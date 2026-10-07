-- Existing historical database only. Do NOT run the initial yi_* reconstruction migration.
-- New personal payment-terms records; no existing customer/project rows are changed.
begin;
create table public.payment_terms (
 id uuid primary key default gen_random_uuid(),
 owner_id uuid not null references auth.users(id) on delete cascade,
 project_id bigint references public.projects(id) on delete restrict,
 title text not null check(length(trim(title)) between 1 and 200),
 conditions text not null check(length(trim(conditions)) between 1 and 20000),
 created_at timestamptz not null default now()
);
alter table public.payment_terms enable row level security;
revoke all on public.payment_terms from anon;
grant select,insert,update,delete on public.payment_terms to authenticated;
create policy payment_terms_read on public.payment_terms for select to authenticated using(owner_id=(select auth.uid()));
create policy payment_terms_create on public.payment_terms for insert to authenticated with check(
 owner_id=(select auth.uid()) and (project_id is null or exists(select 1 from public.projects p where p.id=payment_terms.project_id))
);
create policy payment_terms_edit on public.payment_terms for update to authenticated using(owner_id=(select auth.uid())) with check(
 owner_id=(select auth.uid()) and (project_id is null or exists(select 1 from public.projects p where p.id=payment_terms.project_id))
);
create policy payment_terms_delete on public.payment_terms for delete to authenticated using(owner_id=(select auth.uid()));
create index payment_terms_owner_created_idx on public.payment_terms(owner_id,created_at desc);
create index payment_terms_project_idx on public.payment_terms(project_id);
commit;
