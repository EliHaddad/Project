-- Integration test ONLY on disposable Supabase, after reconstruction migration.
-- Execute as postgres using psql with ON_ERROR_STOP=1. All fixtures roll back.
begin;
insert into auth.users(id,email) values
 ('10000000-0000-0000-0000-000000000001','yi-test-a@example.invalid'),
 ('10000000-0000-0000-0000-000000000002','yi-test-b@example.invalid');
insert into public.yi_prospects(id,owner_id,name) values
 ('20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001','A'),
 ('20000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000002','B');
insert into public.yi_projects(id,owner_id,name) values
 ('30000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001','Project A');
set local role authenticated;
select set_config('request.jwt.claims','{"sub":"10000000-0000-0000-0000-000000000001","role":"authenticated"}',true);
do $$
declare amount integer;
begin
 select count(*) into amount from public.yi_prospects;
 if amount<>1 then raise exception 'RLS SELECT isolation failed';end if;
 update public.yi_prospects set name='Attack' where id='20000000-0000-0000-0000-000000000002';
 get diagnostics amount=row_count;
 if amount<>0 then raise exception 'RLS UPDATE isolation failed';end if;
 delete from public.yi_prospects where id='20000000-0000-0000-0000-000000000002';
 get diagnostics amount=row_count;
 if amount<>0 then raise exception 'RLS DELETE isolation failed';end if;
 begin
  insert into public.yi_prospects(owner_id,name) values ('10000000-0000-0000-0000-000000000002','Attack');
  raise exception 'RLS INSERT isolation failed';
 exception when insufficient_privilege then null;end;
 begin
  update public.yi_prospects set owner_id='10000000-0000-0000-0000-000000000002' where id='20000000-0000-0000-0000-000000000001';
  raise exception 'Owner reassignment permitted';
 exception when insufficient_privilege then null;end;
 begin
  insert into public.yi_activities(owner_id,prospect_id,title,occurred_at)
  values ('10000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000002','Attack',now());
  raise exception 'Cross owner relation permitted';
 exception when foreign_key_violation then null;end;
 insert into public.yi_activities(owner_id,prospect_id,title,occurred_at)
 values ('10000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001','Call',now());
 delete from public.yi_prospects where id='20000000-0000-0000-0000-000000000001';
 select count(*) into amount from public.yi_activities;
 if amount<>0 then raise exception 'Cascade failed';end if;
end $$;
reset role;
set local role anon;
do $$ begin
 begin perform 1 from public.yi_prospects;raise exception 'Anonymous access permitted';
 exception when insufficient_privilege then null;end;
end $$;
rollback;
