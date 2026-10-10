-- Execute as database administrator. Everything below rolls back.
begin;
do $$ begin
 if has_table_privilege('anon','public.profiles','select') then raise exception 'Anonymous profile privilege'; end if;
 if has_table_privilege('authenticated','public.profiles','update') then raise exception 'Direct profile update privilege'; end if;
 if exists(select 1 from pg_policies where schemaname='storage' and policyname like 'Authenticated users can % documents') then raise exception 'Old broad Storage policy'; end if;
 if has_table_privilege('authenticated','public.crm_api_limits','select') then raise exception 'Quota table exposed'; end if;
 if has_function_privilege('anon','public.crm_take_api_quota(text)','execute') then raise exception 'Anonymous quota function'; end if;
 if exists(select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.prosecdef and has_function_privilege('anon',p.oid,'execute')) then raise exception 'Anonymous privileged function'; end if;
end $$;
select set_config('request.jwt.claims',json_build_object('sub',(select id from public.crm_members where active and role='admin' limit 1),'role','authenticated','aal','aal2')::text,true);
set local role authenticated;
do $$ declare i integer; allowed boolean; begin
 if not public.crm_admin() then raise exception 'Admin access regressed'; end if;
 for i in 1..8 loop
  allowed:=public.crm_take_api_quota('assistant');
  if allowed is distinct from (i<=5) then raise exception 'Quota mismatch at request %',i; end if;
 end loop;
 if public.crm_take_api_quota('unrecognized') then raise exception 'Unknown action allowed'; end if;
end $$;
reset role;
rollback;
select 'Protection et quota : tests réussis, aucune donnée conservée' as result;
