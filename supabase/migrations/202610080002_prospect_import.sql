begin;
create table public.crm_import_batches(id uuid primary key default gen_random_uuid(),created_at timestamptz not null default now(),created_by uuid not null references auth.users(id),filename text not null,total integer not null,imported integer not null default 0,skipped integer not null default 0);
alter table public.crm_import_batches enable row level security;
revoke all on public.crm_import_batches from anon,authenticated;
grant select on public.crm_import_batches to authenticated;
create policy crm_import_batches_read on public.crm_import_batches for select to authenticated using(public.crm_admin());
alter table public.prospects add column received_on date,add column received_time time,add column imported_at timestamptz,add column import_batch_id uuid references public.crm_import_batches(id);
alter table public.prospects alter column received_on set default current_date;
create index prospects_received_on_idx on public.prospects(received_on desc);
create function public.crm_phone_key(value text) returns text language sql immutable set search_path='' as $$ select regexp_replace(regexp_replace(coalesce(value,''),'[^0-9]','','g'),'^00',''); $$;
revoke all on function public.crm_phone_key(text) from public;
create function public.crm_import_prospects(leads jsonb,filename text) returns jsonb language plpgsql security definer set search_path='' as $$
declare item jsonb; batch uuid; v_imported integer:=0; v_skipped integer:=0; target uuid; mail text; tel text; fullname text; day date; clock time;
begin
 if not public.crm_admin() then raise exception 'Administrator required' using errcode='42501';end if;
 if jsonb_typeof(leads)<>'array' or jsonb_array_length(leads)<1 or jsonb_array_length(leads)>5000 or length(filename)>255 then raise exception 'Invalid import';end if;
 perform pg_advisory_xact_lock(20261008,2);
 insert into public.crm_import_batches(created_by,filename,total) values(auth.uid(),filename,jsonb_array_length(leads)) returning id into batch;
 for item in select value from jsonb_array_elements(leads) loop
  fullname=btrim(item->>'name');mail=nullif(btrim(item->>'email'),'');tel=nullif(btrim(item->>'phone'),'');target=nullif(item->>'assigned_to','')::uuid;
  day=(item->>'received_on')::date;clock=nullif(item->>'received_time','')::time;
  if fullname is null or fullname='' or length(fullname)>500 or day is null or day<'1900-01-01' or day>'2200-12-31' or (mail is not null and mail !~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$') then raise exception 'Invalid row';end if;
  if target is not null and not exists(select 1 from public.crm_members m join public.profiles p on p.id=m.id where m.id=target and m.active) then raise exception 'Invalid assignee';end if;
  if exists(select 1 from public.prospects p where (mail is not null and lower(btrim(p.email))=lower(mail)) or (public.crm_phone_key(tel)<>'' and public.crm_phone_key(p.phone)=public.crm_phone_key(tel))) then v_skipped=v_skipped+1;continue;end if;
  insert into public.prospects(first_name,last_name,email,phone,country,status,assigned_to,received_on,received_time,imported_at,import_batch_id,notes)
  values(split_part(fullname,' ',1),ltrim(substr(fullname,length(split_part(fullname,' ',1))+1)),mail,tel,nullif(item->>'country',''),'Nouveau',target,day,clock,now(),batch,
   concat_ws(E'\n',case when coalesce(item->>'objective','')<>'' then 'Objectif: '||(item->>'objective') end,case when coalesce(item->>'deadline','')<>'' then 'Délai: '||(item->>'deadline') end,case when coalesce(item->>'commercial','')<>'' then 'Commercial dans le fichier: '||(item->>'commercial') end));
  v_imported=v_imported+1;
 end loop;
 update public.crm_import_batches set imported=v_imported,skipped=v_skipped where id=batch;
 return jsonb_build_object('batch_id',batch,'imported',v_imported,'skipped',v_skipped);
end $$;
revoke all on function public.crm_import_prospects(jsonb,text) from public;
grant execute on function public.crm_import_prospects(jsonb,text) to authenticated;
commit;

