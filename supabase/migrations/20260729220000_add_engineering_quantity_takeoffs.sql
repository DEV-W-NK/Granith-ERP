-- Granith Engenharia P3: auditable quantity takeoffs connected to ERP catalog,
-- budgets and material requisitions.

create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;

create table if not exists public.engineering_quantity_profiles (
  id text primary key default gen_random_uuid()::text,
  code text not null,
  version text not null,
  title text not null,
  description text not null default '',
  disciplines text[] not null default '{Geral}',
  rules jsonb not null default '{}'::jsonb,
  "contentSha256" text not null default '',
  "isActive" boolean not null default true,
  "createdByUserId" text not null default '',
  "createdAt" timestamptz not null default now(),
  unique (code, version),
  constraint engineering_quantity_profiles_code_not_blank
    check (length(trim(code)) > 0),
  constraint engineering_quantity_profiles_version_not_blank
    check (length(trim(version)) > 0),
  constraint engineering_quantity_profiles_rules_object
    check (jsonb_typeof(rules) = 'object'),
  constraint engineering_quantity_profiles_sha256
    check ("contentSha256" ~ '^[0-9a-f]{64}$')
);

create or replace function private.prepare_engineering_quantity_profile()
returns trigger
language plpgsql
security definer
set search_path = public, private, extensions, pg_temp
as $$
declare
  canonical_payload text;
begin
  canonical_payload := jsonb_build_object(
    'code', new.code,
    'version', new.version,
    'title', new.title,
    'disciplines', to_jsonb(new.disciplines),
    'rules', new.rules
  )::text;

  if tg_op = 'INSERT' then
    new."createdByUserId" := coalesce(
      nullif(new."createdByUserId", ''),
      (select auth.uid())::text,
      'migration'
    );
    new."contentSha256" := encode(digest(canonical_payload, 'sha256'), 'hex');
    return new;
  end if;

  if (
    new.code,
    new.version,
    new.title,
    new.description,
    new.disciplines,
    new.rules,
    new."contentSha256",
    new."createdByUserId",
    new."createdAt"
  ) is distinct from (
    old.code,
    old.version,
    old.title,
    old.description,
    old.disciplines,
    old.rules,
    old."contentSha256",
    old."createdByUserId",
    old."createdAt"
  ) then
    raise exception using
      errcode = '55000',
      message = 'Quantity profiles are immutable. Create a new version.';
  end if;

  return new;
end;
$$;

revoke all on function private.prepare_engineering_quantity_profile()
  from public, anon, authenticated;

drop trigger if exists prepare_engineering_quantity_profile_row
  on public.engineering_quantity_profiles;
create trigger prepare_engineering_quantity_profile_row
before insert or update on public.engineering_quantity_profiles
for each row execute function private.prepare_engineering_quantity_profile();

insert into public.engineering_quantity_profiles (
  id,
  code,
  version,
  title,
  description,
  disciplines,
  rules,
  "createdByUserId"
)
values (
  'granith-electrical-base-v1',
  'GRANITH_ELECTRICAL_QTO',
  '1.0.0',
  'Quantitativos eletricos - base assistiva',
  'Pre-classifica trajetos, simbolos, areas e volumes. Cada item exige revisao tecnica e associacao ao catalogo.',
  array['Eletrica', 'Telecom', 'SPDA'],
  '{
    "path": {
      "code": "route.unclassified",
      "label": "Trajeto linear a classificar",
      "minimumMeters": 0.15,
      "wastePercent": 10,
      "curveAllowance": 0.2,
      "connectionAllowance": 0.15
    },
    "symbol": {
      "code": "symbol.{kind}",
      "label": "Simbolo {kind} a classificar",
      "wastePercent": 5
    },
    "area": {
      "code": "area.unclassified",
      "label": "Area fechada a classificar",
      "minimumSquareMeters": 0.01,
      "wastePercent": 8
    },
    "volume": {
      "code": "volume.unclassified",
      "label": "Volume estimado a classificar",
      "thicknessMeters": 0,
      "wastePercent": 8
    }
  }'::jsonb,
  'migration'
)
on conflict (id) do nothing;

