-- READ ONLY: run on existing Supabase before deciding any migration/import.
-- No customer rows, passwords or auth tokens are retrieved.
select table_schema,table_name,column_name,data_type,udt_name,is_nullable,column_default
from information_schema.columns where table_schema='public'
order by table_name,ordinal_position;
select n.nspname as schema,t.typname as enum_name,e.enumlabel,e.enumsortorder
from pg_type t join pg_enum e on e.enumtypid=t.oid join pg_namespace n on n.oid=t.typnamespace
where n.nspname='public' order by t.typname,e.enumsortorder;
select c.relname as table_name,con.conname,pg_get_constraintdef(con.oid) as definition
from pg_constraint con join pg_class c on c.oid=con.conrelid join pg_namespace n on n.oid=c.relnamespace
where n.nspname='public' order by c.relname,con.conname;
select schemaname,tablename,policyname,roles,cmd,qual,with_check from pg_policies
where schemaname='public' order by tablename,policyname;
select c.relname,c.relrowsecurity,c.relforcerowsecurity from pg_class c
join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relkind='r';
-- For text statuses, run SELECT DISTINCT status FROM <verified_table> separately.
-- Do the same for priority, source, kind and currency after verifying actual columns.
