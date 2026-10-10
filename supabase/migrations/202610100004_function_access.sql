-- Supabase default privileges had also granted anon EXECUTE explicitly.
-- Revoking only PUBLIC did not remove that separate grant.
begin;
revoke execute on all functions in schema public from public,anon;
alter default privileges for role postgres in schema public revoke execute on functions from public,anon;
-- The audited trigger uses public.profiles explicitly and built-in operators.
alter function public.handle_new_user() set search_path='';
commit;