create table if not exists public.engineering_quantity_takeoffs (
  id text primary key default gen_random_uuid()::text,
  "projectId" text not null references public.projects(id) on delete cascade,
  "analysisJobId" text not null
    references public.engineering_analysis_jobs(id) on delete restrict,
  "documentRevisionId" text not null
    references public.engineering_document_revisions(id) on delete restrict,
  "profileId" text not null
    references public.engineering_quantity_profiles(id) on delete restrict,
  "profileVersion" text not null,
  "profileSha256" text not null,
  status text not null default 'processing',
  progress numeric(5,4) not null default 0,
  "workerRunId" text,
  "workerVersion" text,
  "analysisResultSha256" text not null,
  "resultSha256" text,
  "resultStoragePath" text,
  summary jsonb not null default '{}'::jsonb,
  "generatedBudgetId" text references public.budgets(id) on delete set null,
  "generatedRequisitionId" text
    references public.material_requisitions(id) on delete set null,
  "errorCode" text,
  "errorMessage" text,
  "createdByUserId" text not null default '',
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now(),
  "completedAt" timestamptz,
  unique ("analysisJobId", "profileId"),
  constraint engineering_quantity_takeoffs_status_check check (
    status in (
      'processing',
      'requiresReview',
      'approved',
      'rejected',
      'failed',
      'cancelled'
    )
  ),
  constraint engineering_quantity_takeoffs_progress_check
    check (progress between 0 and 1),
  constraint engineering_quantity_takeoffs_profile_sha256
    check ("profileSha256" ~ '^[0-9a-f]{64}$'),
  constraint engineering_quantity_takeoffs_analysis_sha256
    check ("analysisResultSha256" ~ '^[0-9a-f]{64}$'),
  constraint engineering_quantity_takeoffs_result_sha256
    check ("resultSha256" is null or "resultSha256" ~ '^[0-9a-f]{64}$'),
  constraint engineering_quantity_takeoffs_summary_object
    check (jsonb_typeof(summary) = 'object')
);

create table if not exists public.engineering_quantity_items (
  id text primary key default gen_random_uuid()::text,
  "projectId" text not null references public.projects(id) on delete cascade,
  "takeoffId" text not null
    references public.engineering_quantity_takeoffs(id) on delete cascade,
  "classificationCode" text not null,
  label text not null,
  "measurementType" text not null,
  unit text not null,
  "rawQuantity" numeric(18,6) not null,
  "adjustedQuantity" numeric(18,6) not null,
  formula text not null,
  inputs jsonb not null default '{}'::jsonb,
  "elementCount" integer not null default 0,
  "sourcePages" integer[] not null default '{}',
  status text not null default 'open',
  "catalogItemId" text references public.items(id) on delete set null,
  "catalogItemName" text,
  "inventoryItemId" text references public.inventory(id) on delete set null,
  "inventoryAvailable" numeric(18,6),
  "reviewedByUserId" text,
  "reviewedAt" timestamptz,
  "reviewComment" text not null default '',
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now(),
  unique ("takeoffId", "classificationCode"),
  constraint engineering_quantity_items_label_not_blank
    check (length(trim(label)) > 0),
  constraint engineering_quantity_items_measurement_check
    check ("measurementType" in ('count', 'length', 'area', 'volume')),
  constraint engineering_quantity_items_status_check
    check (status in ('open', 'accepted', 'rejected')),
  constraint engineering_quantity_items_nonnegative check (
    "rawQuantity" >= 0
    and "adjustedQuantity" >= 0
    and "elementCount" >= 0
  ),
  constraint engineering_quantity_items_inputs_object
    check (jsonb_typeof(inputs) = 'object')
);

create table if not exists public.engineering_quantity_elements (
  id text primary key default gen_random_uuid()::text,
  "projectId" text not null references public.projects(id) on delete cascade,
  "takeoffId" text not null
    references public.engineering_quantity_takeoffs(id) on delete cascade,
  "quantityItemId" text not null
    references public.engineering_quantity_items(id) on delete cascade,
  "elementKey" text not null,
  "pageNumber" integer not null,
  "sourceType" text not null,
  "sourceIndex" integer not null,
  "measurementType" text not null,
  unit text not null,
  "rawQuantity" numeric(18,6) not null,
  "adjustedQuantity" numeric(18,6) not null,
  formula text not null,
  inputs jsonb not null default '{}'::jsonb,
  geometry jsonb not null default '{}'::jsonb,
  evidence jsonb not null default '{}'::jsonb,
  "createdAt" timestamptz not null default now(),
  unique ("takeoffId", "elementKey"),
  constraint engineering_quantity_elements_page_check
    check ("pageNumber" > 0),
  constraint engineering_quantity_elements_source_index_check
    check ("sourceIndex" >= 0),
  constraint engineering_quantity_elements_measurement_check
    check ("measurementType" in ('count', 'length', 'area', 'volume')),
  constraint engineering_quantity_elements_nonnegative
    check ("rawQuantity" >= 0 and "adjustedQuantity" >= 0),
  constraint engineering_quantity_elements_json_objects check (
    jsonb_typeof(inputs) = 'object'
    and jsonb_typeof(geometry) = 'object'
    and jsonb_typeof(evidence) = 'object'
  )
);

create table if not exists public.engineering_quantity_item_costs (
  id text primary key default gen_random_uuid()::text,
  "projectId" text not null references public.projects(id) on delete cascade,
  "quantityItemId" text not null unique
    references public.engineering_quantity_items(id) on delete cascade,
  "unitPrice" numeric(18,4) not null,
  "createdByUserId" text not null default '',
  "createdAt" timestamptz not null default now(),
  "updatedByUserId" text not null default '',
  "updatedAt" timestamptz not null default now(),
  constraint engineering_quantity_item_cost_nonnegative
    check ("unitPrice" >= 0)
);

