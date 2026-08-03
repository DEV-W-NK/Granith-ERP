-- Granith Engenharia P4 - ecosystem integration.
-- Supabase remains the source of truth for Engineering, ERP and Mobile.

create extension if not exists pgcrypto;

-- Keep legacy rows valid before tightening the notification category contract.
update public.mobile_push_notifications
set category = 'system'
where category not in (
  'route',
  'project',
  'team',
  'benefit',
  'material',
  'requisition',
  'purchase',
  'timeClock',
  'measurement',
  'vehicle',
  'sync',
  'task',
  'engineering',
  'system'
);

alter table public.mobile_push_notifications
  drop constraint if exists mobile_push_notifications_category_check;
alter table public.mobile_push_notifications
  add constraint mobile_push_notifications_category_check check (
    category in (
      'route',
      'project',
      'team',
      'benefit',
      'material',
      'requisition',
      'purchase',
      'timeClock',
      'measurement',
      'vehicle',
      'sync',
      'task',
      'engineering',
      'system'
    )
  );

alter table public.engineering_deliveries
  add column if not exists "recipientUserId" text
    references public.users(id) on delete set null,
  add column if not exists "recipientEmployeeId" text
    references public.employees(id) on delete set null,
  add column if not exists "idempotencyKey" text,
  add column if not exists "correlationId" text,
  add column if not exists version integer not null default 1,
  add column if not exists "lastReceiptAt" timestamptz;

create unique index if not exists idx_engineering_deliveries_idempotency
  on public.engineering_deliveries ("idempotencyKey")
  where nullif("idempotencyKey", '') is not null;
create index if not exists idx_engineering_deliveries_recipient_employee
  on public.engineering_deliveries (
    "recipientEmployeeId",
    status,
    "createdAt" desc
  )
  where "recipientEmployeeId" is not null;
create index if not exists idx_engineering_deliveries_recipient_user
  on public.engineering_deliveries (
    "recipientUserId",
    status,
    "createdAt" desc
  )
  where "recipientUserId" is not null;

create table if not exists public.engineering_technical_reports (
  id text primary key default gen_random_uuid()::text,
  "projectId" text not null references public.projects(id) on delete cascade,
  "sourceType" text not null default 'manual',
  "sourceId" text,
  "reportType" text not null default 'technical',
  title text not null,
  version integer not null default 1,
  status text not null default 'generated',
  bucket text not null default 'engineering-reports',
  "filePath" text not null,
  "originalFileName" text not null,
  "mimeType" text not null default 'application/pdf',
  "sizeBytes" bigint not null default 0,
  sha256 text not null,
  summary jsonb not null default '{}'::jsonb,
  "generatedByUserId" text not null default '',
  "approvedByUserId" text,
  "generatedAt" timestamptz not null default now(),
  "approvedAt" timestamptz,
  "revokedAt" timestamptz,
  "correlationId" text,
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now(),
  constraint engineering_technical_reports_source_check check (
    "sourceType" in (
      'manual',
      'document',
      'analysis',
      'quantityTakeoff',
      'delivery'
    )
  ),
  constraint engineering_technical_reports_type_check check (
    "reportType" in (
      'technical',
      'drawingAnalysis',
      'quantityTakeoff',
      'inspection',
      'delivery',
      'rfi'
    )
  ),
  constraint engineering_technical_reports_status_check check (
    status in ('generated', 'approved', 'published', 'revoked', 'failed')
  ),
  constraint engineering_technical_reports_version_check check (version > 0),
  constraint engineering_technical_reports_size_check check ("sizeBytes" > 0),
  constraint engineering_technical_reports_sha_check check (
    sha256 ~ '^[a-f0-9]{64}$'
  )
);

create unique index if not exists idx_engineering_reports_source_version
  on public.engineering_technical_reports (
    "projectId",
    "sourceType",
    "sourceId",
    "reportType",
    version
  )
  where "sourceId" is not null and "revokedAt" is null;
create index if not exists idx_engineering_reports_project_status
  on public.engineering_technical_reports (
    "projectId",
    status,
    "generatedAt" desc
  );

create table if not exists public.engineering_client_report_publications (
  id text primary key default gen_random_uuid()::text,
  "projectId" text not null references public.projects(id) on delete cascade,
  "reportId" text not null
    references public.engineering_technical_reports(id) on delete restrict,
  title text not null,
  notes text not null default '',
  "publishedByUserId" text not null default '',
  "publishedAt" timestamptz not null default now(),
  "revokedByUserId" text,
  "revokedAt" timestamptz,
  "correlationId" text,
  "createdAt" timestamptz not null default now()
);

create unique index if not exists idx_engineering_report_publication_active
  on public.engineering_client_report_publications ("reportId")
  where "revokedAt" is null;
create index if not exists idx_engineering_report_publications_project
  on public.engineering_client_report_publications (
    "projectId",
    "publishedAt" desc
  )
  where "revokedAt" is null;

create table if not exists public.engineering_delivery_reports (
  id text primary key default gen_random_uuid()::text,
  "projectId" text not null references public.projects(id) on delete cascade,
  "deliveryId" text not null
    references public.engineering_deliveries(id) on delete cascade,
  "reportId" text not null
    references public.engineering_technical_reports(id) on delete restrict,
  "createdAt" timestamptz not null default now(),
  unique ("deliveryId", "reportId")
);

create table if not exists public.engineering_delivery_receipts (
  id text primary key default gen_random_uuid()::text,
  "projectId" text not null references public.projects(id) on delete cascade,
  "deliveryId" text not null
    references public.engineering_deliveries(id) on delete cascade,
  status text not null default 'acknowledged',
  notes text not null default '',
  source text not null default 'engineering',
  "recipientUserId" text references public.users(id) on delete set null,
  "recipientEmployeeId" text references public.employees(id) on delete set null,
  "idempotencyKey" text not null,
  "correlationId" text,
  "occurredAt" timestamptz not null default now(),
  "createdAt" timestamptz not null default now(),
  constraint engineering_delivery_receipts_status_check check (
    status in ('acknowledged', 'revisionRequested')
  ),
  constraint engineering_delivery_receipts_source_check check (
    source in ('engineering', 'erp', 'mobile', 'clientPortal', 'offlineSync')
  ),
  unique ("idempotencyKey")
);

