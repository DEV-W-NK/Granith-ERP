-- AI chat must be personal: each authenticated user can access only their own
-- conversations and messages. Monitoring/usage permissions stay limited to
-- usage metadata, not chat content.

grant select, insert, update on public.ai_conversations to authenticated;
grant select, insert on public.ai_messages to authenticated;
grant select, insert on public.ai_usage_events to authenticated;
grant select, insert, update, delete on public.ai_model_pricing to authenticated;

grant select, insert, update, delete on public.ai_conversations to service_role;
grant select, insert, update, delete on public.ai_messages to service_role;
grant select, insert, update, delete on public.ai_usage_events to service_role;
grant select, insert, update, delete on public.ai_model_pricing to service_role;

create or replace function private.can_access_ai_conversation(
  target_conversation_id text
)
returns boolean
language sql
stable
security definer
set search_path = public, private, pg_temp
as $$
  select exists (
    select 1
    from public.ai_conversations c
    where c.id = target_conversation_id
      and (
        c.user_id::text = (select auth.uid())::text
        or lower(c.user_email) = private.jwt_email()
      )
  );
$$;

grant execute on function private.can_access_ai_conversation(text)
  to authenticated;

drop policy if exists ai_conversations_select_own_or_monitor
  on public.ai_conversations;
drop policy if exists ai_conversations_select_own
  on public.ai_conversations;
create policy ai_conversations_select_own
on public.ai_conversations
for select
to authenticated
using (
  user_id::text = (select auth.uid())::text
  or lower(user_email) = private.jwt_email()
);

drop policy if exists ai_conversations_update_own
  on public.ai_conversations;
create policy ai_conversations_update_own
on public.ai_conversations
for update
to authenticated
using (
  user_id::text = (select auth.uid())::text
  or lower(user_email) = private.jwt_email()
)
with check (
  user_id::text = (select auth.uid())::text
  or lower(user_email) = private.jwt_email()
);

drop policy if exists ai_messages_select_own_or_monitor
  on public.ai_messages;
drop policy if exists ai_messages_select_own
  on public.ai_messages;
create policy ai_messages_select_own
on public.ai_messages
for select
to authenticated
using (
  (
    user_id::text = (select auth.uid())::text
    or lower(user_email) = private.jwt_email()
  )
  and private.can_access_ai_conversation(conversation_id)
);

drop policy if exists ai_messages_insert_own
  on public.ai_messages;
create policy ai_messages_insert_own
on public.ai_messages
for insert
to authenticated
with check (
  (
    user_id::text = (select auth.uid())::text
    or lower(user_email) = private.jwt_email()
  )
  and private.can_access_ai_conversation(conversation_id)
);

drop policy if exists ai_usage_events_insert_own
  on public.ai_usage_events;
create policy ai_usage_events_insert_own
on public.ai_usage_events
for insert
to authenticated
with check (
  (
    user_id::text = (select auth.uid())::text
    or lower(user_email) = private.jwt_email()
  )
  and (
    conversation_id is null
    or private.can_access_ai_conversation(conversation_id)
  )
);