create index if not exists idx_engineering_quantity_takeoffs_project
  on public.engineering_quantity_takeoffs (
    "projectId",
    status,
    "updatedAt" desc
  );
create index if not exists idx_engineering_quantity_items_takeoff
  on public.engineering_quantity_items ("takeoffId", status);
create index if not exists idx_engineering_quantity_items_catalog
  on public.engineering_quantity_items ("catalogItemId")
  where "catalogItemId" is not null;
create index if not exists idx_engineering_quantity_elements_memory
  on public.engineering_quantity_elements (
    "takeoffId",
    "pageNumber",
    "quantityItemId"
  );

create or replace view public.engineering_catalog_items
with (security_invoker = true)
as
select
  catalog.id,
  catalog.name,
  catalog.description,
  catalog.unit,
  inventory.id as "inventoryItemId",
  coalesce(inventory.quantity, 0) as "inventoryAvailable",
  inventory."minQuantity",
  inventory."updatedAt" as "inventoryUpdatedAt"
from public.items catalog
left join public.inventory inventory
  on inventory.name_normalized = lower(trim(catalog.name));

revoke all on public.engineering_catalog_items from public, anon;
grant select on public.engineering_catalog_items to authenticated;

create or replace function private.calculate_engineering_quantity(
  measurement_type text,
  raw_quantity numeric,
  formula_inputs jsonb
)
returns numeric
language sql
immutable
set search_path = public, private, pg_temp
as $$
  select round(
    greatest(coalesce(raw_quantity, 0), 0)
      * (1 + greatest(coalesce((formula_inputs ->> 'wastePercent')::numeric, 0), 0) / 100)
      + case
          when measurement_type = 'length' then
            greatest(coalesce((formula_inputs ->> 'curveCount')::numeric, 0), 0)
              * greatest(coalesce((formula_inputs ->> 'curveAllowance')::numeric, 0), 0)
            + greatest(coalesce((formula_inputs ->> 'connectionCount')::numeric, 0), 0)
              * greatest(coalesce((formula_inputs ->> 'connectionAllowance')::numeric, 0), 0)
          else 0
        end,
    6
  );
$$;

revoke all on function private.calculate_engineering_quantity(
  text,
  numeric,
  jsonb
) from public, anon, authenticated;

create or replace function public.create_engineering_quantity_takeoff(
  analysis_job_id text,
  profile_id text
)
returns public.engineering_quantity_takeoffs
language plpgsql
security definer
set search_path = public, private, storage, pg_temp
as $$
declare
  analysis public.engineering_analysis_jobs;
  profile public.engineering_quantity_profiles;
  created_takeoff public.engineering_quantity_takeoffs;
begin
  select * into analysis
  from public.engineering_analysis_jobs
  where id = analysis_job_id
  for update;

  if not found then
    raise exception using errcode = 'P0002', message = 'Analysis not found.';
  end if;
  if not private.can_access_engineering_project(analysis."projectId") then
    raise exception using errcode = '42501', message = 'Project access denied.';
  end if;
  if analysis.status <> 'completed'
     or analysis."resultStoragePath" is null
     or analysis."resultSha256" is null then
    raise exception using
      errcode = '55000',
      message = 'Analysis must be completed and reviewed before takeoff.';
  end if;

  select * into profile
  from public.engineering_quantity_profiles
  where id = profile_id
    and "isActive" = true;
  if not found then
    raise exception using
      errcode = 'P0002',
      message = 'Active quantity profile not found.';
  end if;

  insert into public.engineering_quantity_takeoffs (
    "projectId",
    "analysisJobId",
    "documentRevisionId",
    "profileId",
    "profileVersion",
    "profileSha256",
    status,
    progress,
    "analysisResultSha256",
    "createdByUserId"
  )
  values (
    analysis."projectId",
    analysis.id,
    analysis."documentRevisionId",
    profile.id,
    profile.version,
    profile."contentSha256",
    'processing',
    0.01,
    analysis."resultSha256",
    (select auth.uid())::text
  )
  on conflict ("analysisJobId", "profileId") do update
  set status = case
        when public.engineering_quantity_takeoffs.status = 'failed'
          then 'processing'
        else public.engineering_quantity_takeoffs.status
      end,
      progress = case
        when public.engineering_quantity_takeoffs.status = 'failed'
          then 0.01
        else public.engineering_quantity_takeoffs.progress
      end,
      "errorCode" = case
        when public.engineering_quantity_takeoffs.status = 'failed'
          then null
        else public.engineering_quantity_takeoffs."errorCode"
      end,
      "errorMessage" = case
        when public.engineering_quantity_takeoffs.status = 'failed'
          then null
        else public.engineering_quantity_takeoffs."errorMessage"
      end,
      "updatedAt" = now()
  returning * into created_takeoff;

  return created_takeoff;