create index if not exists idx_engineering_delivery_receipts_delivery
  on public.engineering_delivery_receipts (
    "deliveryId",
    "occurredAt" desc
  );

create table if not exists public.engineering_ecosystem_events (
  id bigint generated always as identity primary key,
  "eventId" text not null default gen_random_uuid()::text,
  "projectId" text references public.projects(id) on delete set null,
  "eventType" text not null,
  "aggregateType" text not null,
  "aggregateId" text not null,
  "actorUserId" text,
  "actorEmployeeId" text,
  source text not null default 'database',
  "correlationId" text not null default gen_random_uuid()::text,
  payload jsonb not null default '{}'::jsonb,
  "createdAt" timestamptz not null default now(),
  unique ("eventId")
);

create index if not exists idx_engineering_events_project
  on public.engineering_ecosystem_events (
    "projectId",
    "createdAt" desc
  );
create index if not exists idx_engineering_events_correlation
  on public.engineering_ecosystem_events ("correlationId");

create table if not exists public.engineering_offline_operations (
  "operationId" text primary key,
  "userId" text not null,
  "employeeId" text,
  "operationType" text not null,
  "entityId" text,
  "projectId" text references public.projects(id) on delete set null,
  payload jsonb not null default '{}'::jsonb,
  result jsonb not null default '{}'::jsonb,
  status text not null default 'applied',
  "appliedAt" timestamptz not null default now(),
  constraint engineering_offline_operations_type_check check (
    "operationType" in (
      'acknowledgeDelivery',
      'requestDeliveryRevision',
      'markNotificationRead'
    )
  ),
  constraint engineering_offline_operations_status_check check (
    status in ('applied', 'rejected')
  )
);

alter table public.engineering_audit_events
  add column if not exists "actorEmployeeId" text,
  add column if not exists "actorEmail" text,
  add column if not exists source text not null default 'database',
  add column if not exists "correlationId" text,
  add column if not exists "requestId" text,
  add column if not exists "beforeData" jsonb,
  add column if not exists "afterData" jsonb;

create index if not exists idx_engineering_audit_actor
  on public.engineering_audit_events (
    "actorUserId",
    "createdAt" desc
  );
create index if not exists idx_engineering_audit_entity
  on public.engineering_audit_events (
    "entityType",
    "entityId",
    "createdAt" desc
  );
create index if not exists idx_engineering_audit_correlation
  on public.engineering_audit_events ("correlationId");

create or replace function private.record_engineering_audit()
returns trigger
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  old_data jsonb := case when tg_op = 'INSERT' then null else to_jsonb(old) end;
  new_data jsonb := case when tg_op = 'DELETE' then null else to_jsonb(new) end;
  row_data jsonb := coalesce(new_data, old_data, '{}'::jsonb);
  request_headers jsonb := '{}'::jsonb;
  correlation_id text;
  request_id text;
begin
  begin
    request_headers := coalesce(
      nullif(current_setting('request.headers', true), '')::jsonb,
      '{}'::jsonb
    );
  exception
    when others then request_headers := '{}'::jsonb;
  end;

  correlation_id := coalesce(
    nullif(row_data ->> 'correlationId', ''),
    nullif(request_headers ->> 'x-correlation-id', ''),
    gen_random_uuid()::text
  );
  request_id := coalesce(
    nullif(request_headers ->> 'x-request-id', ''),
    nullif(request_headers ->> 'cf-ray', '')
  );

  insert into public.engineering_audit_events (
    "projectId",
    "actorUserId",
    "actorEmployeeId",
    "actorEmail",
    action,
    "entityType",
    "entityId",
    source,
    "correlationId",
    "requestId",
    "beforeData",
    "afterData",
    payload
  )
  values (
    nullif(row_data ->> 'projectId', ''),
    (select auth.uid())::text,
    private.current_user_employee_id(),
    nullif((select auth.jwt()) ->> 'email', ''),
    lower(tg_op),
    tg_table_name,
    coalesce(row_data ->> 'id', ''),
    coalesce(nullif(row_data ->> 'source', ''), 'database'),
    correlation_id,
    request_id,
    old_data,
    new_data,
    jsonb_build_object(
      'operation', lower(tg_op),
      'table', tg_table_name
    )
  );

  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

revoke all on function private.record_engineering_audit()
  from public, anon, authenticated;

create or replace function private.emit_engineering_event(
  p_project_id text,
  p_event_type text,
  p_aggregate_type text,
  p_aggregate_id text,
  p_payload jsonb default '{}'::jsonb,
  p_source text default 'database',
  p_correlation_id text default null
)
returns text
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  event_id text;
begin
  insert into public.engineering_ecosystem_events (
    "projectId",
    "eventType",
    "aggregateType",
    "aggregateId",
    "actorUserId",
    "actorEmployeeId",
    source,
    "correlationId",
    payload
  )
  values (
    nullif(p_project_id, ''),
    trim(p_event_type),
    trim(p_aggregate_type),
    trim(p_aggregate_id),
    (select auth.uid())::text,
    private.current_user_employee_id(),
    coalesce(nullif(trim(p_source), ''), 'database'),
    coalesce(nullif(trim(p_correlation_id), ''), gen_random_uuid()::text),
    coalesce(p_payload, '{}'::jsonb)
  )
  returning "eventId" into event_id;

  return event_id;
end;
$$;

revoke all on function private.emit_engineering_event(
  text,
  text,
  text,
  text,
  jsonb,
  text,
  text
) from public, anon, authenticated;

create or replace function private.notify_engineering_project_people(
  p_project_id text,
  p_title text,
  p_body text,
  p_payload jsonb default '{}'::jsonb,
  p_priority text default 'normal',
  p_excluded_employee_id text default null
)
returns integer
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  employee_id text;
  sent_count integer := 0;
