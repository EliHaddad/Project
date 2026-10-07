-- NEW RECONSTRUCTION ONLY. Audit existing Supabase first. No legacy table altered.
-- Intentionally fails if any yi_* table already exists: never hides schema mismatches.
begin;
create function public.yi_touch_updated_at() returns trigger language plpgsql set search_path = '' as $$
begin new.updated_at=now(); return new; end; $$;

create table public.yi_prospects (id uuid primary key default gen_random_uuid(),
 owner_id uuid not null references auth.users(id) on delete cascade,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 unique(id,owner_id),
 name text not null check(length(trim(name))>0), email text, phone text, status text, source text, budget numeric check(budget>=0), city text, notes text);
alter table public.yi_prospects enable row level security;
revoke all on public.yi_prospects from anon;
grant select,insert,update,delete on public.yi_prospects to authenticated;
create policy yi_prospects_select on public.yi_prospects for select to authenticated using ((select auth.uid())=owner_id);
create policy yi_prospects_insert on public.yi_prospects for insert to authenticated with check ((select auth.uid())=owner_id);
create policy yi_prospects_update on public.yi_prospects for update to authenticated using ((select auth.uid())=owner_id) with check ((select auth.uid())=owner_id);
create policy yi_prospects_delete on public.yi_prospects for delete to authenticated using ((select auth.uid())=owner_id);
create index yi_prospects_owner_created_idx on public.yi_prospects(owner_id,created_at desc);
create trigger yi_prospects_updated before update on public.yi_prospects for each row execute function public.yi_touch_updated_at();

create table public.yi_projects (id uuid primary key default gen_random_uuid(),
 owner_id uuid not null references auth.users(id) on delete cascade,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 unique(id,owner_id),
 name text not null check(length(trim(name))>0), city text, address text, developer text, status text, delivery_date date, notes text);
alter table public.yi_projects enable row level security;
revoke all on public.yi_projects from anon;
grant select,insert,update,delete on public.yi_projects to authenticated;
create policy yi_projects_select on public.yi_projects for select to authenticated using ((select auth.uid())=owner_id);
create policy yi_projects_insert on public.yi_projects for insert to authenticated with check ((select auth.uid())=owner_id);
create policy yi_projects_update on public.yi_projects for update to authenticated using ((select auth.uid())=owner_id) with check ((select auth.uid())=owner_id);
create policy yi_projects_delete on public.yi_projects for delete to authenticated using ((select auth.uid())=owner_id);
create index yi_projects_owner_created_idx on public.yi_projects(owner_id,created_at desc);
create trigger yi_projects_updated before update on public.yi_projects for each row execute function public.yi_touch_updated_at();

create table public.yi_apartments (id uuid primary key default gen_random_uuid(),
 owner_id uuid not null references auth.users(id) on delete cascade,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 unique(id,owner_id),
 reference text not null check(length(trim(reference))>0), project_id uuid not null, floor integer, rooms numeric check(rooms>=0), area numeric check(area>=0), price numeric check(price>=0), currency text not null check(length(trim(currency))>0), status text, notes text,
 foreign key(project_id,owner_id) references public.yi_projects(id,owner_id) on delete restrict,
 unique(project_id,reference,owner_id));
alter table public.yi_apartments enable row level security;
revoke all on public.yi_apartments from anon;
grant select,insert,update,delete on public.yi_apartments to authenticated;
create policy yi_apartments_select on public.yi_apartments for select to authenticated using ((select auth.uid())=owner_id);
create policy yi_apartments_insert on public.yi_apartments for insert to authenticated with check ((select auth.uid())=owner_id);
create policy yi_apartments_update on public.yi_apartments for update to authenticated using ((select auth.uid())=owner_id) with check ((select auth.uid())=owner_id);
create policy yi_apartments_delete on public.yi_apartments for delete to authenticated using ((select auth.uid())=owner_id);
create index yi_apartments_owner_created_idx on public.yi_apartments(owner_id,created_at desc);
create trigger yi_apartments_updated before update on public.yi_apartments for each row execute function public.yi_touch_updated_at();

create table public.yi_appointments (id uuid primary key default gen_random_uuid(),
 owner_id uuid not null references auth.users(id) on delete cascade,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 unique(id,owner_id),
 title text not null check(length(trim(title))>0), prospect_id uuid not null, apartment_id uuid, starts_at timestamptz not null, ends_at timestamptz, location text, status text, notes text,
 check(ends_at is null or ends_at>starts_at),
 foreign key(prospect_id,owner_id) references public.yi_prospects(id,owner_id) on delete cascade,
 foreign key(apartment_id,owner_id) references public.yi_apartments(id,owner_id) on delete restrict);
alter table public.yi_appointments enable row level security;
revoke all on public.yi_appointments from anon;
grant select,insert,update,delete on public.yi_appointments to authenticated;
create policy yi_appointments_select on public.yi_appointments for select to authenticated using ((select auth.uid())=owner_id);
create policy yi_appointments_insert on public.yi_appointments for insert to authenticated with check ((select auth.uid())=owner_id);
create policy yi_appointments_update on public.yi_appointments for update to authenticated using ((select auth.uid())=owner_id) with check ((select auth.uid())=owner_id);
create policy yi_appointments_delete on public.yi_appointments for delete to authenticated using ((select auth.uid())=owner_id);
create index yi_appointments_owner_created_idx on public.yi_appointments(owner_id,created_at desc);
create trigger yi_appointments_updated before update on public.yi_appointments for each row execute function public.yi_touch_updated_at();

