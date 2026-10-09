-- Messaging is separate from prospect permissions. Private chats are visible only to their two participants.
begin;
create table public.crm_chat_threads(
 id uuid primary key default gen_random_uuid(),kind text not null check(kind in ('team','direct')),
 member_a uuid references public.crm_members(id),member_b uuid references public.crm_members(id),created_at timestamptz not null default now(),
 check((kind='team' and member_a is null and member_b is null) or (kind='direct' and member_a is not null and member_b is not null and member_a<member_b)),unique(member_a,member_b));
create unique index crm_chat_one_team on public.crm_chat_threads(kind) where kind='team';
insert into public.crm_chat_threads(kind) values('team');
create table public.crm_chat_messages(id uuid primary key default gen_random_uuid(),thread_id uuid not null references public.crm_chat_threads(id),sender_id uuid not null references public.crm_members(id),body text not null check(length(btrim(body)) between 1 and 4000),created_at timestamptz not null default now());
create index crm_chat_messages_thread_date on public.crm_chat_messages(thread_id,created_at desc,id desc);
create table public.crm_chat_reads(thread_id uuid not null references public.crm_chat_threads(id),member_id uuid not null references public.crm_members(id),last_read_at timestamptz not null,primary key(thread_id,member_id));
alter table public.crm_chat_threads enable row level security;
alter table public.crm_chat_messages enable row level security;
alter table public.crm_chat_reads enable row level security;
revoke all on public.crm_chat_threads,public.crm_chat_messages,public.crm_chat_reads from anon,authenticated;
grant select on public.crm_chat_threads,public.crm_chat_messages to authenticated;
grant insert(thread_id,sender_id,body) on public.crm_chat_messages to authenticated;
create function public.crm_chat_access(thread uuid) returns boolean language sql stable security definer set search_path='' as $$
 select public.crm_active() and exists(select 1 from public.crm_chat_threads t where t.id=thread and (t.kind='team' or auth.uid() in(t.member_a,t.member_b)));
$$;
revoke all on function public.crm_chat_access(uuid) from public;
grant execute on function public.crm_chat_access(uuid) to authenticated;
create policy crm_chat_threads_select on public.crm_chat_threads for select to authenticated using(public.crm_chat_access(id));
create policy crm_chat_messages_select on public.crm_chat_messages for select to authenticated using(public.crm_chat_access(thread_id));
create policy crm_chat_messages_insert on public.crm_chat_messages for insert to authenticated with check(sender_id=auth.uid() and public.crm_chat_access(thread_id));
create function public.crm_chat_directory() returns table(id uuid,full_name text) language sql stable security definer set search_path='' as $$
 select m.id,m.full_name from public.crm_members m where public.crm_active() and m.active order by m.full_name,m.id;
$$;
create function public.crm_chat_open(peer uuid) returns uuid language plpgsql security definer set search_path='' as $$
declare a uuid; b uuid; result uuid; begin
 if not public.crm_active() or peer=auth.uid() or peer is null or not exists(select 1 from public.crm_members where id=peer and active) then raise exception 'Invalid chat participant' using errcode='42501';end if;
 a=least(peer,auth.uid());b=greatest(peer,auth.uid());
 insert into public.crm_chat_threads(kind,member_a,member_b) values('direct',a,b) on conflict(member_a,member_b) do nothing;
 select id into result from public.crm_chat_threads where member_a=a and member_b=b;
 return result;
end $$;
create function public.crm_chat_inbox() returns table(id uuid,kind text,peer_id uuid,peer_name text,last_body text,last_at timestamptz,unread bigint) language sql stable security definer set search_path='' as $$
 select t.id,t.kind,case when auth.uid()=t.member_a then t.member_b else t.member_a end,m.full_name,msg.body,msg.created_at,
 (select count(*) from public.crm_chat_messages n where n.thread_id=t.id and n.sender_id<>auth.uid() and n.created_at>coalesce(r.last_read_at,'-infinity'::timestamptz))
 from public.crm_chat_threads t
 left join public.crm_members m on m.id=case when auth.uid()=t.member_a then t.member_b else t.member_a end
 left join lateral(select body,created_at from public.crm_chat_messages where thread_id=t.id order by created_at desc,id desc limit 1) msg on true
 left join public.crm_chat_reads r on r.thread_id=t.id and r.member_id=auth.uid()
 where public.crm_active() and (t.kind='team' or auth.uid() in(t.member_a,t.member_b))
 order by msg.created_at desc nulls last,t.created_at,t.id;
$$;
create function public.crm_chat_mark_read(thread uuid,message uuid) returns void language plpgsql security definer set search_path='' as $$
declare seen timestamptz;begin
 if not public.crm_chat_access(thread) then raise exception 'Chat access denied' using errcode='42501';end if;
 select created_at into seen from public.crm_chat_messages where id=message and thread_id=thread;
 if seen is null then return;end if;
 insert into public.crm_chat_reads(thread_id,member_id,last_read_at) values(thread,auth.uid(),seen)
 on conflict(thread_id,member_id) do update set last_read_at=greatest(public.crm_chat_reads.last_read_at,excluded.last_read_at);
end $$;
revoke all on function public.crm_chat_directory(),public.crm_chat_open(uuid),public.crm_chat_inbox(),public.crm_chat_mark_read(uuid,uuid) from public;
grant execute on function public.crm_chat_directory(),public.crm_chat_open(uuid),public.crm_chat_inbox(),public.crm_chat_mark_read(uuid,uuid) to authenticated;
commit;