begin
  for employee_id in
    with project_people as (
      select project."coordinatorId"::text as id
      from public.projects project
      where project.id::text = p_project_id

      union

      select team."leaderId"::text
      from public.teams team
      where team."projectId"::text = p_project_id

      union

      select member_id::text
      from public.teams team
      cross join lateral unnest(coalesce(team."memberIds", '{}'::text[]))
        member_id
      where team."projectId"::text = p_project_id
    )
    select distinct id
    from project_people
    where nullif(id, '') is not null
      and id is distinct from nullif(p_excluded_employee_id, '')
  loop
    perform private.enqueue_mobile_push_notification(
      null,
      employee_id,
      p_title,
      p_body,
      'engineering',
      coalesce(
        nullif(p_payload ->> 'actionRoute', ''),
        'engineering'
      ),
      jsonb_build_object(
        'sync', true,
        'syncReason', coalesce(p_payload ->> 'eventType', 'engineering_changed'),
        'syncTargets', jsonb_build_array(
          'workspace',
          'projects',
          'engineeringDocuments',
          'engineeringDeliveries',
          'engineeringReports'
        ),
        'projectId', p_project_id
      ) || coalesce(p_payload, '{}'::jsonb),
      p_priority
    );
    sent_count := sent_count + 1;
  end loop;

  return sent_count;
end;
$$;

revoke all on function private.notify_engineering_project_people(
  text,
  text,
  text,
  jsonb,
  text,
  text
) from public, anon, authenticated;

create or replace function public.create_engineering_delivery(
  p_project_id text,
  p_title text,
  p_recipient text default '',
  p_recipient_user_id text default null,
  p_recipient_employee_id text default null,
  p_recipient_email text default null,
  p_due_at timestamptz default null,
  p_revision_ids text[] default '{}'::text[],
  p_report_ids text[] default '{}'::text[],
  p_idempotency_key text default null
)
returns public.engineering_deliveries
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  delivery public.engineering_deliveries;
  revision_id text;
  report_id text;
  correlation_id text := gen_random_uuid()::text;
begin
  if not private.can_access_engineering_project(p_project_id) then
    raise exception using errcode = '42501',
      message = 'Sem acesso a obra para criar a entrega.';
  end if;
  if nullif(trim(p_title), '') is null then
    raise exception using errcode = '22023',
      message = 'Informe o titulo da entrega.';
  end if;

  if nullif(trim(coalesce(p_idempotency_key, '')), '') is not null then
    select *
    into delivery
    from public.engineering_deliveries item
    where item."idempotencyKey" = trim(p_idempotency_key)
    limit 1;
    if delivery.id is not null then
      return delivery;
    end if;
  end if;

  insert into public.engineering_deliveries (
    "projectId",
    title,
    recipient,
    "recipientEmail",
    "recipientUserId",
    "recipientEmployeeId",
    status,
    "dueAt",
    "createdByUserId",
    "idempotencyKey",
    "correlationId"
  )
  values (
    p_project_id,
    trim(p_title),
    coalesce(nullif(trim(p_recipient), ''), 'Destinatario'),
    nullif(trim(coalesce(p_recipient_email, '')), ''),
    nullif(trim(coalesce(p_recipient_user_id, '')), ''),
    nullif(trim(coalesce(p_recipient_employee_id, '')), ''),
    'preparing',
    p_due_at,
    (select auth.uid())::text,
    nullif(trim(coalesce(p_idempotency_key, '')), ''),
    correlation_id
  )
  returning * into delivery;

  foreach revision_id in array coalesce(p_revision_ids, '{}'::text[])
  loop
    insert into public.engineering_delivery_documents (
      "projectId",
      "deliveryId",
      "documentRevisionId"
    )
    select
      p_project_id,
      delivery.id,
      revision.id
    from public.engineering_document_revisions revision
    where revision.id = revision_id
      and revision."projectId" = p_project_id
      and revision.status = 'approved'
    on conflict ("deliveryId", "documentRevisionId") do nothing;
  end loop;

  foreach report_id in array coalesce(p_report_ids, '{}'::text[])
  loop
    insert into public.engineering_delivery_reports (
      "projectId",
      "deliveryId",
      "reportId"
    )
    select
      p_project_id,
      delivery.id,
      report.id
    from public.engineering_technical_reports report
    where report.id = report_id
      and report."projectId" = p_project_id
      and report.status in ('approved', 'published')
      and report."revokedAt" is null
    on conflict ("deliveryId", "reportId") do nothing;
  end loop;

  perform private.emit_engineering_event(
    p_project_id,
    'engineering.delivery.created',
    'engineeringDelivery',
    delivery.id,
    jsonb_build_object(
      'status', delivery.status,
      'recipientEmployeeId', delivery."recipientEmployeeId",
      'recipientUserId', delivery."recipientUserId"
    ),
    'engineering',
    correlation_id
  );
  return delivery;
end;
$$;

create or replace function public.send_engineering_delivery(
  p_delivery_id text,
  p_idempotency_key text default null
)
returns public.engineering_deliveries
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  delivery public.engineering_deliveries;
  correlation_id text;
begin
  select *
  into delivery
  from public.engineering_deliveries item
  where item.id = p_delivery_id
  for update;

  if delivery.id is null
    or not private.can_access_engineering_project(delivery."projectId")
  then
    raise exception using errcode = '42501',
      message = 'Entrega indisponivel.';
  end if;
  if delivery.status in ('acknowledged', 'revisionRequested', 'cancelled') then
    return delivery;
  end if;

  correlation_id := coalesce(
    nullif(delivery."correlationId", ''),
    gen_random_uuid()::text
  );
  update public.engineering_deliveries
  set
    status = 'sent',
    "sentAt" = coalesce("sentAt", clock_timestamp()),
    "idempotencyKey" = coalesce(
      "idempotencyKey",
      nullif(trim(coalesce(p_idempotency_key, '')), '')
    ),
    "correlationId" = correlation_id,
    version = version + 1,
    "updatedAt" = clock_timestamp()
  where id = delivery.id
  returning * into delivery;

  perform private.enqueue_mobile_push_notification(
    delivery."recipientUserId",
    delivery."recipientEmployeeId",
    'Nova entrega tecnica',
    delivery.title,
    'engineering',
    'engineering_deliveries',
    jsonb_build_object(
      'sync', true,
      'syncReason', 'engineering_delivery_sent',
      'syncTargets', jsonb_build_array(
        'workspace',
        'engineeringDeliveries',
        'engineeringDocuments',
        'engineeringReports'
      ),
      'eventType', 'engineering.delivery.sent',
      'deliveryId', delivery.id,
      'projectId', delivery."projectId",
      'correlationId', correlation_id
    ),
    'high'
  );
  perform private.emit_engineering_event(
    delivery."projectId",
    'engineering.delivery.sent',
    'engineeringDelivery',
    delivery.id,
    jsonb_build_object('status', delivery.status),
    'engineering',
    correlation_id
  );
  return delivery;