create table public.yi_activities (id uuid primary key default gen_random_uuid(),
 owner_id uuid not null references auth.users(id) on delete cascade,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 unique(id,owner_id),
 title text not null check(length(trim(title))>0), prospect_id uuid not null, kind text, occurred_at timestamptz not null, notes text,
 foreign key(prospect_id,owner_id) references public.yi_prospects(id,owner_id) on delete cascade);
alter table public.yi_activities enable row level security;
revoke all on public.yi_activities from anon;
grant select,insert,update,delete on public.yi_activities to authenticated;
create policy yi_activities_select on public.yi_activities for select to authenticated using ((select auth.uid())=owner_id);
create policy yi_activities_insert on public.yi_activities for insert to authenticated with check ((select auth.uid())=owner_id);
create policy yi_activities_update on public.yi_activities for update to authenticated using ((select auth.uid())=owner_id) with check ((select auth.uid())=owner_id);
create policy yi_activities_delete on public.yi_activities for delete to authenticated using ((select auth.uid())=owner_id);
create index yi_activities_owner_created_idx on public.yi_activities(owner_id,created_at desc);
create trigger yi_activities_updated before update on public.yi_activities for each row execute function public.yi_touch_updated_at();

create table public.yi_tasks (id uuid primary key default gen_random_uuid(),
 owner_id uuid not null references auth.users(id) on delete cascade,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 unique(id,owner_id),
 title text not null check(length(trim(title))>0), prospect_id uuid, due_at timestamptz, status text, priority text, notes text,
 foreign key(prospect_id,owner_id) references public.yi_prospects(id,owner_id) on delete cascade);
alter table public.yi_tasks enable row level security;
revoke all on public.yi_tasks from anon;
grant select,insert,update,delete on public.yi_tasks to authenticated;
create policy yi_tasks_select on public.yi_tasks for select to authenticated using ((select auth.uid())=owner_id);
create policy yi_tasks_insert on public.yi_tasks for insert to authenticated with check ((select auth.uid())=owner_id);
create policy yi_tasks_update on public.yi_tasks for update to authenticated using ((select auth.uid())=owner_id) with check ((select auth.uid())=owner_id);
create policy yi_tasks_delete on public.yi_tasks for delete to authenticated using ((select auth.uid())=owner_id);
create index yi_tasks_owner_created_idx on public.yi_tasks(owner_id,created_at desc);
create trigger yi_tasks_updated before update on public.yi_tasks for each row execute function public.yi_touch_updated_at();

create table public.yi_prospect_apartments (id uuid primary key default gen_random_uuid(),
 owner_id uuid not null references auth.users(id) on delete cascade,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 unique(id,owner_id),
 prospect_id uuid not null, apartment_id uuid not null, status text,
 foreign key(prospect_id,owner_id) references public.yi_prospects(id,owner_id) on delete cascade,
 foreign key(apartment_id,owner_id) references public.yi_apartments(id,owner_id) on delete cascade,
 unique(prospect_id,apartment_id,owner_id));
alter table public.yi_prospect_apartments enable row level security;
revoke all on public.yi_prospect_apartments from anon;
grant select,insert,update,delete on public.yi_prospect_apartments to authenticated;
create policy yi_prospect_apartments_select on public.yi_prospect_apartments for select to authenticated using ((select auth.uid())=owner_id);
create policy yi_prospect_apartments_insert on public.yi_prospect_apartments for insert to authenticated with check ((select auth.uid())=owner_id);
create policy yi_prospect_apartments_update on public.yi_prospect_apartments for update to authenticated using ((select auth.uid())=owner_id) with check ((select auth.uid())=owner_id);
create policy yi_prospect_apartments_delete on public.yi_prospect_apartments for delete to authenticated using ((select auth.uid())=owner_id);
create index yi_prospect_apartments_owner_created_idx on public.yi_prospect_apartments(owner_id,created_at desc);
create trigger yi_prospect_apartments_updated before update on public.yi_prospect_apartments for each row execute function public.yi_touch_updated_at();
create index yi_apartments_project_idx on public.yi_apartments(owner_id,project_id);
create index yi_appointments_prospect_idx on public.yi_appointments(owner_id,prospect_id);
create index yi_appointments_apartment_idx on public.yi_appointments(owner_id,apartment_id);
create index yi_appointments_date_idx on public.yi_appointments(owner_id,starts_at);
create index yi_activities_prospect_idx on public.yi_activities(owner_id,prospect_id,occurred_at desc);
create index yi_tasks_prospect_idx on public.yi_tasks(owner_id,prospect_id);
create index yi_tasks_due_idx on public.yi_tasks(owner_id,due_at);
create index yi_prospect_apartments_apartment_idx on public.yi_prospect_apartments(owner_id,apartment_id);
commit;
