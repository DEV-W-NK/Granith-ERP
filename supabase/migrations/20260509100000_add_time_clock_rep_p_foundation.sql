-- Granith REP-P foundation.
-- The AFD table is append-only by trigger. Corrections must be represented by
-- new events or by future treatment tables, never by mutating raw records.

alter table public.system_settings
  add column if not exists time_clock_enabled boolean not null default true;

alter table public.system_settings
  add column if not exists time_clock_geofence_required boolean not null default true;

alter table public.system_settings
  add column if not exists time_clock_store_rejected_attempts boolean not null default true;

alter table public.system_settings
  add column if not exists time_clock_inpi_registration_number text not null default '';

alter table public.system_settings
  add column if not exists time_clock_employer_name text not null default '';

alter table public.system_settings
  add column if not exists time_clock_employer_document text not null default '';

alter table public.system_settings
  add column if not exists time_clock_timezone text not null default 'America/Sao_Paulo';

create table if not exists public.time_clock_establishments (
  id text primary key default gen_random_uuid()::text,
  name text not null default 'Matriz',
  "documentNumber" text not null default '',
  timezone text not null default 'America/Sao_Paulo',
  "nextNsr" bigint not null default 1,
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now(),
  constraint time_clock_establishments_next_nsr_check check ("nextNsr" > 0)
);

insert into public.time_clock_establishments (id, name, timezone)
values ('default', 'Matriz', 'America/Sao_Paulo')
on conflict (id) do nothing;

drop trigger if exists trg_time_clock_establishments_updated_at on public.time_clock_establishments;
create trigger trg_time_clock_establishments_updated_at
before update on public.time_clock_establishments
for each row execute function public.set_updated_at();

create table if not exists public.time_clock_afd_events (
  id text primary key default gen_random_uuid()::text,
  "establishmentId" text not null default 'default'
    references public.time_clock_establishments(id) on delete restrict,
  nsr bigint not null,
  "eventKind" text not null,
  "eventSource" text not null default 'mobile',
  "punchType" text not null default 'unknown',
  "employeeId" text references public.employees(id) on delete set null,
  "employeeName" text not null default '',
  "employeeCpf" text not null default '',
  "userId" text not null default '',
  "projectId" text references public.projects(id) on delete set null,
  "projectName" text not null default '',
  "eventAt" timestamptz not null default now(),
  "timeZone" text not null default 'America/Sao_Paulo',
  latitude numeric(10,7),
  longitude numeric(10,7),
  "accuracyMeters" numeric(10,2),
  "geofenceStatus" text not null default 'unknown',
  "geofenceId" text,
  "geofenceName" text not null default '',
  "deviceId" text not null default '',
  "ipAddress" text not null default '',
  "receiptCode" text not null default '',
  offline boolean not null default false,
  reason text not null default '',
  "rawPayload" jsonb not null default '{}'::jsonb,
  "previousHash" text,
  "eventHash" text not null default '',
  "createdAt" timestamptz not null default now(),
  constraint time_clock_afd_events_unique_nsr unique ("establishmentId", nsr),
  constraint time_clock_afd_events_kind_check check (
    "eventKind" in (
      'employee_include',
      'employee_update',
      'employee_delete',
      'punch',
      'rejected_punch',
      'manual_work_hours',
      'system_event'
    )
  ),
  constraint time_clock_afd_events_source_check check (
    "eventSource" in ('mobile', 'web', 'import', 'system')
  ),
  constraint time_clock_afd_events_punch_type_check check (
    "punchType" in ('entry', 'exit', 'interval_start', 'interval_end', 'unknown')
  ),
  constraint time_clock_afd_events_geofence_status_check check (
    "geofenceStatus" in ('inside', 'outside', 'unknown', 'disabled')
  ),
  constraint time_clock_afd_events_latitude_check check (
    latitude is null or latitude between -90 and 90
  ),
  constraint time_clock_afd_events_longitude_check check (
    longitude is null or longitude between -180 and 180
  )
);

create index if not exists idx_time_clock_afd_events_employee_event_at
  on public.time_clock_afd_events ("employeeId", "eventAt" desc);

create index if not exists idx_time_clock_afd_events_project_event_at
  on public.time_clock_afd_events ("projectId", "eventAt" desc);

create index if not exists idx_time_clock_afd_events_event_kind
  on public.time_clock_afd_events ("eventKind");

create or replace function public.prepare_time_clock_afd_event()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  assigned_nsr bigint;
  last_hash text;