end;
$$;

create or replace function public.fail_engineering_quantity_takeoff(
  takeoff_id text,
  worker_run_id text,
  error_code text,
  error_message text
)
returns void
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  takeoff public.engineering_quantity_takeoffs;
begin
  select * into takeoff
  from public.engineering_quantity_takeoffs
  where id = takeoff_id
  for update;
  if not found then
    raise exception using errcode = 'P0002', message = 'Takeoff not found.';
  end if;
  if not private.can_access_engineering_project(takeoff."projectId") then
    raise exception using errcode = '42501', message = 'Project access denied.';
  end if;

  update public.engineering_quantity_takeoffs
  set status = 'failed',
      progress = 0,
      "workerRunId" = nullif(trim(worker_run_id), ''),
      "errorCode" = left(coalesce(error_code, 'unknown'), 120),
      "errorMessage" = left(coalesce(error_message, ''), 2000),
      "updatedAt" = now()
  where id = takeoff.id;
end;
$$;

create or replace function public.complete_engineering_quantity_takeoff(
  takeoff_id text,
  worker_run_id text,
  worker_version text,
  result_sha256 text,
  result_storage_path text,
  result_payload jsonb
)
returns public.engineering_quantity_takeoffs
language plpgsql
security definer
set search_path = public, private, storage, pg_temp
as $$
declare
  takeoff public.engineering_quantity_takeoffs;
  completed_takeoff public.engineering_quantity_takeoffs;
  item_count integer;
begin
  select * into takeoff
  from public.engineering_quantity_takeoffs
  where id = takeoff_id
  for update;
  if not found then
    raise exception using errcode = 'P0002', message = 'Takeoff not found.';
  end if;
  if not private.can_access_engineering_project(takeoff."projectId") then
    raise exception using errcode = '42501', message = 'Project access denied.';
  end if;
  if takeoff.status <> 'processing' then
    raise exception using
      errcode = '55000',
      message = 'Only processing takeoffs can be completed.';
  end if;
  if result_sha256 !~ '^[0-9a-f]{64}$' then
    raise exception using errcode = '22023', message = 'Invalid result SHA-256.';
  end if;
  if result_storage_path <> (
    takeoff."projectId" || '/' || takeoff.id || '/takeoff-' || result_sha256 || '.json'
  ) then
    raise exception using
      errcode = '22023',
      message = 'Unexpected takeoff result storage path.';
  end if;
  if not exists (
    select 1
    from storage.objects object
    where object.bucket_id = 'engineering-derived'
      and object.name = result_storage_path
  ) then
    raise exception using
      errcode = 'P0002',
      message = 'Takeoff result object not found in storage.';
  end if;
  if jsonb_typeof(result_payload) <> 'object'
     or jsonb_typeof(result_payload -> 'items') <> 'array'
     or jsonb_typeof(result_payload -> 'elements') <> 'array' then
    raise exception using
      errcode = '22023',
      message = 'Invalid takeoff result payload.';
  end if;
  if result_payload ->> 'takeoffId' <> takeoff.id
     or result_payload ->> 'analysisJobId' <> takeoff."analysisJobId"
     or result_payload ->> 'analysisResultSha256' <> takeoff."analysisResultSha256"
     or result_payload #>> '{profile,id}' <> takeoff."profileId"
     or result_payload #>> '{profile,version}' <> takeoff."profileVersion"
     or result_payload #>> '{profile,sha256}' <> takeoff."profileSha256" then
    raise exception using
      errcode = '22023',
      message = 'Takeoff result does not match its source contracts.';
  end if;

  delete from public.engineering_quantity_elements
  where "takeoffId" = takeoff.id;
  delete from public.engineering_quantity_items
  where "takeoffId" = takeoff.id;

  insert into public.engineering_quantity_items (
    "projectId",
    "takeoffId",
    "classificationCode",
    label,
    "measurementType",
    unit,
    "rawQuantity",
    "adjustedQuantity",
    formula,
    inputs,
    "elementCount",
    "sourcePages"
  )
  select
    takeoff."projectId",
    takeoff.id,
    nullif(trim(item ->> 'classificationCode'), ''),
    nullif(trim(item ->> 'label'), ''),
    item ->> 'measurementType',
    nullif(trim(item ->> 'unit'), ''),
    greatest(coalesce((item ->> 'rawQuantity')::numeric, 0), 0),
    greatest(coalesce((item ->> 'adjustedQuantity')::numeric, 0), 0),
    coalesce(item ->> 'formula', ''),
    coalesce(item -> 'inputs', '{}'::jsonb),
    greatest(coalesce((item ->> 'elementCount')::integer, 0), 0),
    coalesce(
      (
        select array_agg(page_value::integer order by page_value::integer)
        from jsonb_array_elements_text(
          coalesce(item -> 'sourcePages', '[]'::jsonb)
        ) as source_page(page_value)
      ),
      '{}'::integer[]
    )
  from jsonb_array_elements(result_payload -> 'items') item;

  insert into public.engineering_quantity_elements (
    "projectId",
    "takeoffId",
    "quantityItemId",
    "elementKey",
    "pageNumber",
    "sourceType",
    "sourceIndex",
    "measurementType",
    unit,
    "rawQuantity",
    "adjustedQuantity",
    formula,
    inputs,
    geometry,
    evidence
  )
  select
    takeoff."projectId",
    takeoff.id,
    quantity_item.id,
    nullif(trim(element ->> 'elementKey'), ''),
    greatest(coalesce((element ->> 'pageNumber')::integer, 1), 1),
    nullif(trim(element ->> 'sourceType'), ''),
    greatest(coalesce((element ->> 'sourceIndex')::integer, 0), 0),
    element ->> 'measurementType',
    nullif(trim(element ->> 'unit'), ''),
    greatest(coalesce((element ->> 'rawQuantity')::numeric, 0), 0),
    greatest(coalesce((element ->> 'adjustedQuantity')::numeric, 0), 0),
    coalesce(element ->> 'formula', ''),
    coalesce(element -> 'inputs', '{}'::jsonb),
    coalesce(element -> 'geometry', '{}'::jsonb),
    coalesce(element -> 'evidence', '{}'::jsonb)
  from jsonb_array_elements(result_payload -> 'elements') element
  join public.engineering_quantity_items quantity_item
    on quantity_item."takeoffId" = takeoff.id
   and quantity_item."classificationCode" = element ->> 'classificationCode';

  select count(*) into item_count
  from public.engineering_quantity_items
  where "takeoffId" = takeoff.id;

  update public.engineering_quantity_takeoffs
  set status = case when item_count > 0 then 'requiresReview' else 'approved' end,
      progress = 1,
      "workerRunId" = nullif(trim(worker_run_id), ''),
      "workerVersion" = nullif(trim(worker_version), ''),
      "resultSha256" = result_sha256,
      "resultStoragePath" = result_storage_path,
      summary = coalesce(result_payload -> 'summary', '{}'::jsonb),
      "errorCode" = null,
      "errorMessage" = null,
      "completedAt" = now(),
      "updatedAt" = now()
  where id = takeoff.id
  returning * into completed_takeoff;

  return completed_takeoff;
