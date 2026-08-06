-- Granith IoT MQTT ingestion.
--
-- ESP32 devices publish only to an MQTT broker. The broker connects to this
-- database using granith_iot_ingest, which can INSERT telemetry but cannot
-- read, update or delete business data.

do $$
begin
  if not exists (
    select 1
      from pg_roles
     where rolname = 'granith_iot_ingest'
  ) then
    create role granith_iot_ingest
      nologin
      noinherit
      nocreatedb
      nocreaterole
      noreplication
      nobypassrls;
  end if;
end;
$$;

create table if not exists public.iot_devices (
  id text primary key,
  "projectId" text not null references public.projects(id) on delete restrict,
  name text not null,
  kind text not null default 'siteSensor',
  status text not null default 'active',
  "mqttClientId" text not null unique,
  "lastSeenAt" timestamptz,
  "lastRssiDbm" integer,
  "firmwareVersion" text,
  notes text not null default '',
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now(),
  constraint iot_devices_id_format_check check (
    id ~ '^[A-Za-z0-9_-]{3,96}$'
  ),
  constraint iot_devices_mqtt_client_id_format_check check (
    "mqttClientId" ~ '^[A-Za-z0-9_-]{3,96}$'
  ),
  constraint iot_devices_status_check check (
    status in ('active', 'maintenance', 'disabled')
  ),
  constraint iot_devices_mqtt_client_matches_id check (
    "mqttClientId" = id
  ),
  constraint iot_devices_rssi_range_check check (
    "lastRssiDbm" is null or "lastRssiDbm" between -127 and 0
  )
);

create index if not exists idx_iot_devices_project_status
  on public.iot_devices ("projectId", status);

create table if not exists public.iot_telemetry (
  id text primary key default gen_random_uuid()::text,
  "deviceId" text not null references public.iot_devices(id) on delete restrict,
  "projectId" text not null references public.projects(id) on delete restrict,
  "bootId" text not null,
  sequence bigint not null,
  "sampledAt" timestamptz,
  "receivedAt" timestamptz not null default clock_timestamp(),
  "rssiDbm" integer,
  "batteryMillivolts" integer,
  payload jsonb not null,
  constraint iot_telemetry_boot_id_format_check check (
    "bootId" ~ '^[A-Za-z0-9_-]{8,96}$'
  ),
  constraint iot_telemetry_sequence_check check (sequence >= 0),
  constraint iot_telemetry_payload_object_check check (
    jsonb_typeof(payload) = 'object'
  ),
  constraint iot_telemetry_payload_size_check check (
    octet_length(payload::text) <= 4096
  ),
  constraint iot_telemetry_rssi_range_check check (
    "rssiDbm" is null or "rssiDbm" between -127 and 0
  ),
  constraint iot_telemetry_battery_range_check check (
    "batteryMillivolts" is null
      or "batteryMillivolts" between 0 and 30000
  ),
  constraint iot_telemetry_device_boot_sequence_unique unique (
    "deviceId", "bootId", sequence
  )
);

create index if not exists idx_iot_telemetry_project_received
  on public.iot_telemetry ("projectId", "receivedAt" desc);
create index if not exists idx_iot_telemetry_device_received
  on public.iot_telemetry ("deviceId", "receivedAt" desc);

create or replace function private.prepare_iot_telemetry()
returns trigger
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_project_id text;
  v_device_status text;
  v_payload_boot_id text;
  v_payload_sequence bigint;