begin
  if new."establishmentId" is null or trim(new."establishmentId") = '' then
    new."establishmentId" := 'default';
  end if;

  insert into public.time_clock_establishments (id)
  values (new."establishmentId")
  on conflict (id) do nothing;

  update public.time_clock_establishments
     set "nextNsr" = "nextNsr" + 1
   where id = new."establishmentId"
   returning "nextNsr" - 1 into assigned_nsr;

  new.nsr := assigned_nsr;

  select "eventHash"
    into last_hash
    from public.time_clock_afd_events
   where "establishmentId" = new."establishmentId"
   order by nsr desc
   limit 1;

  new."previousHash" := last_hash;

  new."eventHash" := encode(
    digest(
      concat_ws(
        '|',
        new."establishmentId",
        new.nsr::text,
        new."eventKind",
        new."eventSource",
        new."punchType",
        coalesce(new."employeeId", ''),
        new."employeeCpf",
        new."projectId",
        new."eventAt"::text,
        new."timeZone",
        coalesce(new.latitude::text, ''),
        coalesce(new.longitude::text, ''),
        new."geofenceStatus",
        coalesce(new."previousHash", ''),
        new."rawPayload"::text
      ),
      'sha256'
    ),
    'hex'
  );

  if new."receiptCode" is null or trim(new."receiptCode") = '' then
    new."receiptCode" := upper(substr(new."eventHash", 1, 16));
  end if;

  return new;
end;
$$;

create or replace function public.block_time_clock_afd_mutation()
returns trigger
language plpgsql
as $$
begin
  raise exception 'time_clock_afd_events is append-only; create a new event instead.';
end;
$$;

drop trigger if exists trg_prepare_time_clock_afd_event on public.time_clock_afd_events;
create trigger trg_prepare_time_clock_afd_event
before insert on public.time_clock_afd_events
for each row execute function public.prepare_time_clock_afd_event();

drop trigger if exists trg_block_time_clock_afd_update on public.time_clock_afd_events;
create trigger trg_block_time_clock_afd_update
before update on public.time_clock_afd_events
for each row execute function public.block_time_clock_afd_mutation();

drop trigger if exists trg_block_time_clock_afd_delete on public.time_clock_afd_events;
create trigger trg_block_time_clock_afd_delete
before delete on public.time_clock_afd_events
for each row execute function public.block_time_clock_afd_mutation();

create table if not exists public.mobile_work_hour_entries (
  id text primary key default gen_random_uuid()::text,
  "employeeId" text references public.employees(id) on delete set null,
  "employeeName" text not null default '',
  "userId" text not null default '',
  "projectId" text references public.projects(id) on delete set null,
  "projectName" text not null default '',
  "startAt" timestamptz not null,
  "endAt" timestamptz not null,
  "durationMinutes" integer not null default 0,
  reason text not null default '',
  source text not null default 'manual_offsite',
  status text not null default 'pending',
  "approvedBy" text,
  "approvedAt" timestamptz,
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now(),
  constraint mobile_work_hour_entries_duration_check check ("durationMinutes" >= 0),
  constraint mobile_work_hour_entries_range_check check ("endAt" > "startAt"),
  constraint mobile_work_hour_entries_status_check check (
    status in ('pending', 'approved', 'rejected', 'cancelled')
  )
);

create index if not exists idx_mobile_work_hour_entries_employee_start
  on public.mobile_work_hour_entries ("employeeId", "startAt" desc);

create index if not exists idx_mobile_work_hour_entries_project_start
  on public.mobile_work_hour_entries ("projectId", "startAt" desc);

drop trigger if exists trg_mobile_work_hour_entries_updated_at on public.mobile_work_hour_entries;
create trigger trg_mobile_work_hour_entries_updated_at
before update on public.mobile_work_hour_entries
for each row execute function public.set_updated_at();

alter table public.time_clock_establishments enable row level security;
alter table public.time_clock_afd_events enable row level security;
alter table public.mobile_work_hour_entries enable row level security;

drop policy if exists time_clock_establishments_select_internal on public.time_clock_establishments;
create policy time_clock_establishments_select_internal
on public.time_clock_establishments
for select
to authenticated
using (private.is_internal_user());

drop policy if exists time_clock_establishments_manage_settings on public.time_clock_establishments;
create policy time_clock_establishments_manage_settings
on public.time_clock_establishments
for all
to authenticated
using (private.can_manage_settings())
with check (private.can_manage_settings());

drop policy if exists time_clock_afd_events_select_internal on public.time_clock_afd_events;
create policy time_clock_afd_events_select_internal
on public.time_clock_afd_events
for select
to authenticated
using (private.is_internal_user());

drop policy if exists time_clock_afd_events_insert_internal on public.time_clock_afd_events;
create policy time_clock_afd_events_insert_internal
on public.time_clock_afd_events
for insert
to authenticated
with check (private.is_internal_user());

drop policy if exists mobile_work_hour_entries_select_internal on public.mobile_work_hour_entries;
create policy mobile_work_hour_entries_select_internal
on public.mobile_work_hour_entries
for select
to authenticated
using (private.is_internal_user());

drop policy if exists mobile_work_hour_entries_insert_internal on public.mobile_work_hour_entries;
create policy mobile_work_hour_entries_insert_internal
on public.mobile_work_hour_entries
for insert
to authenticated
with check (private.is_internal_user());

drop policy if exists mobile_work_hour_entries_manage_people on public.mobile_work_hour_entries;
create policy mobile_work_hour_entries_manage_people
on public.mobile_work_hour_entries
for update
to authenticated
using (private.can_manage_people())
with check (private.can_manage_people());

grant select, insert, update on public.time_clock_establishments to authenticated;
grant select, insert on public.time_clock_afd_events to authenticated;
grant select, insert, update on public.mobile_work_hour_entries to authenticated;