end;
$$;

create or replace function public.review_engineering_quantity_item(
  quantity_item_id text,
  decision text,
  catalog_item_id text,
  waste_percent numeric default null,
  curve_count integer default null,
  curve_allowance numeric default null,
  connection_count integer default null,
  connection_allowance numeric default null,
  review_comment text default '',
  unit_price numeric default null
)
returns public.engineering_quantity_items
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  quantity_item public.engineering_quantity_items;
  catalog public.items;
  inventory public.inventory;
  updated_item public.engineering_quantity_items;
  formula_inputs jsonb;
  remaining_open integer;
  accepted_count integer;
begin
  if decision not in ('accepted', 'rejected') then
    raise exception using errcode = '22023', message = 'Invalid review decision.';
  end if;

  select * into quantity_item
  from public.engineering_quantity_items
  where id = quantity_item_id
  for update;
  if not found then
    raise exception using errcode = 'P0002', message = 'Quantity item not found.';
  end if;
  if not private.can_access_engineering_project(quantity_item."projectId") then
    raise exception using errcode = '42501', message = 'Project access denied.';
  end if;

  if decision = 'accepted' then
    if catalog_item_id is null or trim(catalog_item_id) = '' then
      raise exception using
        errcode = '22023',
        message = 'Accepted quantities require an ERP catalog item.';
    end if;
    select * into catalog
    from public.items
    where id = catalog_item_id;
    if not found then
      raise exception using errcode = 'P0002', message = 'Catalog item not found.';
    end if;
    select * into inventory
    from public.inventory
    where name_normalized = lower(trim(catalog.name))
    limit 1;
  end if;

  formula_inputs := jsonb_build_object(
    'wastePercent',
      greatest(
        coalesce(waste_percent, (quantity_item.inputs ->> 'wastePercent')::numeric, 0),
        0
      ),
    'curveCount',
      greatest(
        coalesce(curve_count, (quantity_item.inputs ->> 'curveCount')::integer, 0),
        0
      ),
    'curveAllowance',
      greatest(
        coalesce(curve_allowance, (quantity_item.inputs ->> 'curveAllowance')::numeric, 0),
        0
      ),
    'connectionCount',
      greatest(
        coalesce(
          connection_count,
          (quantity_item.inputs ->> 'connectionCount')::integer,
          0
        ),
        0
      ),
    'connectionAllowance',
      greatest(
        coalesce(
          connection_allowance,
          (quantity_item.inputs ->> 'connectionAllowance')::numeric,
          0
        ),
        0
      )
  );

  update public.engineering_quantity_items
  set status = decision,
      label = case when decision = 'accepted' then catalog.name else label end,
      unit = case when decision = 'accepted' then catalog.unit else unit end,
      inputs = formula_inputs,
      "adjustedQuantity" = private.calculate_engineering_quantity(
        "measurementType",
        "rawQuantity",
        formula_inputs
      ),
      "catalogItemId" = case
        when decision = 'accepted' then catalog.id
        else null
      end,
      "catalogItemName" = case
        when decision = 'accepted' then catalog.name
        else null
      end,
      "inventoryItemId" = case
        when decision = 'accepted' then inventory.id
        else null
      end,
      "inventoryAvailable" = case
        when decision = 'accepted' then coalesce(inventory.quantity, 0)
        else null
      end,
      "reviewedByUserId" = (select auth.uid())::text,
      "reviewedAt" = now(),
      "reviewComment" = left(coalesce(review_comment, ''), 2000),
      "updatedAt" = now()
  where id = quantity_item.id
  returning * into updated_item;

  if unit_price is not null then
    if not private.can_read_engineering_financials() then
      raise exception using
        errcode = '42501',
        message = 'Only engineering administrators can define prices.';
    end if;
    if unit_price < 0 then
      raise exception using errcode = '22023', message = 'Invalid unit price.';
    end if;
    insert into public.engineering_quantity_item_costs (
      "projectId",
      "quantityItemId",
      "unitPrice",
      "createdByUserId",
      "updatedByUserId"
    )
    values (
      quantity_item."projectId",
      quantity_item.id,
      unit_price,
      (select auth.uid())::text,
      (select auth.uid())::text
    )
    on conflict ("quantityItemId") do update
    set "unitPrice" = excluded."unitPrice",
        "updatedByUserId" = excluded."updatedByUserId",
        "updatedAt" = now();
  end if;

  select count(*) into remaining_open
  from public.engineering_quantity_items
  where "takeoffId" = quantity_item."takeoffId"
    and status = 'open';
  select count(*) into accepted_count
  from public.engineering_quantity_items
  where "takeoffId" = quantity_item."takeoffId"
    and status = 'accepted';

  update public.engineering_quantity_takeoffs
  set status = case
        when remaining_open > 0 then 'requiresReview'
        when accepted_count > 0 then 'approved'
        else 'rejected'
      end,
      "updatedAt" = now()
  where id = quantity_item."takeoffId";

  return updated_item;