end;
$$;

create or replace function public.acknowledge_engineering_delivery(
  p_delivery_id text,
  p_status text default 'acknowledged',
  p_notes text default '',
  p_idempotency_key text default null,
  p_source text default 'engineering'
)
returns public.engineering_delivery_receipts
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  delivery public.engineering_deliveries;
  receipt public.engineering_delivery_receipts;
  operation_key text := coalesce(
    nullif(trim(coalesce(p_idempotency_key, '')), ''),
    gen_random_uuid()::text
  );
  current_user_id text := (select auth.uid())::text;
  current_employee_id text := private.current_user_employee_id();
  correlation_id text;
begin
  if p_status not in ('acknowledged', 'revisionRequested') then
    raise exception using errcode = '22023',
      message = 'Status de recebimento invalido.';
  end if;
  if p_source not in (
    'engineering',
    'erp',
    'mobile',
    'clientPortal',
    'offlineSync'
  ) then
    raise exception using errcode = '22023',
      message = 'Origem de recebimento invalida.';
  end if;

  select *
  into receipt
  from public.engineering_delivery_receipts item
  where item."idempotencyKey" = operation_key
  limit 1;
  if receipt.id is not null then
    return receipt;
  end if;

  select *
  into delivery
  from public.engineering_deliveries item
  where item.id = p_delivery_id
  for update;

  if delivery.id is null then
    raise exception using errcode = 'P0002', message = 'Entrega nao encontrada.';
  end if;
  if not (
    private.can_access_engineering_project(delivery."projectId")
    or delivery."recipientUserId" = current_user_id
    or delivery."recipientEmployeeId" = current_employee_id
    or private.client_can_access_project(delivery."projectId")
  ) then
    raise exception using errcode = '42501',
      message = 'Sem acesso para confirmar esta entrega.';
  end if;

  correlation_id := coalesce(
    nullif(delivery."correlationId", ''),
    gen_random_uuid()::text
  );
  insert into public.engineering_delivery_receipts (
    "projectId",
    "deliveryId",
    status,
    notes,
    source,
    "recipientUserId",
    "recipientEmployeeId",
    "idempotencyKey",
    "correlationId"
  )
  values (
    delivery."projectId",
    delivery.id,
    p_status,
    coalesce(p_notes, ''),
    p_source,
    current_user_id,
    current_employee_id,
    operation_key,
    correlation_id
  )
  returning * into receipt;

  update public.engineering_deliveries
  set
    status = p_status,
    "acknowledgedAt" = case
      when p_status = 'acknowledged' then clock_timestamp()
      else "acknowledgedAt"
    end,
    "lastReceiptAt" = receipt."occurredAt",
    version = version + 1,
    "updatedAt" = clock_timestamp()
  where id = delivery.id;

  perform private.enqueue_mobile_push_notification(
    nullif(delivery."createdByUserId", ''),
    null,
    case
      when p_status = 'acknowledged' then 'Entrega tecnica recebida'
      else 'Revisao de entrega solicitada'
    end,
    delivery.title,
    'engineering',
    'engineering_deliveries',
    jsonb_build_object(
      'sync', true,
      'syncReason', 'engineering_delivery_receipt',
      'syncTargets', jsonb_build_array(
        'workspace',
        'engineeringDeliveries'
      ),
      'eventType', 'engineering.delivery.' || p_status,
      'deliveryId', delivery.id,
      'receiptId', receipt.id,
      'projectId', delivery."projectId",
      'correlationId', correlation_id
    ),
    case when p_status = 'revisionRequested' then 'high' else 'normal' end
  );
  perform private.emit_engineering_event(
    delivery."projectId",
    'engineering.delivery.' || p_status,
    'engineeringDelivery',
    delivery.id,
    jsonb_build_object(
      'receiptId', receipt.id,
      'status', p_status,
      'source', p_source
    ),
    p_source,
    correlation_id
  );
  return receipt;
end;
$$;

create or replace function public.register_engineering_technical_report(
  p_project_id text,
  p_source_type text,
  p_source_id text,
  p_report_type text,
  p_title text,
  p_file_path text,
  p_original_file_name text,
  p_size_bytes bigint,
  p_sha256 text,
  p_summary jsonb default '{}'::jsonb,
  p_correlation_id text default null
)
returns public.engineering_technical_reports
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  report public.engineering_technical_reports;
  next_version integer;
  correlation_id text := coalesce(
    nullif(trim(coalesce(p_correlation_id, '')), ''),
    gen_random_uuid()::text
  );
begin
  if not private.can_access_engineering_project(p_project_id) then
    raise exception using errcode = '42501',
      message = 'Sem acesso a obra para registrar o relatorio.';
  end if;
  if p_file_path not like p_project_id || '/%' then
    raise exception using errcode = '22023',
      message = 'O arquivo precisa estar na pasta da obra.';
  end if;
  if lower(trim(p_sha256)) !~ '^[a-f0-9]{64}$' or p_size_bytes <= 0 then
    raise exception using errcode = '22023',
      message = 'Hash ou tamanho do relatorio invalido.';
  end if;

  select coalesce(max(item.version), 0) + 1
  into next_version
  from public.engineering_technical_reports item
  where item."projectId" = p_project_id
    and item."sourceType" = p_source_type
    and item."sourceId" is not distinct from nullif(p_source_id, '')
    and item."reportType" = p_report_type;

  insert into public.engineering_technical_reports (
    "projectId",
    "sourceType",
    "sourceId",
    "reportType",
    title,
    version,
    status,
    "filePath",
    "originalFileName",
    "sizeBytes",
    sha256,
    summary,
    "generatedByUserId",
    "correlationId"
  )
  values (
    p_project_id,
    p_source_type,
    nullif(p_source_id, ''),
    p_report_type,
    trim(p_title),
    next_version,
    'generated',
    p_file_path,
    p_original_file_name,
    p_size_bytes,
    lower(trim(p_sha256)),
    coalesce(p_summary, '{}'::jsonb),
    (select auth.uid())::text,
    correlation_id
  )
  returning * into report;

  perform private.emit_engineering_event(
    p_project_id,
    'engineering.report.generated',
    'engineeringTechnicalReport',
    report.id,
    jsonb_build_object(
      'reportType', report."reportType",
      'sourceType', report."sourceType",
      'sourceId', report."sourceId",
      'version', report.version
    ),
    'engineering',
    correlation_id
  );
  return report;
