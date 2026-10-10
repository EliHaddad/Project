-- Narrow the audited legacy Storage policies. No files or client rows are deleted.
begin;
revoke all on public.profiles from anon;
-- Profiles are provisioned through the server-only administrator endpoint.
-- CRM membership, rather than this legacy role column, grants authorization.
revoke insert,update,delete on public.profiles from authenticated;
drop policy if exists "Authenticated users can read documents" on storage.objects;
drop policy if exists "Authenticated users can upload documents" on storage.objects;
drop policy if exists "Authenticated users can update documents" on storage.objects;
drop policy if exists "Authenticated users can delete documents" on storage.objects;
drop policy if exists crm_document_storage on storage.objects;
create policy crm_document_storage on storage.objects for all to authenticated
 using(bucket_id='documents' and public.crm_active() and
  (public.crm_admin() or owner_id=(select auth.uid()::text)))
 with check(bucket_id='documents' and public.crm_active() and
  (public.crm_admin() or owner_id=(select auth.uid()::text)));
commit;
