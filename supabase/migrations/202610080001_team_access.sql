-- Audited legacy database only. Bootstrap account verified on 2026-10-08.
-- Apply atomically after deploying the team UI and configuring the server-only key.
begin;
create table public.crm_members (
 id uuid primary key references auth.users(id) on delete cascade,
 full_name text not null,
 email text not null,
 role text not null check (role in ('admin','employee')),
 active boolean not null default true,
 created_at timestamptz not null default now()
);
insert into public.crm_members(id,full_name,email,role)
 select u.id,coalesce(nullif(p.full_name,''),u.email),u.email,
 case when lower(u.email)=lower(current_setting('crm.bootstrap_email')) then 'admin' else 'employee' end
 from auth.users u left join public.profiles p on p.id=u.id;
do $$ begin
 if (select count(*) from public.crm_members where role='admin')<>1 then
 raise exception 'Verified administrator not found'; end if;
end $$;
alter table public.crm_members enable row level security;
revoke all on public.crm_members from anon,authenticated;
grant select on public.crm_members to authenticated;
grant all on public.crm_members to service_role;
create function public.crm_active() returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.crm_members where id=auth.uid() and active);
$$;
create function public.crm_admin() returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.crm_members where id=auth.uid() and active and role='admin');
$$;
create function public.crm_prospect_access(prospect bigint) returns boolean language sql stable security definer set search_path='' as $$
 select public.crm_active() and (public.crm_admin() or exists(select 1 from public.prospects where id=prospect and assigned_to=auth.uid()));
$$;
revoke all on function public.crm_active(),public.crm_admin(),public.crm_prospect_access(bigint) from public;
grant execute on function public.crm_active(),public.crm_admin(),public.crm_prospect_access(bigint) to authenticated;
create policy crm_members_read on public.crm_members for select to authenticated using(id=auth.uid() or public.crm_admin());

-- Replace permissive policies, otherwise PostgreSQL ORs them and leaks shared data.
do $$ declare p record; begin
 for p in select tablename,policyname from pg_policies where schemaname='public' and tablename in
 ('prospects','appointments','tasks','prospect_activities','prospect_apartments','projects','apartments','documents','commissions','payment_terms') loop
 execute format('drop policy %I on public.%I',p.policyname,p.tablename);
 end loop;
end $$;
do $$ declare t text; begin
 foreach t in array array['prospects','appointments','tasks','prospect_activities','prospect_apartments','projects','apartments','documents','commissions','payment_terms'] loop
 execute format('alter table public.%I enable row level security',t);
 execute format('revoke all on public.%I from anon',t);
 end loop;
end $$;
create policy crm_prospects on public.prospects for all to authenticated
 using(public.crm_prospect_access(id)) with check(public.crm_active() and (public.crm_admin() or assigned_to=auth.uid()));
create policy crm_appointments on public.appointments for all to authenticated
 using(public.crm_active() and (public.crm_admin() or public.crm_prospect_access(prospect_id)))
 with check(public.crm_active() and (public.crm_admin() or public.crm_prospect_access(prospect_id)));
create policy crm_tasks on public.tasks for all to authenticated
 using(public.crm_active() and (public.crm_admin() or case when prospect_id is null then assigned_to=auth.uid() else public.crm_prospect_access(prospect_id) end))
 with check(public.crm_active() and (public.crm_admin() or case when prospect_id is null then assigned_to=auth.uid() else public.crm_prospect_access(prospect_id) end));
create policy crm_activities on public.prospect_activities for all to authenticated
 using(public.crm_prospect_access(prospect_id)) with check(public.crm_prospect_access(prospect_id));
create policy crm_links on public.prospect_apartments for all to authenticated
 using(public.crm_prospect_access(prospect_id)) with check(public.crm_prospect_access(prospect_id));
create policy crm_projects_read on public.projects for select to authenticated using(public.crm_active());
create policy crm_projects_write on public.projects for all to authenticated using(public.crm_admin()) with check(public.crm_admin());
create policy crm_apartments_read on public.apartments for select to authenticated using(public.crm_active());
create policy crm_apartments_write on public.apartments for all to authenticated using(public.crm_admin()) with check(public.crm_admin());
create policy crm_documents on public.documents for all to authenticated
 using(public.crm_active() and (public.crm_admin() or public.crm_prospect_access(prospect_id)))
 with check(public.crm_active() and (public.crm_admin() or public.crm_prospect_access(prospect_id)));
create policy crm_commissions on public.commissions for all to authenticated
 using(public.crm_active() and (public.crm_admin() or (assigned_to=auth.uid() and (prospect_id is null or public.crm_prospect_access(prospect_id)))))
 with check(public.crm_active() and (public.crm_admin() or (assigned_to=auth.uid() and (prospect_id is null or public.crm_prospect_access(prospect_id)))));
create policy crm_payments on public.payment_terms for all to authenticated
 using(public.crm_active() and (public.crm_admin() or owner_id=auth.uid()))
 with check(public.crm_active() and (public.crm_admin() or owner_id=auth.uid()));

-- Employees cannot hand themselves another employee's prospect through a direct API request.
create function public.crm_assignment_guard() returns trigger language plpgsql security definer set search_path='' as $$
begin
 if auth.role()='service_role' then return new; end if;
 if tg_op='UPDATE' and new.assigned_to is distinct from old.assigned_to and not public.crm_admin() then
 raise exception 'Only an administrator may reassign prospects' using errcode='42501'; end if;
 if new.assigned_to is not null and not exists(select 1 from public.crm_members where id=new.assigned_to and active) then
 raise exception 'Assignee must be an active employee' using errcode='23514'; end if;
 return new;
end $$;
revoke all on function public.crm_assignment_guard() from public;
create trigger crm_prospect_assignment before insert or update on public.prospects for each row execute function public.crm_assignment_guard();
create function public.crm_assign_prospects(prospect_ids bigint[],employee_id uuid) returns void language plpgsql security definer set search_path='' as $$
declare found_count integer;
begin
 if not public.crm_admin() then raise exception 'Administrator required' using errcode='42501'; end if;
 if coalesce(cardinality(prospect_ids),0)<1 or cardinality(prospect_ids)>5000 then raise exception 'Invalid selection'; end if;
 if not exists(select 1 from public.crm_members m join public.profiles p on p.id=m.id where m.id=employee_id and m.active) then raise exception 'Invalid employee'; end if;
 perform 1 from public.prospects where id=any(prospect_ids) for update;
 select count(*) into found_count from public.prospects where id=any(prospect_ids);
 if found_count <> cardinality(prospect_ids) then raise exception 'Selection contains missing or duplicate prospects'; end if;
 update public.prospects set assigned_to=employee_id where id=any(prospect_ids);
 update public.appointments set assigned_to=employee_id where prospect_id=any(prospect_ids);
 update public.tasks set assigned_to=employee_id where prospect_id=any(prospect_ids);
end $$;
revoke all on function public.crm_assign_prospects(bigint[],uuid) from public;
grant execute on function public.crm_assign_prospects(bigint[],uuid) to authenticated;
commit;