end;
$$;

create or replace function public.generate_requisition_from_engineering_takeoff(
  takeoff_id text,
  requisition_priority text default 'Media'
)
returns text
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  takeoff public.engineering_quantity_takeoffs;
  project public.projects;
  employee public.employees;
  requisition_items jsonb;
  requisition_id text;
begin
  select * into takeoff
  from public.engineering_quantity_takeoffs
  where id = takeoff_id
  for update;
  if not found then
    raise exception using errcode = 'P0002', message = 'Takeoff not found.';
  end if;
  if not private.can_access_engineering_project(takeoff."projectId") then
    raise exception using errcode = '42501', message = 'Project access denied.';
  end if;
  if takeoff.status <> 'approved' then
    raise exception using
      errcode = '55000',
      message = 'Takeoff must be fully reviewed and approved.';
  end if;
  if takeoff."generatedRequisitionId" is not null then
    return takeoff."generatedRequisitionId";
  end if;
  if requisition_priority not in ('Baixa', 'Media', 'Alta', 'Urgente') then
    raise exception using errcode = '22023', message = 'Invalid priority.';
  end if;

  select employees.* into employee
  from public.engineering_user_profiles profile
  join public.employees employees on employees.id = profile."employeeId"
  where profile."userId"::text = (select auth.uid())::text
    and profile."isActive" = true
    and employees.status = 'ativo'
  limit 1;
  if not found then
    raise exception using
      errcode = '55000',
      message = 'Engineering user must be linked to an active employee.';
  end if;

  select * into project
  from public.projects
  where id = takeoff."projectId";

  select jsonb_agg(
    jsonb_build_object(
      'itemName', quantity_item.label,
      'itemId', quantity_item."catalogItemId",
      'catalogItemId', quantity_item."catalogItemId",
      'quantity', round(quantity_item."adjustedQuantity", 3),
      'unit', quantity_item.unit,
      'observation',
        'Quantitativo ' || takeoff.id
        || ' - memoria em '
        || array_to_string(quantity_item."sourcePages", ', '),
      'engineeringTakeoffId', takeoff.id,
      'engineeringQuantityItemId', quantity_item.id
    )
    order by quantity_item.label
  ) into requisition_items
  from public.engineering_quantity_items quantity_item
  where quantity_item."takeoffId" = takeoff.id
    and quantity_item.status = 'accepted';

  if requisition_items is null or jsonb_array_length(requisition_items) = 0 then
    raise exception using
      errcode = '55000',
      message = 'Takeoff has no accepted catalog items.';
  end if;

  insert into public.material_requisitions (
    "projectId",
    "projectName",
    "requesterName",
    "requesterId",
    "requesterSector",
    "requestDate",
    status,
    items,
    priority
  )
  values (
    project.id,
    project.name,
    employee.name,
    employee.id,
    employee.sector,
    now(),
    'pending',
    requisition_items,
    requisition_priority
  )
  returning id into requisition_id;

  update public.engineering_quantity_takeoffs
  set "generatedRequisitionId" = requisition_id,
      "updatedAt" = now()
  where id = takeoff.id;

  return requisition_id;
