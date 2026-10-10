begin;
create table if not exists public.crm_api_limits (
 user_id uuid not null references auth.users(id) on delete cascade,
 action text not null,
 period text not null check(period in ('minute','day')),
 started_at timestamptz not null,
 used integer not null,
 primary key(user_id,action,period)
);
alter table public.crm_api_limits enable row level security;
revoke all on public.crm_api_limits from public,anon,authenticated;
create or replace function public.crm_take_api_quota(action_name text) returns boolean
language plpgsql security definer set search_path='' as $$
declare p text; cap integer; current_time_value timestamptz:=clock_timestamp(); accepted integer;
begin
 if not public.crm_active() then return false; end if;
 if action_name not in ('assistant','invite') then return false; end if;
 if action_name='invite' and not public.crm_admin() then return false; end if;
 -- One lock per account prevents concurrent requests racing across the two windows.
 perform pg_advisory_xact_lock(hashtextextended(auth.uid()::text,0));
 foreach p in array array['day','minute'] loop
  cap:=case when action_name='assistant' then case when p='day' then 100 else 5 end
       else case when p='day' then 20 else 3 end end;
  insert into public.crm_api_limits(user_id,action,period,started_at,used)
   values(auth.uid(),action_name,p,current_time_value,1)
  on conflict(user_id,action,period) do update set
   started_at=case when crm_api_limits.started_at<=current_time_value-(case when p='day' then interval '1 day' else interval '1 minute' end) then current_time_value else crm_api_limits.started_at end,
   used=case when crm_api_limits.started_at<=current_time_value-(case when p='day' then interval '1 day' else interval '1 minute' end) then 1 else crm_api_limits.used+1 end
  where crm_api_limits.used<cap or crm_api_limits.started_at<=current_time_value-(case when p='day' then interval '1 day' else interval '1 minute' end)
  returning used into accepted;
  if accepted is null then return false; end if;
  accepted:=null;
 end loop;
 return true;
end $$;
revoke all on function public.crm_take_api_quota(text) from public,anon;
grant execute on function public.crm_take_api_quota(text) to authenticated;
commit;
