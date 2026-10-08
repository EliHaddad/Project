-- Run after team migration. Test fixtures, role changes and writes are rolled back.
begin;
insert into auth.users(id,email) values
 ('b31ec819-4634-4c5c-8319-712c3c8dba01','crm-test-a@example.invalid'),
 ('b31ec819-4634-4c5c-8319-712c3c8dba02','crm-test-b@example.invalid');
insert into public.profiles(id,full_name,role) values
 ('b31ec819-4634-4c5c-8319-712c3c8dba01','Test A','agent'),
 ('b31ec819-4634-4c5c-8319-712c3c8dba02','Test B','agent') on conflict(id) do nothing;
insert into public.crm_members(id,email,full_name,role) values
 ('b31ec819-4634-4c5c-8319-712c3c8dba01','crm-test-a@example.invalid','Test A','employee'),
 ('b31ec819-4634-4c5c-8319-712c3c8dba02','crm-test-b@example.invalid','Test B','employee');
insert into public.prospects(id,first_name,last_name,assigned_to) values
 (-910001,'CRM Test','A','b31ec819-4634-4c5c-8319-712c3c8dba01'),
 (-910002,'CRM Test','B','b31ec819-4634-4c5c-8319-712c3c8dba02');
set local role authenticated;
select set_config('request.jwt.claims','{"sub":"b31ec819-4634-4c5c-8319-712c3c8dba01","role":"authenticated"}',true);
do $$ begin
 if (select count(*) from public.prospects)<>1 then raise exception 'Employee sees other prospects'; end if;
 if (select count(*) from public.crm_members)<>1 then raise exception 'Employee sees other memberships'; end if;
 if exists(select 1 from public.appointments) or exists(select 1 from public.prospect_activities) or exists(select 1 from public.prospect_apartments) then raise exception 'Related data leaked'; end if;
 begin
 perform public.crm_assign_prospects(array[-910002]::bigint[],'b31ec819-4634-4c5c-8319-712c3c8dba01');
 raise exception 'Employee may assign prospects';
 exception when insufficient_privilege then null; end;
 begin
 update public.crm_members set role='admin' where id=auth.uid();
 raise exception 'Employee may change membership';
 exception when insufficient_privilege then null; end;
 update public.profiles set role='admin' where id=auth.uid();
 if public.crm_admin() then raise exception 'Profile edit escalates role'; end if;
end $$;
reset role;
select set_config('request.jwt.claims',(select json_build_object('sub',id,'role','authenticated')::text from public.crm_members where role='admin'),true);
set local role authenticated;
do $$ begin
 if not public.crm_admin() then raise exception 'Administrator denied'; end if;
 if (select count(*) from public.prospects where id in (-910001,-910002))<>2 then raise exception 'Admin cannot see both employees'; end if;
end $$;
select public.crm_assign_prospects(array[-910002]::bigint[],'b31ec819-4634-4c5c-8319-712c3c8dba01');
select set_config('request.jwt.claims','{"sub":"b31ec819-4634-4c5c-8319-712c3c8dba02","role":"authenticated"}',true);
do $$ begin if exists(select 1 from public.prospects) then raise exception 'Previous assignee still has access'; end if; end $$;
select set_config('request.jwt.claims','{"sub":"b31ec819-4634-4c5c-8319-712c3c8dba01","role":"authenticated"}',true);
do $$ begin if (select count(*) from public.prospects)<>2 then raise exception 'New assignee denied'; end if; end $$;
reset role;
update public.crm_members set active=false where id='b31ec819-4634-4c5c-8319-712c3c8dba01';
set local role authenticated;
do $$ begin if exists(select 1 from public.prospects) or exists(select 1 from public.projects) then raise exception 'Inactive member still has access'; end if; end $$;
reset role;
rollback;
select 'Team access tests passed; all fixtures rolled back' as result;