end;
$$;

create or replace function public.review_engineering_technical_report(
  p_report_id text,
  p_decision text,
  p_comment text default ''
)
returns public.engineering_technical_reports
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  report public.engineering_technical_reports;
begin
  if p_decision not in ('approved', 'revoked') then
    raise exception using errcode = '22023',
      message = 'Decisao de relatorio invalida.';
  end if;
  select *
  into report
  from public.engineering_technical_reports item
  where item.id = p_report_id
  for update;

  if report.id is null
    or not private.can_access_engineering_project(report."projectId")
  then
    raise exception using errcode = '42501', message = 'Relatorio indisponivel.';
  end if;

  update public.engineering_technical_reports
  set
    status = p_decision,
    "approvedByUserId" = case
      when p_decision = 'approved' then (select auth.uid())::text
      else "approvedByUserId"
    end,
    "approvedAt" = case
      when p_decision = 'approved' then clock_timestamp()
      else "approvedAt"
    end,
    "revokedAt" = case
      when p_decision = 'revoked' then clock_timestamp()
      else null
    end,
    summary = summary || jsonb_build_object('reviewComment', p_comment),
    "updatedAt" = clock_timestamp()
  where id = report.id
  returning * into report;

  perform private.emit_engineering_event(
    report."projectId",
    'engineering.report.' || p_decision,
    'engineeringTechnicalReport',
    report.id,
    jsonb_build_object(
      'reportType', report."reportType",
      'version', report.version
    ),
    'engineering',
    report."correlationId"
  );
  perform private.notify_engineering_project_people(
    report."projectId",
    case
      when p_decision = 'approved' then 'Relatorio tecnico aprovado'
      else 'Relatorio tecnico revogado'
    end,
    report.title,
    jsonb_build_object(
      'eventType', 'engineering.report.' || p_decision,
      'reportId', report.id,
      'reportType', report."reportType",
      'actionRoute', 'engineering_reports'
    ),
    case when p_decision = 'revoked' then 'high' else 'normal' end,
    private.current_user_employee_id()
  );
  return report;
end;
$$;

create or replace function public.publish_engineering_technical_report(
  p_report_id text,
  p_notes text default ''
)
returns public.engineering_client_report_publications
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  report public.engineering_technical_reports;
  publication public.engineering_client_report_publications;
begin
  select *
  into report
  from public.engineering_technical_reports item
  where item.id = p_report_id
  for update;

  if report.id is null
    or report.status not in ('approved', 'published')
    or not private.can_access_engineering_project(report."projectId")
  then
    raise exception using errcode = '42501',
      message = 'Somente relatorios aprovados podem ser publicados.';
  end if;

  select *
  into publication
  from public.engineering_client_report_publications item
  where item."reportId" = report.id
    and item."revokedAt" is null
  limit 1;
  if publication.id is not null then
    return publication;
  end if;

  insert into public.engineering_client_report_publications (
    "projectId",
    "reportId",
    title,
    notes,
    "publishedByUserId",
    "correlationId"
  )
  values (
    report."projectId",
    report.id,
    report.title,
    coalesce(p_notes, ''),
    (select auth.uid())::text,
    report."correlationId"
  )
  returning * into publication;

  update public.engineering_technical_reports
  set status = 'published', "updatedAt" = clock_timestamp()
  where id = report.id;

  perform private.emit_engineering_event(
    report."projectId",
    'engineering.report.published',
    'engineeringTechnicalReport',
    report.id,
    jsonb_build_object('publicationId', publication.id),
    'engineering',
    report."correlationId"
  );
  return publication;
end;
$$;

create or replace function public.unpublish_engineering_technical_report(
  p_publication_id text,
  p_reason text default ''
)
returns boolean
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  publication public.engineering_client_report_publications;
begin
  select *
  into publication
  from public.engineering_client_report_publications item
  where item.id = p_publication_id
    and item."revokedAt" is null
  for update;

  if publication.id is null
    or not private.can_access_engineering_project(publication."projectId")
  then
    raise exception using errcode = '42501',
      message = 'Publicacao indisponivel.';
  end if;

  update public.engineering_client_report_publications
  set
    "revokedAt" = clock_timestamp(),
    "revokedByUserId" = (select auth.uid())::text,
    notes = concat_ws(
      E'\n',
      nullif(notes, ''),
      nullif(trim(coalesce(p_reason, '')), '')
    )
  where id = publication.id;
  update public.engineering_technical_reports
  set status = 'approved', "updatedAt" = clock_timestamp()
  where id = publication."reportId";

  perform private.emit_engineering_event(
    publication."projectId",
    'engineering.report.unpublished',
    'engineeringTechnicalReport',
    publication."reportId",
    jsonb_build_object('publicationId', publication.id),
    'engineering',
    publication."correlationId"
  );
  return true;
end;
$$;