end;
$$;

create or replace function public.generate_budget_from_engineering_takeoff(
  takeoff_id text,
  expiration_days integer default 30
)
returns text
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  takeoff public.engineering_quantity_takeoffs;
  project public.projects;
  budget_items jsonb;
  total_value numeric;
  budget_id text;
  missing_prices integer;
begin
  if not private.can_read_engineering_financials() then
    raise exception using
      errcode = '42501',
      message = 'Only engineering administrators can generate budgets.';
  end if;

  select * into takeoff
  from public.engineering_quantity_takeoffs
  where id = takeoff_id
  for update;
  if not found then
    raise exception using errcode = 'P0002', message = 'Takeoff not found.';
  end if;
  if not private.can_access_engineering_project(takeoff."projectId") then
    raise exception using errcode = '42501', message = 'Project access denied.';
  end if;
  if takeoff.status <> 'approved' then
    raise exception using
      errcode = '55000',
      message = 'Takeoff must be fully reviewed and approved.';
  end if;
  if takeoff."generatedBudgetId" is not null then
    return takeoff."generatedBudgetId";
  end if;
  if expiration_days < 1 or expiration_days > 365 then
    raise exception using
      errcode = '22023',
      message = 'Expiration must be between 1 and 365 days.';
  end if;

  select count(*) into missing_prices
  from public.engineering_quantity_items quantity_item
  left join public.engineering_quantity_item_costs cost
    on cost."quantityItemId" = quantity_item.id
  where quantity_item."takeoffId" = takeoff.id
    and quantity_item.status = 'accepted'
    and (cost.id is null or cost."unitPrice" <= 0);
  if missing_prices > 0 then
    raise exception using
      errcode = '55000',
      message = 'All accepted items require a positive unit price.';
  end if;

  select * into project
  from public.projects
  where id = takeoff."projectId";

  select
    jsonb_agg(
      jsonb_build_object(
        'description', quantity_item.label,
        'quantity', ceil(quantity_item."adjustedQuantity")::integer,
        'unitPrice', cost."unitPrice",
        'total', ceil(quantity_item."adjustedQuantity") * cost."unitPrice",
        'unit', quantity_item.unit,
        'technicalQuantity', quantity_item."adjustedQuantity",
        'catalogItemId', quantity_item."catalogItemId",
        'engineeringTakeoffId', takeoff.id,
        'engineeringQuantityItemId', quantity_item.id
      )
      order by quantity_item.label
    ),
    coalesce(
      sum(ceil(quantity_item."adjustedQuantity") * cost."unitPrice"),
      0
    )
  into budget_items, total_value
  from public.engineering_quantity_items quantity_item
  join public.engineering_quantity_item_costs cost
    on cost."quantityItemId" = quantity_item.id
  where quantity_item."takeoffId" = takeoff.id
    and quantity_item.status = 'accepted';

  if budget_items is null or jsonb_array_length(budget_items) = 0 then
    raise exception using
      errcode = '55000',
      message = 'Takeoff has no accepted priced items.';
  end if;

  insert into public.budgets (
    "clientName",
    "projectName",
    "totalValue",
    "creationDate",
    "expirationDate",
    status,
    description,
    items,
    "projectId"
  )
  values (
    project.client,
    project.name,
    total_value,
    floor(extract(epoch from now()) * 1000)::bigint,
    floor(
      extract(epoch from (now() + make_interval(days => expiration_days)))
      * 1000
    )::bigint,
    0,
    'Orcamento gerado pelo quantitativo tecnico ' || takeoff.id || '.',
    budget_items,
    project.id
  )
  returning id into budget_id;

  update public.engineering_quantity_takeoffs
  set "generatedBudgetId" = budget_id,
      "updatedAt" = now()
  where id = takeoff.id;

  return budget_id;
end;
$$;

revoke all on function public.create_engineering_quantity_takeoff(text, text)
  from public, anon;
