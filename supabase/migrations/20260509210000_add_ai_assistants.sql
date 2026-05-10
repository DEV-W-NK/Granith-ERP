-- Isolated AI assistants:
-- - each user can read only their own conversations;
-- - monitoring requires explicit AI permission;
-- - assistants are read-only for business data and only write chat/usage logs.

create table if not exists public.ai_conversations (
  id text primary key default gen_random_uuid()::text,
  user_id text not null,
  user_email text not null default '',
  area text not null,
  title text not null default 'Nova conversa',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint ai_conversations_area_check check (
    area in (
      'operational',
      'human_resources',
      'commercial',
      'supplies',
      'administrative'
    )
  )
);

create table if not exists public.ai_messages (
  id text primary key default gen_random_uuid()::text,
  conversation_id text not null references public.ai_conversations(id) on delete cascade,
  user_id text not null,
  user_email text not null default '',
  area text not null,
  role text not null,
  content text not null,
  model text not null default '',
  prompt_tokens integer not null default 0,
  output_tokens integer not null default 0,
  total_tokens integer not null default 0,
  estimated_cost_usd numeric(14,6) not null default 0,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint ai_messages_area_check check (
    area in (
      'operational',
      'human_resources',
      'commercial',
      'supplies',
      'administrative'
    )
  ),
  constraint ai_messages_role_check check (role in ('user', 'model'))
);

create table if not exists public.ai_usage_events (
  id text primary key default gen_random_uuid()::text,
  conversation_id text references public.ai_conversations(id) on delete set null,
  message_id text references public.ai_messages(id) on delete set null,
  user_id text not null,
  user_email text not null default '',
  area text not null,
  model text not null default '',
  prompt_tokens integer not null default 0,
  output_tokens integer not null default 0,
  total_tokens integer not null default 0,
  estimated_cost_usd numeric(14,6) not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.ai_model_pricing (
  id text primary key,
  model text not null unique,
  input_per_million_usd numeric(14,6) not null default 0,
  output_per_million_usd numeric(14,6) not null default 0,
  currency text not null default 'USD',
  updated_by text,
  updated_at timestamptz not null default now()
);

insert into public.ai_model_pricing (
  id,
  model,
  input_per_million_usd,
  output_per_million_usd,
  currency
)
values ('gemini-2.5-flash', 'gemini-2.5-flash', 0.30, 2.50, 'USD')
on conflict (id) do nothing;

create index if not exists idx_ai_conversations_user_area
  on public.ai_conversations (user_id, area, updated_at desc);
create index if not exists idx_ai_conversations_email_area
  on public.ai_conversations (lower(user_email), area, updated_at desc);
create index if not exists idx_ai_messages_conversation_created
  on public.ai_messages (conversation_id, created_at);
create index if not exists idx_ai_usage_events_created
  on public.ai_usage_events (created_at desc);
create index if not exists idx_ai_usage_events_area
  on public.ai_usage_events (area, created_at desc);

alter table public.ai_conversations enable row level security;
alter table public.ai_messages enable row level security;
alter table public.ai_usage_events enable row level security;
alter table public.ai_model_pricing enable row level security;

create or replace function private.can_monitor_ai()
returns boolean
language sql
stable
security definer
set search_path = public, private, pg_temp
as $$
  select private.has_permission('ai.monitor')
    or private.has_permission('ai.dev.monitor')
    or private.has_permission('ai.owner.monitor');
$$;

create or replace function private.can_read_ai_usage()
returns boolean
language sql
stable
security definer
set search_path = public, private, pg_temp
as $$
  select private.is_admin()
    or private.can_monitor_ai()
    or private.has_permission('ai.usage.read')
    or private.has_permission('billing.manage')
    or private.has_permission('settings.manage');
$$;

create or replace function private.can_manage_ai_pricing()
returns boolean
language sql
stable
security definer
set search_path = public, private, pg_temp
as $$
  select private.has_permission('ai.pricing.manage')
    or private.has_permission('ai.dev.monitor');
$$;

grant execute on function private.can_monitor_ai() to authenticated;
grant execute on function private.can_read_ai_usage() to authenticated;
grant execute on function private.can_manage_ai_pricing() to authenticated;

drop policy if exists ai_conversations_select_own_or_monitor on public.ai_conversations;
create policy ai_conversations_select_own_or_monitor
on public.ai_conversations
for select
to authenticated
using (
  user_id::text = (select auth.uid())::text
  or lower(user_email) = private.jwt_email()
  or private.can_monitor_ai()
);

drop policy if exists ai_conversations_insert_own on public.ai_conversations;
create policy ai_conversations_insert_own
on public.ai_conversations
for insert
to authenticated
with check (
  user_id::text = (select auth.uid())::text
  or lower(user_email) = private.jwt_email()
);

drop policy if exists ai_conversations_update_own on public.ai_conversations;
create policy ai_conversations_update_own
on public.ai_conversations
for update
to authenticated
using (
  user_id::text = (select auth.uid())::text
  or lower(user_email) = private.jwt_email()
  or private.can_monitor_ai()
)
with check (
  user_id::text = (select auth.uid())::text
  or lower(user_email) = private.jwt_email()
  or private.can_monitor_ai()
);

drop policy if exists ai_messages_select_own_or_monitor on public.ai_messages;
create policy ai_messages_select_own_or_monitor
on public.ai_messages
for select
to authenticated
using (
  user_id::text = (select auth.uid())::text
  or lower(user_email) = private.jwt_email()
  or private.can_monitor_ai()
);

drop policy if exists ai_messages_insert_own on public.ai_messages;
create policy ai_messages_insert_own
on public.ai_messages
for insert
to authenticated
with check (
  user_id::text = (select auth.uid())::text
  or lower(user_email) = private.jwt_email()
);

drop policy if exists ai_usage_events_select_authorized on public.ai_usage_events;
create policy ai_usage_events_select_authorized
on public.ai_usage_events
for select
to authenticated
using (
  user_id::text = (select auth.uid())::text
  or lower(user_email) = private.jwt_email()
  or private.can_read_ai_usage()
);

drop policy if exists ai_usage_events_insert_own on public.ai_usage_events;
create policy ai_usage_events_insert_own
on public.ai_usage_events
for insert
to authenticated
with check (
  user_id::text = (select auth.uid())::text
  or lower(user_email) = private.jwt_email()
);

drop policy if exists ai_model_pricing_select_internal on public.ai_model_pricing;
create policy ai_model_pricing_select_internal
on public.ai_model_pricing
for select
to authenticated
using (private.is_internal_user());

drop policy if exists ai_model_pricing_manage_authorized on public.ai_model_pricing;
create policy ai_model_pricing_manage_authorized
on public.ai_model_pricing
for all
to authenticated
using (private.can_manage_ai_pricing())
with check (private.can_manage_ai_pricing());