create or replace function public.apply_engineering_offline_operation(
  p_operation_id text,
  p_operation_type text,
  p_payload jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  existing public.engineering_offline_operations;
  receipt public.engineering_delivery_receipts;
  result jsonb;
  entity_id text;
  project_id text;
begin
  if nullif(trim(p_operation_id), '') is null then
    raise exception using errcode = '22023',
      message = 'Identificador da operacao offline obrigatorio.';
  end if;

  select *
  into existing
  from public.engineering_offline_operations operation
  where operation."operationId" = p_operation_id;
  if existing."operationId" is not null then
    return existing.result;
  end if;

  if p_operation_type in (
    'acknowledgeDelivery',
    'requestDeliveryRevision'
  ) then
    entity_id := nullif(p_payload ->> 'deliveryId', '');
    select *
    into receipt
    from public.acknowledge_engineering_delivery(
      entity_id,
      case
        when p_operation_type = 'acknowledgeDelivery'
          then 'acknowledged'
        else 'revisionRequested'
      end,
      coalesce(p_payload ->> 'notes', ''),
      p_operation_id,
      'offlineSync'
    );
    project_id := receipt."projectId";
    result := jsonb_build_object(
      'receiptId', receipt.id,
      'deliveryId', receipt."deliveryId",
      'status', receipt.status,
      'appliedAt', receipt."createdAt"
    );
  elsif p_operation_type = 'markNotificationRead' then
    entity_id := nullif(p_payload ->> 'notificationId', '');
    if entity_id is null then
      raise exception using errcode = '22023',
        message = 'Notificacao obrigatoria.';
    end if;
    perform public.set_mobile_push_notification_state(entity_id, 'read');
    result := jsonb_build_object(
      'notificationId', entity_id,
      'status', 'read'
    );
  else
    raise exception using errcode = '22023',
      message = 'Operacao offline nao suportada.';
  end if;

  insert into public.engineering_offline_operations (
    "operationId",
    "userId",
    "employeeId",
    "operationType",
    "entityId",
    "projectId",
    payload,
    result
  )
  values (
    p_operation_id,
    (select auth.uid())::text,
    private.current_user_employee_id(),
    p_operation_type,
    entity_id,
    project_id,
    coalesce(p_payload, '{}'::jsonb),
    result
  );
  return result;
end;
$$;

revoke all on function public.create_engineering_delivery(
  text,
  text,
  text,
  text,
  text,
  text,
  timestamptz,
  text[],
  text[],
  text
) from public, anon;
revoke all on function public.send_engineering_delivery(text, text)
  from public, anon;
revoke all on function public.acknowledge_engineering_delivery(
  text,
  text,
  text,
  text,
  text
) from public, anon;
revoke all on function public.register_engineering_technical_report(
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  bigint,
  text,
  jsonb,
  text
) from public, anon;
revoke all on function public.review_engineering_technical_report(
  text,
  text,
  text
) from public, anon;
revoke all on function public.publish_engineering_technical_report(text, text)
  from public, anon;
revoke all on function public.unpublish_engineering_technical_report(text, text)
  from public, anon;
revoke all on function public.apply_engineering_offline_operation(
  text,
  text,
  jsonb
) from public, anon;

grant execute on function public.create_engineering_delivery(
  text,
  text,
  text,
  text,
  text,
  text,
  timestamptz,
  text[],
  text[],
  text
) to authenticated;
grant execute on function public.send_engineering_delivery(text, text)
  to authenticated;
grant execute on function public.acknowledge_engineering_delivery(
  text,
  text,
  text,
  text,
  text
) to authenticated;
grant execute on function public.register_engineering_technical_report(
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  bigint,
  text,
  jsonb,
  text
) to authenticated;
grant execute on function public.review_engineering_technical_report(
  text,
  text,
  text
) to authenticated;
grant execute on function public.publish_engineering_technical_report(text, text)
  to authenticated;
grant execute on function public.unpublish_engineering_technical_report(
  text,
  text
) to authenticated;
grant execute on function public.apply_engineering_offline_operation(
  text,
  text,
  jsonb
) to authenticated;

alter table public.engineering_technical_reports enable row level security;
alter table public.engineering_technical_reports force row level security;
alter table public.engineering_client_report_publications enable row level security;
alter table public.engineering_client_report_publications force row level security;
alter table public.engineering_delivery_reports enable row level security;
alter table public.engineering_delivery_reports force row level security;
alter table public.engineering_delivery_receipts enable row level security;
alter table public.engineering_delivery_receipts force row level security;
alter table public.engineering_ecosystem_events enable row level security;
alter table public.engineering_ecosystem_events force row level security;
alter table public.engineering_offline_operations enable row level security;
alter table public.engineering_offline_operations force row level security;

drop policy if exists engineering_reports_select
  on public.engineering_technical_reports;
create policy engineering_reports_select
on public.engineering_technical_reports
for select to authenticated
using (private.can_access_engineering_project("projectId"));

drop policy if exists engineering_report_publications_select
  on public.engineering_client_report_publications;
create policy engineering_report_publications_select
on public.engineering_client_report_publications
for select to authenticated
using (
  private.can_access_engineering_project("projectId")
  or private.client_can_access_project("projectId")
);

drop policy if exists engineering_delivery_reports_select
  on public.engineering_delivery_reports;
create policy engineering_delivery_reports_select
on public.engineering_delivery_reports
for select to authenticated
using (private.can_access_engineering_project("projectId"));

drop policy if exists engineering_delivery_receipts_select
  on public.engineering_delivery_receipts;
create policy engineering_delivery_receipts_select
on public.engineering_delivery_receipts
for select to authenticated
using (
  private.can_access_engineering_project("projectId")
  or "recipientUserId" = (select auth.uid())::text
  or "recipientEmployeeId" = private.current_user_employee_id()
  or private.client_can_access_project("projectId")
);

drop policy if exists engineering_events_select
  on public.engineering_ecosystem_events;
create policy engineering_events_select
on public.engineering_ecosystem_events
for select to authenticated
using (
  "projectId" is not null
  and (
    private.can_access_engineering_project("projectId")
    or private.client_can_access_project("projectId")
  )
);

drop policy if exists engineering_offline_operations_select_own
  on public.engineering_offline_operations;
create policy engineering_offline_operations_select_own
on public.engineering_offline_operations
for select to authenticated
using ("userId" = (select auth.uid())::text);

revoke all on public.engineering_technical_reports from public, anon;
revoke all on public.engineering_client_report_publications from public, anon;
revoke all on public.engineering_delivery_reports from public, anon;
revoke all on public.engineering_delivery_receipts from public, anon;
revoke all on public.engineering_ecosystem_events from public, anon;
revoke all on public.engineering_offline_operations from public, anon;
grant select on public.engineering_technical_reports to authenticated;
grant select on public.engineering_client_report_publications to authenticated;
grant select on public.engineering_delivery_reports to authenticated;
grant select on public.engineering_delivery_receipts to authenticated;
grant select on public.engineering_ecosystem_events to authenticated;
grant select on public.engineering_offline_operations to authenticated;
grant all on public.engineering_technical_reports to service_role;
grant all on public.engineering_client_report_publications to service_role;
grant all on public.engineering_delivery_reports to service_role;
grant all on public.engineering_delivery_receipts to service_role;
grant all on public.engineering_ecosystem_events to service_role;
grant all on public.engineering_offline_operations to service_role;

create or replace view public.client_portal_engineering_reports
with (security_barrier = true)
as
select
  publication.id as "publicationId",
  publication."projectId",
  report.id as "reportId",
  report."sourceType",
  report."sourceId",
  report."reportType",
  publication.title,
  report.version,
  report.bucket,
  report."filePath",
  report."originalFileName",
  report."mimeType",
  report."sizeBytes",
  report.sha256,
  report.summary,
  publication.notes,
  publication."publishedAt"
from public.engineering_client_report_publications publication
join public.engineering_technical_reports report
  on report.id = publication."reportId"
where publication."revokedAt" is null
  and report.status = 'published'
  and report."revokedAt" is null
  and private.client_can_access_project(publication."projectId");

revoke all on public.client_portal_engineering_reports from public, anon;
grant select on public.client_portal_engineering_reports to authenticated;

create or replace view public.mobile_engineering_deliveries
with (security_barrier = true)
as
select
  delivery.id,
  delivery."projectId",
  project.name as "projectName",
  delivery.title,
  delivery.recipient,
  delivery."recipientUserId",
  delivery."recipientEmployeeId",
  delivery.status,
  delivery."dueAt",
  delivery."sentAt",
  delivery."acknowledgedAt",
  delivery."lastReceiptAt",
  delivery.version,
  delivery."correlationId",
  coalesce(document_count.total, 0)::integer as "documentCount",
  coalesce(report_count.total, 0)::integer as "reportCount",
  delivery."updatedAt"
from public.engineering_deliveries delivery
join public.projects project on project.id = delivery."projectId"
left join lateral (
  select count(*) as total
  from public.engineering_delivery_documents item
  where item."deliveryId" = delivery.id
) document_count on true
left join lateral (
  select count(*) as total
  from public.engineering_delivery_reports item
  where item."deliveryId" = delivery.id
) report_count on true
where delivery.status <> 'cancelled'
  and (
    delivery."recipientUserId" = (select auth.uid())::text
    or delivery."recipientEmployeeId" = private.current_user_employee_id()
    or private.can_access_engineering_project(delivery."projectId")
  );

revoke all on public.mobile_engineering_deliveries from public, anon;
grant select on public.mobile_engineering_deliveries to authenticated;

create or replace view public.mobile_engineering_documents
with (security_barrier = true)
as
select
  'engineering-document:' || publication.id as id,
  publication."projectId",
  project.name as "projectName",
  publication.title,
  concat_ws(
    E'\n',
    'Documento tecnico aprovado',
    'Disciplina: ' || document.discipline,
    'Tipo: ' || document."documentType",
    'Revisao: ' || revision."revisionCode",
    'Arquivo: ' || revision."originalFileName",
    case
      when nullif(publication.notes, '') is not null
        then 'Observacoes: ' || publication.notes
      else null
    end
  ) as content,
  publication."publishedAt" as "updatedAt"
from public.engineering_client_document_publications publication
join public.engineering_documents document
  on document.id = publication."documentId"
join public.engineering_document_revisions revision
  on revision.id = publication."documentRevisionId"
join public.projects project
  on project.id = publication."projectId"
where publication."revokedAt" is null
  and revision.status = 'approved'
  and private.can_access_engineering_project(publication."projectId")

union all

select
  'engineering-report:' || publication.id as id,
  publication."projectId",
  project.name as "projectName",
  publication.title,
  concat_ws(
    E'\n',
    'Relatorio tecnico aprovado',
    'Tipo: ' || report."reportType",
    'Versao: ' || report.version::text,
    'Arquivo: ' || report."originalFileName",
    case
      when report.summary is not null
        and report.summary <> '{}'::jsonb
        then 'Resumo: ' || report.summary::text
      else null
    end,
    case
      when nullif(publication.notes, '') is not null
        then 'Observacoes: ' || publication.notes
      else null
    end
  ) as content,
  publication."publishedAt" as "updatedAt"
from public.engineering_client_report_publications publication
join public.engineering_technical_reports report
  on report.id = publication."reportId"
join public.projects project
  on project.id = publication."projectId"
where publication."revokedAt" is null
  and report.status = 'published'
  and report."revokedAt" is null
  and private.can_access_engineering_project(publication."projectId");

revoke all on public.mobile_engineering_documents from public, anon;
grant select on public.mobile_engineering_documents to authenticated;

insert into storage.buckets (id, name, public)
values ('engineering-reports', 'engineering-reports', false)
on conflict (id) do update set public = false;

drop policy if exists engineering_reports_storage_select on storage.objects;
create policy engineering_reports_storage_select
on storage.objects
for select to authenticated
using (
  bucket_id = 'engineering-reports'
  and (
    private.can_access_engineering_project((storage.foldername(name))[1])
    or exists (
      select 1
      from public.engineering_client_report_publications publication
      join public.engineering_technical_reports report
        on report.id = publication."reportId"
      where publication."revokedAt" is null
        and report.status = 'published'
        and report."revokedAt" is null
        and report."filePath" = storage.objects.name
        and private.client_can_access_project(publication."projectId")
    )
  )
);

drop policy if exists engineering_reports_storage_insert on storage.objects;
create policy engineering_reports_storage_insert
on storage.objects
for insert to authenticated
with check (
  bucket_id = 'engineering-reports'
  and private.can_access_engineering_project((storage.foldername(name))[1])
);

drop policy if exists engineering_reports_storage_immutable_update
  on storage.objects;
create policy engineering_reports_storage_immutable_update
on storage.objects
as restrictive
for update to authenticated
using (bucket_id <> 'engineering-reports')
with check (bucket_id <> 'engineering-reports');

drop policy if exists engineering_reports_storage_delete on storage.objects;
create policy engineering_reports_storage_delete
on storage.objects
for delete to authenticated
using (
  bucket_id = 'engineering-reports'
  and private.can_access_engineering_project((storage.foldername(name))[1])
  and not exists (
    select 1
    from public.engineering_technical_reports report
    where report."filePath" = storage.objects.name
  )
);

create or replace function private.notify_engineering_document_publication()
returns trigger
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  event_type text;
  event_title text;
  event_body text;
  correlation_id text := gen_random_uuid()::text;
begin
  if tg_op = 'INSERT' then
    event_type := 'engineering.document.published';
    event_title := 'Novo documento tecnico';
    event_body := new.title;
  elsif old."revokedAt" is null and new."revokedAt" is not null then
    event_type := 'engineering.document.unpublished';
    event_title := 'Documento tecnico retirado';
    event_body := new.title;
  else
    return new;
  end if;

  perform private.notify_engineering_project_people(
    new."projectId",
    event_title,
    event_body,
    jsonb_build_object(
      'eventType', event_type,
      'publicationId', new.id,
      'documentId', new."documentId",
      'documentRevisionId', new."documentRevisionId",
      'actionRoute', 'engineering_documents',
      'correlationId', correlation_id
    ),
    'normal'
  );
  perform private.emit_engineering_event(
    new."projectId",
    event_type,
    'engineeringDocumentPublication',
    new.id,
    jsonb_build_object(
      'documentId', new."documentId",
      'documentRevisionId', new."documentRevisionId"
    ),
    'database',
    correlation_id
  );
  return new;
end;
$$;

revoke all on function private.notify_engineering_document_publication()
  from public, anon, authenticated;

drop trigger if exists notify_engineering_document_publication_row
  on public.engineering_client_document_publications;
create trigger notify_engineering_document_publication_row
after insert or update of "revokedAt"
on public.engineering_client_document_publications
for each row execute function private.notify_engineering_document_publication();

create or replace function private.notify_engineering_revision_status()
returns trigger
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  document_title text;
  event_type text;
  correlation_id text := gen_random_uuid()::text;
begin
  if old.status is not distinct from new.status
    or new.status not in ('approved', 'revisionRequested')
  then
    return new;
  end if;

  select document.title
  into document_title
  from public.engineering_documents document
  where document.id = new."documentId";

  event_type := case
    when new.status = 'approved'
      then 'engineering.revision.approved'
    else 'engineering.revision.requested'
  end;
  perform private.notify_engineering_project_people(
    new."projectId",
    case
      when new.status = 'approved' then 'Revisao tecnica aprovada'
      else 'Revisao tecnica solicitada'
    end,
    coalesce(document_title, new."originalFileName")
      || ' - ' || new."revisionCode",
    jsonb_build_object(
      'eventType', event_type,
      'documentId', new."documentId",
      'documentRevisionId', new.id,
      'actionRoute', 'engineering_documents',
      'correlationId', correlation_id
    ),
    case when new.status = 'revisionRequested' then 'high' else 'normal' end
  );
  perform private.emit_engineering_event(
    new."projectId",
    event_type,
    'engineeringDocumentRevision',
    new.id,
    jsonb_build_object(
      'documentId', new."documentId",
      'status', new.status
    ),
    'database',
    correlation_id
  );
  return new;
end;
$$;

revoke all on function private.notify_engineering_revision_status()
  from public, anon, authenticated;

drop trigger if exists notify_engineering_revision_status_row
  on public.engineering_document_revisions;
create trigger notify_engineering_revision_status_row
after update of status on public.engineering_document_revisions
for each row execute function private.notify_engineering_revision_status();

create or replace function private.notify_engineering_analysis_status()
returns trigger
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  event_type text;
  correlation_id text := gen_random_uuid()::text;
begin
  if old.status is not distinct from new.status
    or new.status not in ('completed', 'failed')
  then
    return new;
  end if;

  event_type := case
    when new.status = 'completed'
      then 'engineering.analysis.completed'
    else 'engineering.analysis.failed'
  end;
  perform private.notify_engineering_project_people(
    new."projectId",
    case
      when new.status = 'completed' then 'Analise de planta concluida'
      else 'Falha na analise de planta'
    end,
    case
      when new.status = 'completed'
        then 'Os apontamentos estao prontos para revisao humana.'
      else coalesce(nullif(new."errorMessage", ''), 'Revise o processamento.')
    end,
    jsonb_build_object(
      'eventType', event_type,
      'analysisJobId', new.id,
      'documentRevisionId', new."documentRevisionId",
      'actionRoute', 'engineering_analysis',
      'correlationId', correlation_id
    ),
    case when new.status = 'failed' then 'high' else 'normal' end
  );
  perform private.emit_engineering_event(
    new."projectId",
    event_type,
    'engineeringAnalysisJob',
    new.id,
    jsonb_build_object(
      'documentRevisionId', new."documentRevisionId",
      'status', new.status
    ),
    'worker',
    correlation_id
  );
  return new;
end;
$$;

revoke all on function private.notify_engineering_analysis_status()
  from public, anon, authenticated;

drop trigger if exists notify_engineering_analysis_status_row
  on public.engineering_analysis_jobs;
create trigger notify_engineering_analysis_status_row
after update of status on public.engineering_analysis_jobs
for each row execute function private.notify_engineering_analysis_status();

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'engineering_technical_reports',
    'engineering_client_report_publications',
    'engineering_delivery_reports',
    'engineering_delivery_receipts'
  ]
  loop
    execute format(
      'drop trigger if exists audit_%I_row on public.%I',
      table_name,
      table_name
    );
    execute format(
      'create trigger audit_%I_row after insert or update or delete
       on public.%I for each row
       execute function private.record_engineering_audit()',
      table_name,
      table_name
    );
  end loop;
end
$$;

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'engineering_deliveries',
    'engineering_delivery_receipts',
    'engineering_technical_reports',
    'engineering_client_report_publications',
    'engineering_ecosystem_events'
  ]
  loop
    begin
      execute format(
        'alter publication supabase_realtime add table public.%I',
        table_name
      );
    exception
      when duplicate_object then null;
    end;
  end loop;
end
$$;