revoke all on function public.fail_engineering_quantity_takeoff(
  text,
  text,
  text,
  text
) from public, anon;
revoke all on function public.complete_engineering_quantity_takeoff(
  text,
  text,
  text,
  text,
  text,
  jsonb
) from public, anon;
revoke all on function public.review_engineering_quantity_item(
  text,
  text,
  text,
  numeric,
  integer,
  numeric,
  integer,
  numeric,
  text,
  numeric
) from public, anon;
revoke all on function public.generate_requisition_from_engineering_takeoff(
  text,
  text
) from public, anon;
revoke all on function public.generate_budget_from_engineering_takeoff(
  text,
  integer
) from public, anon;

grant execute on function public.create_engineering_quantity_takeoff(text, text)
  to authenticated;
grant execute on function public.fail_engineering_quantity_takeoff(
  text,
  text,
  text,
  text
) to authenticated;
grant execute on function public.complete_engineering_quantity_takeoff(
  text,
  text,
  text,
  text,
  text,
  jsonb
) to authenticated;
grant execute on function public.review_engineering_quantity_item(
  text,
  text,
  text,
  numeric,
  integer,
  numeric,
  integer,
  numeric,
  text,
  numeric
) to authenticated;
grant execute on function public.generate_requisition_from_engineering_takeoff(
  text,
  text
) to authenticated;
grant execute on function public.generate_budget_from_engineering_takeoff(
  text,
  integer
) to authenticated;

alter table public.engineering_quantity_profiles enable row level security;
alter table public.engineering_quantity_profiles force row level security;
alter table public.engineering_quantity_takeoffs enable row level security;
alter table public.engineering_quantity_takeoffs force row level security;
alter table public.engineering_quantity_items enable row level security;
alter table public.engineering_quantity_items force row level security;
alter table public.engineering_quantity_elements enable row level security;
alter table public.engineering_quantity_elements force row level security;
alter table public.engineering_quantity_item_costs enable row level security;
alter table public.engineering_quantity_item_costs force row level security;

create policy engineering_quantity_profiles_select
on public.engineering_quantity_profiles
for select to authenticated
using (private.can_access_engineering());
create policy engineering_quantity_profiles_manage
on public.engineering_quantity_profiles
for all to authenticated
using (private.can_manage_engineering_profiles())
with check (private.can_manage_engineering_profiles());

create policy engineering_quantity_takeoffs_select
on public.engineering_quantity_takeoffs
for select to authenticated
using (private.can_access_engineering_project("projectId"));
create policy engineering_quantity_items_select
on public.engineering_quantity_items
for select to authenticated
using (private.can_access_engineering_project("projectId"));
create policy engineering_quantity_elements_select
on public.engineering_quantity_elements
for select to authenticated
using (private.can_access_engineering_project("projectId"));
create policy engineering_quantity_item_costs_select
on public.engineering_quantity_item_costs
for select to authenticated
using (
  private.can_access_engineering_project("projectId")
  and private.can_read_engineering_financials()
);

revoke all on public.engineering_quantity_profiles from public, anon;
revoke all on public.engineering_quantity_takeoffs from public, anon;
revoke all on public.engineering_quantity_items from public, anon;
revoke all on public.engineering_quantity_elements from public, anon;
revoke all on public.engineering_quantity_item_costs from public, anon;
grant select on public.engineering_quantity_profiles to authenticated;
grant insert, update on public.engineering_quantity_profiles to authenticated;
grant select on public.engineering_quantity_takeoffs to authenticated;
grant select on public.engineering_quantity_items to authenticated;
grant select on public.engineering_quantity_elements to authenticated;
grant select on public.engineering_quantity_item_costs to authenticated;
grant all on public.engineering_quantity_profiles to service_role;
grant all on public.engineering_quantity_takeoffs to service_role;
grant all on public.engineering_quantity_items to service_role;
grant all on public.engineering_quantity_elements to service_role;
grant all on public.engineering_quantity_item_costs to service_role;

drop policy if exists engineering_quantity_result_immutable_delete
  on storage.objects;
create policy engineering_quantity_result_immutable_delete
on storage.objects
as restrictive
for delete to authenticated
using (
  bucket_id <> 'engineering-derived'
  or not exists (
    select 1
    from public.engineering_quantity_takeoffs takeoff
    where takeoff."resultStoragePath" = storage.objects.name
  )
);

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'engineering_quantity_profiles',
    'engineering_quantity_takeoffs',
    'engineering_quantity_items',
    'engineering_quantity_elements',
    'engineering_quantity_item_costs'
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
begin
  alter publication supabase_realtime
    add table public.engineering_quantity_takeoffs;
exception when duplicate_object then null;
end
$$;

do $$
begin
  alter publication supabase_realtime
    add table public.engineering_quantity_items;
exception when duplicate_object then null;
end
$$;
