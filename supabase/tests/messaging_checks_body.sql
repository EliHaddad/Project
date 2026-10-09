-- Run inside a transaction after the messaging schema. All fixtures roll back.
insert into auth.users(id,email) values
('c19b8190-1000-4000-8000-000000000001','chat-test-a@example.invalid'),
('c19b8190-1000-4000-8000-000000000002','chat-test-b@example.invalid'),
('c19b8190-1000-4000-8000-000000000003','chat-test-c@example.invalid');
insert into public.crm_members(id,email,full_name,role) values
('c19b8190-1000-4000-8000-000000000001','chat-test-a@example.invalid','Chat A','employee'),
('c19b8190-1000-4000-8000-000000000002','chat-test-b@example.invalid','Chat B','employee'),
('c19b8190-1000-4000-8000-000000000003','chat-test-c@example.invalid','Chat C','admin');
select set_config('request.jwt.claims','{"sub":"c19b8190-1000-4000-8000-000000000001","role":"authenticated"}',true);
set local role authenticated;
do $$ declare direct uuid; again uuid; team uuid;msg uuid;begin
 direct=public.crm_chat_open('c19b8190-1000-4000-8000-000000000002');again=public.crm_chat_open('c19b8190-1000-4000-8000-000000000002');
 if direct<>again then raise exception 'Duplicate direct chat';end if;
 select id into team from public.crm_chat_threads where kind='team';
 insert into public.crm_chat_messages(thread_id,sender_id,body) values(direct,auth.uid(),'Private fixture'),(team,auth.uid(),'Team fixture');
 if (select unread from public.crm_chat_inbox() where id=direct) is distinct from 0 then raise exception 'Own message counted as unread';end if;
 begin
 insert into public.crm_chat_messages(thread_id,sender_id,body) values(direct,'c19b8190-1000-4000-8000-000000000002','Spoofed');raise exception 'Sender impersonation accepted';exception when insufficient_privilege then null;end;
 begin
 insert into public.crm_chat_messages(thread_id,sender_id,body) values(direct,auth.uid(),'   ');raise exception 'Empty message accepted';exception when check_violation then null;end;
end $$;
reset role;
select set_config('request.jwt.claims','{"sub":"c19b8190-1000-4000-8000-000000000002","role":"authenticated"}',true);
set local role authenticated;
do $$ declare direct uuid;team uuid;msg uuid;begin
 direct=public.crm_chat_open('c19b8190-1000-4000-8000-000000000001');
 if (select unread from public.crm_chat_inbox() where id=direct) is distinct from 1 then raise exception 'Unread message missing';end if;
 select id into msg from public.crm_chat_messages where thread_id=direct;
 perform set_config('chat.test_private',direct::text,true);perform set_config('chat.test_message',msg::text,true);
 perform public.crm_chat_mark_read(direct,msg);
 if (select unread from public.crm_chat_inbox() where id=direct) is distinct from 0 then raise exception 'Read receipt failed';end if;
end $$;
reset role;
select set_config('request.jwt.claims','{"sub":"c19b8190-1000-4000-8000-000000000003","role":"authenticated"}',true);
set local role authenticated;
do $$ declare private uuid:=current_setting('chat.test_private')::uuid;begin
 begin insert into public.crm_chat_messages(thread_id,sender_id,body) values(private,auth.uid(),'Unauthorized');raise exception 'Third party writes private chat';exception when insufficient_privilege then null;end;
 begin perform public.crm_chat_mark_read(private,current_setting('chat.test_message')::uuid);raise exception 'Third party marks private messages read';exception when insufficient_privilege then null;end;
 begin update public.crm_chat_messages set body='Changed';raise exception 'Message editing permitted';exception when insufficient_privilege then null;end;
 if (select count(*) from public.crm_chat_messages)<>1 then raise exception 'Administrator accessed private chat';end if;
 if exists(select 1 from public.crm_chat_inbox() where kind='direct') then raise exception 'Private conversation metadata leaked';end if;
end $$;
reset role;
update public.crm_members set active=false where id='c19b8190-1000-4000-8000-000000000003';
set local role authenticated;
do $$ begin
 if exists(select 1 from public.crm_chat_messages) or exists(select 1 from public.crm_chat_directory()) or exists(select 1 from public.crm_chat_inbox()) then raise exception 'Inactive member access';end if;
 begin perform public.crm_chat_open('c19b8190-1000-4000-8000-000000000001');raise exception 'Inactive member opens chat';exception when insufficient_privilege then null;end;
end $$;
reset role;