begin
  new."deviceId" := nullif(trim(coalesce(new."deviceId", '')), '');
  new."bootId" := nullif(trim(coalesce(new."bootId", '')), '');

  if new."deviceId" is null or new."bootId" is null then
    raise exception 'IoT telemetry requires a device ID and boot ID.';
  end if;

  select d."projectId", d.status
    into v_project_id, v_device_status
    from public.iot_devices d
   where d.id = new."deviceId"
   for share;

  if not found then
    raise exception 'IoT device % is not registered.', new."deviceId";
  end if;

  if v_device_status <> 'active' then
    raise exception 'IoT device % is not active.', new."deviceId";
  end if;

  if jsonb_typeof(new.payload) <> 'object' then
    raise exception 'IoT telemetry payload must be a JSON object.';
  end if;

  v_payload_boot_id := nullif(trim(coalesce(new.payload ->> 'bootId', '')), '');
  if v_payload_boot_id is not null and v_payload_boot_id <> new."bootId" then
    raise exception 'IoT telemetry boot ID does not match the payload.';
  end if;

  begin
    v_payload_sequence := nullif(new.payload ->> 'sequence', '')::bigint;
  exception
    when invalid_text_representation then
      raise exception 'IoT telemetry sequence must be numeric.';
  end;

  if v_payload_sequence is not null and v_payload_sequence <> new.sequence then
    raise exception 'IoT telemetry sequence does not match the payload.';
  end if;

  new."projectId" := v_project_id;
  new."receivedAt" := clock_timestamp();
  new."rssiDbm" := coalesce(
    new."rssiDbm",
    nullif(new.payload ->> 'rssiDbm', '')::integer
  );
  new."batteryMillivolts" := coalesce(
    new."batteryMillivolts",
    nullif(new.payload ->> 'batteryMillivolts', '')::integer
  );

  if new."sampledAt" is not null
      and (
        new."sampledAt" < clock_timestamp() - interval '90 days'
        or new."sampledAt" > clock_timestamp() + interval '10 minutes'
      ) then
    raise exception 'IoT sampled timestamp is outside the accepted range.';
  end if;

  update public.iot_devices
     set "lastSeenAt" = new."receivedAt",
         "lastRssiDbm" = new."rssiDbm",
         "firmwareVersion" = coalesce(
           nullif(trim(new.payload ->> 'firmware'), ''),
           "firmwareVersion"
         ),
         "updatedAt" = new."receivedAt"
   where id = new."deviceId";

  return new;
end;
$$;

drop trigger if exists prepare_iot_telemetry on public.iot_telemetry;
create trigger prepare_iot_telemetry
before insert on public.iot_telemetry
for each row
execute function private.prepare_iot_telemetry();

create or replace function private.touch_iot_device()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  new."updatedAt" := clock_timestamp();
  return new;
end;
$$;

drop trigger if exists touch_iot_device on public.iot_devices;
create trigger touch_iot_device
before update on public.iot_devices
for each row
execute function private.touch_iot_device();

alter table public.iot_devices enable row level security;
alter table public.iot_telemetry enable row level security;

drop policy if exists iot_devices_select_fleet_readers on public.iot_devices;
create policy iot_devices_select_fleet_readers
on public.iot_devices
for select
to authenticated
using (private.can_read_fleet());

drop policy if exists iot_devices_manage_fleet on public.iot_devices;
create policy iot_devices_manage_fleet
on public.iot_devices
for all
to authenticated
using (private.can_manage_fleet())
with check (private.can_manage_fleet());

drop policy if exists iot_telemetry_select_fleet_readers on public.iot_telemetry;
create policy iot_telemetry_select_fleet_readers
on public.iot_telemetry
for select
to authenticated
using (private.can_read_fleet());

drop policy if exists iot_telemetry_insert_mqtt_bridge on public.iot_telemetry;
create policy iot_telemetry_insert_mqtt_bridge
on public.iot_telemetry
for insert
to granith_iot_ingest
with check (true);

revoke all on public.iot_devices from public, anon;
revoke all on public.iot_telemetry from public, anon;
revoke all on public.iot_telemetry from authenticated;
revoke all on function private.prepare_iot_telemetry() from public, anon, authenticated;

grant select, insert, update, delete on public.iot_devices to authenticated;
grant select on public.iot_telemetry to authenticated;
grant select, insert, update, delete on public.iot_devices to service_role;
grant select, insert on public.iot_telemetry to service_role;
grant usage on schema public to granith_iot_ingest;
grant insert on public.iot_telemetry to granith_iot_ingest;
