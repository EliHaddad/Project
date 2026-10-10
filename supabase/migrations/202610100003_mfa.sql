-- Enrolled accounts require a verified second factor for CRM data access.
-- Accounts without a verified TOTP factor keep working until they enroll.
begin;
create or replace function public.crm_active() returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.crm_members where id=auth.uid() and active)
 and (coalesce(auth.jwt()->>'aal','')='aal2' or not exists(
  select 1 from auth.mfa_factors where user_id=auth.uid() and factor_type='totp' and status='verified'
 ));
$$;
create or replace function public.crm_admin() returns boolean language sql stable security definer set search_path='' as $$
 select public.crm_active() and exists(select 1 from public.crm_members where id=auth.uid() and active and role='admin');
$$;
commit;
