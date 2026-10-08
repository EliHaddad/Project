-- Admin import, deduplication, dates and rollback; no fixture retained.
begin;
select set_config('request.jwt.claims',(select json_build_object('sub',id,'role','authenticated')::text from public.crm_members where role='admin' and active limit 1),true);
set local role authenticated;
do $$ declare result jsonb; payload jsonb; before_count integer; begin
payload='[{"name":"CRM Import Test","email":"crm-import-20261008@example.invalid","phone":"+99900020261008","country":"fr","received_on":"2026-09-01","received_time":"15:45","objective":"résidence_principale","deadline":"dès_que_possible","commercial":"Chmouel","assigned_to":null},{"name":"Duplicate","email":"CRM-IMPORT-20261008@example.invalid","received_on":"2026-09-02"}]'::jsonb;
result=public.crm_import_prospects(payload,'test-only.csv');
if (result->>'imported')::int<>1 or (result->>'skipped')::int<>1 then raise exception 'Duplicate detection failed';end if;
if not exists(select 1 from public.prospects where email='crm-import-20261008@example.invalid' and received_on='2026-09-01' and received_time='15:45' and assigned_to is null and country='fr' and status='Nouveau' and notes like '%résidence_principale%' and notes like '%dès_que_possible%') then raise exception 'Imported values changed';end if;
result=public.crm_import_prospects(payload,'repeat.csv');
if (result->>'imported')::int<>0 or (result->>'skipped')::int<>2 then raise exception 'Repeat import changed records';end if;
select count(*) into before_count from public.crm_import_batches;
begin
perform public.crm_import_prospects('[{"name":"Invalid Test","received_on":"2026-09-01","assigned_to":"00000000-0000-0000-0000-000000000000"}]','invalid.csv');
raise exception 'Invalid assignment accepted';
exception when raise_exception then if sqlerrm<>'Invalid assignee' then raise;end if;end;
if (select count(*) from public.crm_import_batches)<>before_count then raise exception 'Failed import was not atomic';end if;
end $$;
reset role;
select set_config('request.jwt.claims','{"sub":"00000000-0000-0000-0000-000000000000","role":"authenticated"}',true);
set local role authenticated;
do $$ begin
begin perform public.crm_import_prospects('[{"name":"Denied","received_on":"2026-09-01"}]','denied.csv');raise exception 'Nonmember may import';exception when insufficient_privilege then null;end;
if exists(select 1 from public.crm_import_batches) then raise exception 'Import history leaked';end if;
end $$;
reset role;
rollback;
select 'Import checks passed' as result,(select count(*) from public.prospects where email='crm-import-20261008@example.invalid') as retained_fixtures;
