-- One-time device provisioning for Granith IoT.
--
-- A sensor receives only an opaque provisioning secret. On its first boot the
-- firmware presents its hardware identifier, claims the secret and receives
-- its own device/project configuration. Plain secrets are never persisted.

alter table public.iot_devices
  add column if not exists "hardwareId" text,
  add column if not exists "telemetryIntervalSeconds" integer not null default 900,
  add column if not exists "provisionedAt" timestamptz;

alter table public.iot_devices
  drop constraint if exists iot_devices_hardware_id_format_check,
  add constraint iot_devices_hardware_id_format_check check (
    "hardwareId" is null or "hardwareId" ~ '^[0-9a-f]{12}$'
  ),
  drop constraint if exists iot_devices_telemetry_interval_check,
  add constraint iot_devices_telemetry_interval_check check (
    "telemetryIntervalSeconds" between 60 and 86400
  );

create unique index if not exists idx_iot_devices_hardware_id_unique
  on public.iot_devices ("hardwareId")
  where "hardwareId" is not null;

create table if not exists public.iot_device_provisioning_tokens (
  id text primary key default gen_random_uuid()::text,
  "projectId" text not null references public.projects(id) on delete restrict,
  "deviceId" text references public.iot_devices(id) on delete set null,
  "deviceName" text not null,
  kind text not null default 'siteSensor',
  "telemetryIntervalSeconds" integer not null default 900,
  "tokenHash" text not null unique,
  "hardwareId" text,
  "issuedBy" uuid references auth.users(id) on delete set null,
  "expiresAt" timestamptz not null,
  "claimedAt" timestamptz,
  "revokedAt" timestamptz,
  "createdAt" timestamptz not null default clock_timestamp(),
  constraint iot_device_provisioning_tokens_device_name_check check (
    length(trim("deviceName")) between 3 and 120
  ),
  constraint iot_device_provisioning_tokens_kind_check check (
    kind ~ '^[A-Za-z0-9_-]{3,48}$'
  ),
  constraint iot_device_provisioning_tokens_hash_check check (
    "tokenHash" ~ '^[a-f0-9]{64}$'
  ),
  constraint iot_device_provisioning_tokens_hardware_id_check check (
    "hardwareId" is null or "hardwareId" ~ '^[0-9a-f]{12}$'
  ),
  constraint iot_device_provisioning_tokens_interval_check check (
    "telemetryIntervalSeconds" between 60 and 86400
  ),
  constraint iot_device_provisioning_tokens_expiry_check check (
    "expiresAt" > "createdAt"
  ),
  constraint iot_device_provisioning_tokens_claim_check check (
    "claimedAt" is null or "hardwareId" is not null
  )
);

create index if not exists idx_iot_device_provisioning_tokens_pending
  on public.iot_device_provisioning_tokens ("projectId", "expiresAt")
  where "claimedAt" is null and "revokedAt" is null;

alter table public.iot_device_provisioning_tokens enable row level security;

revoke all on public.iot_device_provisioning_tokens from public, anon, authenticated;
grant select, insert, update, delete on public.iot_device_provisioning_tokens
  to service_role;
