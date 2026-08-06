-- Granith Engenharia: assisted "tracing paper" review between analysis and
-- quantity takeoff. Automatic results remain immutable; reviewed overlays are
-- versioned and become the only accepted source for new takeoffs.

create table if not exists public.engineering_overlay_versions (
  id text primary key default gen_random_uuid()::text,
  "projectId" text not null references public.projects(id) on delete cascade,
  "documentRevisionId" text not null
    references public.engineering_document_revisions(id) on delete cascade,
  "analysisJobId" text not null
    references public.engineering_analysis_jobs(id) on delete restrict,
  "versionNumber" integer not null,
  title text not null default 'Camada tecnica',
  status text not null default 'draft',
  "scaleDenominator" numeric(14,4) not null,
  opacity numeric(5,4) not null default 0.82,
  "sourceResultSha256" text not null,
  "pageMetrics" jsonb not null default '[]'::jsonb,
  "createdByUserId" text not null default '',
  "approvedByUserId" text,
  "approvedAt" timestamptz,
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now(),
  unique ("documentRevisionId", "versionNumber"),
  constraint engineering_overlay_version_number_check
    check ("versionNumber" > 0),
  constraint engineering_overlay_version_status_check
    check (status in ('draft', 'underReview', 'approved', 'superseded')),
  constraint engineering_overlay_version_scale_check
    check ("scaleDenominator" > 0),
  constraint engineering_overlay_version_opacity_check
    check (opacity between 0 and 1),
  constraint engineering_overlay_version_sha256_check
    check ("sourceResultSha256" ~ '^[0-9a-f]{64}$'),
  constraint engineering_overlay_version_pages_check
    check (jsonb_typeof("pageMetrics") = 'array')
);

create table if not exists public.engineering_overlay_elements (
  id text primary key default gen_random_uuid()::text,
  "versionId" text not null
    references public.engineering_overlay_versions(id) on delete cascade,
  "projectId" text not null references public.projects(id) on delete cascade,
  "documentRevisionId" text not null
    references public.engineering_document_revisions(id) on delete cascade,
  "pageNumber" integer not null,
  kind text not null,
  "classificationCode" text not null default 'unclassified',
  label text not null default 'Elemento a classificar',
  source text not null default 'automatic',
  "reviewStatus" text not null default 'pending',
  geometry jsonb not null default '{}'::jsonb,
  properties jsonb not null default '{}'::jsonb,
  confidence numeric(5,4),
  "measuredQuantity" numeric(18,6) not null default 0,
  unit text not null default 'un',
  "sourceKey" text,
  "createdByUserId" text not null default '',
  "updatedByUserId" text not null default '',
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now(),
  constraint engineering_overlay_element_page_check check ("pageNumber" > 0),
  constraint engineering_overlay_element_kind_check check (
    kind in ('path', 'symbol', 'room', 'area', 'equipment', 'issue', 'note')
  ),
  constraint engineering_overlay_element_source_check check (
    source in ('automatic', 'manual', 'corrected')
  ),
  constraint engineering_overlay_element_review_check check (
    "reviewStatus" in ('pending', 'accepted', 'rejected')
  ),
  constraint engineering_overlay_element_confidence_check check (
    confidence is null or confidence between 0 and 1
  ),
  constraint engineering_overlay_element_quantity_check
    check ("measuredQuantity" >= 0),
  constraint engineering_overlay_element_geometry_check
    check (jsonb_typeof(geometry) = 'object'),
  constraint engineering_overlay_element_properties_check
    check (jsonb_typeof(properties) = 'object')
);

create unique index if not exists idx_engineering_overlay_element_source
  on public.engineering_overlay_elements ("versionId", "sourceKey")
  where "sourceKey" is not null;

create index if not exists idx_engineering_overlay_versions_revision
  on public.engineering_overlay_versions (
    "documentRevisionId",
    "versionNumber" desc
  );

create index if not exists idx_engineering_overlay_versions_analysis
  on public.engineering_overlay_versions ("analysisJobId", status);

create index if not exists idx_engineering_overlay_elements_page
  on public.engineering_overlay_elements (
    "versionId",
    "pageNumber",
    "reviewStatus"
  );

create table if not exists public.engineering_overlay_operations (
  id text primary key default gen_random_uuid()::text,
  "versionId" text not null
    references public.engineering_overlay_versions(id) on delete cascade,
  "elementId" text
    references public.engineering_overlay_elements(id) on delete set null,
  "projectId" text not null references public.projects(id) on delete cascade,
  operation text not null,
  "beforeValue" jsonb,
  "afterValue" jsonb,
  reason text not null default '',
  "actorUserId" text not null default '',
  "createdAt" timestamptz not null default now(),
  constraint engineering_overlay_operation_check check (
    operation in (
      'versionCreated',
      'elementCreated',
      'elementUpdated',
      'elementReviewed',
      'bulkReviewed',
      'versionApproved'
    )
  )
);

create index if not exists idx_engineering_overlay_operations_version
  on public.engineering_overlay_operations ("versionId", "createdAt" desc);

create or replace function private.assert_engineering_overlay_editable()
returns trigger
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  overlay_status text;
begin
  if tg_op = 'DELETE' then
    select status into overlay_status
    from public.engineering_overlay_versions
    where id = old."versionId";
  else
    select status into overlay_status
    from public.engineering_overlay_versions
    where id = new."versionId";
  end if;

  if overlay_status is distinct from 'draft' then
    raise exception using
      errcode = '55000',
      message = 'Only draft assisted-review layers can be edited.';
  end if;
  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

revoke all on function private.assert_engineering_overlay_editable()
  from public, anon, authenticated;

drop trigger if exists assert_engineering_overlay_element_editable
  on public.engineering_overlay_elements;
create trigger assert_engineering_overlay_element_editable
before insert or update or delete on public.engineering_overlay_elements
for each row execute function private.assert_engineering_overlay_editable();

create or replace function public.create_engineering_overlay_version(
  analysis_job_id text,
  force_new boolean default false
)
returns public.engineering_overlay_versions
language plpgsql
security definer
set search_path = public, private, extensions, pg_temp
as $$
declare
  analysis public.engineering_analysis_jobs;
  analysis_scale public.engineering_analysis_scales;
  existing public.engineering_overlay_versions;
  parent public.engineering_overlay_versions;
  created public.engineering_overlay_versions;
  next_version integer;
  page_metrics jsonb;
begin
  select * into analysis
  from public.engineering_analysis_jobs
  where id = analysis_job_id;

  if not found
     or not private.can_access_engineering_project(analysis."projectId") then
    raise exception using errcode = '42501', message = 'Analysis not available.';
  end if;
  if analysis.status not in ('requiresReview', 'completed')
     or analysis."resultSha256" is null then
    raise exception using
      errcode = '55000',
      message = 'A completed local analysis is required.';
  end if;

  if not force_new then
    select * into existing
    from public.engineering_overlay_versions
    where "analysisJobId" = analysis.id
      and status = 'draft'
    order by "versionNumber" desc
    limit 1;
    if found then
      return existing;
    end if;
  end if;

  select * into analysis_scale
  from public.engineering_analysis_scales
  where "analysisJobId" = analysis.id;
  if not found then
    raise exception using errcode = 'P0002', message = 'Analysis scale not found.';
  end if;

  select * into parent
  from public.engineering_overlay_versions
  where "documentRevisionId" = analysis."documentRevisionId"
    and status = 'approved'
  order by "versionNumber" desc
  limit 1;

  select coalesce(max("versionNumber"), 0) + 1 into next_version
  from public.engineering_overlay_versions
  where "documentRevisionId" = analysis."documentRevisionId";

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'pageNumber', page."pageNumber",
        'widthPoints', page."widthPoints",
        'heightPoints', page."heightPoints"
      )
      order by page."pageNumber"
    ),
    '[]'::jsonb
  ) into page_metrics
  from public.engineering_analysis_pages page
  where page."analysisJobId" = analysis.id;

  insert into public.engineering_overlay_versions (
    "projectId",
    "documentRevisionId",
    "analysisJobId",
    "versionNumber",
    title,
    status,
    "scaleDenominator",
    opacity,
    "sourceResultSha256",
    "pageMetrics",
    "createdByUserId"
  )
  values (
    analysis."projectId",
    analysis."documentRevisionId",
    analysis.id,
    next_version,
    'Camada tecnica v' || next_version,
    'draft',
    analysis_scale.denominator,
    coalesce(parent.opacity, 0.82),
    analysis."resultSha256",
    page_metrics,
    (select auth.uid())::text
  )
  returning * into created;

  if parent.id is not null and force_new then
    insert into public.engineering_overlay_elements (
      "versionId",
      "projectId",
      "documentRevisionId",
      "pageNumber",
      kind,
      "classificationCode",
      label,
      source,
      "reviewStatus",
      geometry,
      properties,
      confidence,
      "measuredQuantity",
      unit,
      "sourceKey",
      "createdByUserId",
      "updatedByUserId"
    )
    select
      created.id,
      element."projectId",
      element."documentRevisionId",
      element."pageNumber",
      element.kind,
      element."classificationCode",
      element.label,
      'corrected',
      element."reviewStatus",
      element.geometry,
      element.properties,
      element.confidence,
      element."measuredQuantity",
      element.unit,
      element."sourceKey",
      (select auth.uid())::text,
      (select auth.uid())::text
    from public.engineering_overlay_elements element
    where element."versionId" = parent.id
      and element."reviewStatus" = 'accepted';
  else
    insert into public.engineering_overlay_elements (
      "versionId",
      "projectId",
      "documentRevisionId",
      "pageNumber",
      kind,
      "classificationCode",
      label,
      source,
      "reviewStatus",
      geometry,
      properties,
      confidence,
      "measuredQuantity",
      unit,
      "sourceKey",
      "createdByUserId",
      "updatedByUserId"
    )
    select
      created.id,
      page."projectId",
      page."documentRevisionId",
      page."pageNumber",
      'path',
      'route.unclassified',
      'Trajeto linear a classificar',
      'automatic',
      'pending',
      jsonb_build_object(
        'points',
        jsonb_build_array(
          jsonb_build_object(
            'x', (line.value ->> 'x1')::numeric,
            'y', (line.value ->> 'y1')::numeric
          ),
          jsonb_build_object(
            'x', (line.value ->> 'x2')::numeric,
            'y', (line.value ->> 'y2')::numeric
          )
        )
      ),
      jsonb_build_object(
        'pageWidthPoints', page."widthPoints",
        'pageHeightPoints', page."heightPoints",
        'angleDegrees', line.value -> 'angleDegrees',
        'detector', 'OpenCV/HoughLinesP'
      ),
      0.50,
      round(
        sqrt(
          power(
            (
              (line.value ->> 'x2')::numeric
              - (line.value ->> 'x1')::numeric
            ) * page."widthPoints",
            2
          )
          + power(
            (
              (line.value ->> 'y2')::numeric
              - (line.value ->> 'y1')::numeric
            ) * page."heightPoints",
            2
          )
        ) * analysis_scale.denominator * 25.4 / 72 / 1000,
        6
      ),
      'm',
      'line:' || page."pageNumber" || ':' || line.ordinality,
      (select auth.uid())::text,
      (select auth.uid())::text
    from public.engineering_analysis_pages page
    cross join lateral jsonb_array_elements(page."lineSegments")
      with ordinality as line(value, ordinality)
    where page."analysisJobId" = analysis.id;

    insert into public.engineering_overlay_elements (
      "versionId",
      "projectId",
      "documentRevisionId",
      "pageNumber",
      kind,
      "classificationCode",
      label,
      source,
      "reviewStatus",
      geometry,
      properties,
      confidence,
      "measuredQuantity",
      unit,
      "sourceKey",
      "createdByUserId",
      "updatedByUserId"
    )
    select
      created.id,
      page."projectId",
      page."documentRevisionId",
      page."pageNumber",
      'symbol',
      'symbol.' || coalesce(nullif(symbol.value ->> 'kind', ''), 'complex'),
      'Simbolo ' || coalesce(nullif(symbol.value ->> 'kind', ''), 'complex'),
      'automatic',
      'pending',
      coalesce(symbol.value -> 'geometry', '{}'::jsonb),
      jsonb_build_object('detector', 'OpenCV/contours'),
      greatest(
        0,
        least(1, coalesce((symbol.value ->> 'confidence')::numeric, 0.35))
      ),
      1,
      'un',
      'symbol:' || page."pageNumber" || ':' || symbol.ordinality,
      (select auth.uid())::text,
      (select auth.uid())::text
    from public.engineering_analysis_pages page
    cross join lateral jsonb_array_elements(page.symbols)
      with ordinality as symbol(value, ordinality)
    where page."analysisJobId" = analysis.id;

    insert into public.engineering_overlay_elements (
      "versionId",
      "projectId",
      "documentRevisionId",
      "pageNumber",
      kind,
      "classificationCode",
      label,
      source,
      "reviewStatus",
      geometry,
      properties,
      confidence,
      "measuredQuantity",
      unit,
      "sourceKey",
      "createdByUserId",
      "updatedByUserId"
    )
    select
      created.id,
      finding."projectId",
      finding."documentRevisionId",
      finding."pageNumber",
      'issue',
      coalesce(finding."ruleCode", 'finding.unclassified'),
      finding.title,
      'automatic',
      case
        when finding.status = 'rejected' then 'rejected'
        when finding.status in ('accepted', 'resolved') then 'accepted'
        else 'pending'
      end,
      finding.geometry,
      jsonb_build_object(
        'description', finding.description,
        'suggestedAction', finding."suggestedAction",
        'severity', finding.severity
      ),
      finding.confidence,
      0,
      'un',
      'finding:' || finding.id,
      (select auth.uid())::text,
      (select auth.uid())::text
    from public.engineering_findings finding
    where finding."analysisJobId" = analysis.id;
  end if;

  insert into public.engineering_overlay_operations (
    "versionId",
    "projectId",
    operation,
    "afterValue",
    "actorUserId"
  )
  values (
    created.id,
    created."projectId",
    'versionCreated',
    to_jsonb(created),
    (select auth.uid())::text
  );

  return created;
end;
$$;

create or replace function public.save_engineering_overlay_element(
  version_id text,
  element_id text,
  page_number integer,
  element_kind text,
  classification_code text,
  element_label text,
  element_geometry jsonb,
  element_properties jsonb,
  review_status text,
  measured_quantity numeric,
  element_unit text,
  change_reason text
)
returns public.engineering_overlay_elements
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  overlay public.engineering_overlay_versions;
  previous public.engineering_overlay_elements;
  saved public.engineering_overlay_elements;
begin
  select * into overlay
  from public.engineering_overlay_versions
  where id = version_id
  for update;
  if not found
     or not private.can_access_engineering_project(overlay."projectId") then
    raise exception using errcode = '42501', message = 'Overlay not available.';
  end if;
  if overlay.status <> 'draft' then
    raise exception using errcode = '55000', message = 'Overlay is read-only.';
  end if;
  if page_number <= 0
     or element_kind not in (
       'path', 'symbol', 'room', 'area', 'equipment', 'issue', 'note'
     )
     or review_status not in ('pending', 'accepted', 'rejected')
     or jsonb_typeof(element_geometry) <> 'object'
     or jsonb_typeof(element_properties) <> 'object'
     or coalesce(measured_quantity, 0) < 0 then
    raise exception using errcode = '22023', message = 'Invalid overlay element.';
  end if;

  if nullif(trim(coalesce(element_id, '')), '') is null then
    insert into public.engineering_overlay_elements (
      "versionId",
      "projectId",
      "documentRevisionId",
      "pageNumber",
      kind,
      "classificationCode",
      label,
      source,
      "reviewStatus",
      geometry,
      properties,
      "measuredQuantity",
      unit,
      "createdByUserId",
      "updatedByUserId"
    )
    values (
      overlay.id,
      overlay."projectId",
      overlay."documentRevisionId",
      page_number,
      element_kind,
      coalesce(nullif(trim(classification_code), ''), 'unclassified'),
      coalesce(nullif(trim(element_label), ''), 'Elemento manual'),
      'manual',
      review_status,
      element_geometry,
      element_properties,
      coalesce(measured_quantity, 0),
      coalesce(nullif(trim(element_unit), ''), 'un'),
      (select auth.uid())::text,
      (select auth.uid())::text
    )
    returning * into saved;

    insert into public.engineering_overlay_operations (
      "versionId",
      "elementId",
      "projectId",
      operation,
      "afterValue",
      reason,
      "actorUserId"
    )
    values (
      overlay.id,
      saved.id,
      overlay."projectId",
      'elementCreated',
      to_jsonb(saved),
      coalesce(change_reason, ''),
      (select auth.uid())::text
    );
  else
    select * into previous
    from public.engineering_overlay_elements
    where id = element_id
      and "versionId" = overlay.id
    for update;
    if not found then
      raise exception using errcode = 'P0002', message = 'Element not found.';
    end if;

    update public.engineering_overlay_elements
    set "pageNumber" = page_number,
        kind = element_kind,
        "classificationCode" = coalesce(
          nullif(trim(classification_code), ''),
          'unclassified'
        ),
        label = coalesce(nullif(trim(element_label), ''), 'Elemento manual'),
        source = case
          when previous.source = 'manual' then 'manual'
          else 'corrected'
        end,
        "reviewStatus" = review_status,
        geometry = element_geometry,
        properties = element_properties,
        "measuredQuantity" = coalesce(measured_quantity, 0),
        unit = coalesce(nullif(trim(element_unit), ''), 'un'),
        "updatedByUserId" = (select auth.uid())::text,
        "updatedAt" = now()
    where id = previous.id
    returning * into saved;

    insert into public.engineering_overlay_operations (
      "versionId",
      "elementId",
      "projectId",
      operation,
      "beforeValue",
      "afterValue",
      reason,
      "actorUserId"
    )
    values (
      overlay.id,
      saved.id,
      overlay."projectId",
      'elementUpdated',
      to_jsonb(previous),
      to_jsonb(saved),
      coalesce(change_reason, ''),
      (select auth.uid())::text
    );
  end if;

  update public.engineering_overlay_versions
  set "updatedAt" = now()
  where id = overlay.id;
  return saved;
end;
$$;

create or replace function public.review_engineering_overlay_element(
  element_id text,
  review_status text,
  review_reason text default ''
)
returns public.engineering_overlay_elements
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  previous public.engineering_overlay_elements;
  overlay public.engineering_overlay_versions;
  saved public.engineering_overlay_elements;
begin
  if review_status not in ('accepted', 'rejected') then
    raise exception using errcode = '22023', message = 'Invalid review status.';
  end if;
  select * into previous
  from public.engineering_overlay_elements
  where id = element_id
  for update;
  if not found then
    raise exception using errcode = 'P0002', message = 'Element not found.';
  end if;
  select * into overlay
  from public.engineering_overlay_versions
  where id = previous."versionId"
  for update;
  if overlay.status <> 'draft'
     or not private.can_access_engineering_project(overlay."projectId") then
    raise exception using errcode = '42501', message = 'Overlay is not editable.';
  end if;

  update public.engineering_overlay_elements
  set "reviewStatus" = review_status,
      "updatedByUserId" = (select auth.uid())::text,
      "updatedAt" = now()
  where id = previous.id
  returning * into saved;

  insert into public.engineering_overlay_operations (
    "versionId",
    "elementId",
    "projectId",
    operation,
    "beforeValue",
    "afterValue",
    reason,
    "actorUserId"
  )
  values (
    overlay.id,
    saved.id,
    overlay."projectId",
    'elementReviewed',
    to_jsonb(previous),
    to_jsonb(saved),
    coalesce(review_reason, ''),
    (select auth.uid())::text
  );
  return saved;
end;
$$;

create or replace function public.bulk_review_engineering_overlay_elements(
  version_id text,
  review_status text
)
returns integer
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  overlay public.engineering_overlay_versions;
  changed integer;
begin
  if review_status not in ('accepted', 'rejected') then
    raise exception using errcode = '22023', message = 'Invalid review status.';
  end if;
  select * into overlay
  from public.engineering_overlay_versions
  where id = version_id
  for update;
  if not found
     or overlay.status <> 'draft'
     or not private.can_access_engineering_project(overlay."projectId") then
    raise exception using errcode = '42501', message = 'Overlay is not editable.';
  end if;

  update public.engineering_overlay_elements
  set "reviewStatus" = review_status,
      "updatedByUserId" = (select auth.uid())::text,
      "updatedAt" = now()
  where "versionId" = overlay.id
    and "reviewStatus" = 'pending';
  get diagnostics changed = row_count;

  insert into public.engineering_overlay_operations (
    "versionId",
    "projectId",
    operation,
    "afterValue",
    reason,
    "actorUserId"
  )
  values (
    overlay.id,
    overlay."projectId",
    'bulkReviewed',
    jsonb_build_object('status', review_status, 'count', changed),
    'Revisao em lote confirmada pelo usuario.',
    (select auth.uid())::text
  );
  return changed;
end;
$$;

create or replace function public.approve_engineering_overlay_version(
  version_id text
)
returns public.engineering_overlay_versions
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  overlay public.engineering_overlay_versions;
  approved public.engineering_overlay_versions;
  pending_count integer;
  accepted_count integer;
begin
  select * into overlay
  from public.engineering_overlay_versions
  where id = version_id
  for update;
  if not found
     or not private.can_access_engineering_project(overlay."projectId") then
    raise exception using errcode = '42501', message = 'Overlay not available.';
  end if;
  if overlay.status <> 'draft' then
    raise exception using errcode = '55000', message = 'Overlay is not a draft.';
  end if;

  select
    count(*) filter (where "reviewStatus" = 'pending'),
    count(*) filter (where "reviewStatus" = 'accepted')
  into pending_count, accepted_count
  from public.engineering_overlay_elements
  where "versionId" = overlay.id;

  if pending_count > 0 then
    raise exception using
      errcode = '55000',
      message = 'Review every pending element before approval.';
  end if;
  if accepted_count <= 0 then
    raise exception using
      errcode = '55000',
      message = 'At least one accepted element is required.';
  end if;

  update public.engineering_overlay_versions
  set status = 'superseded',
      "updatedAt" = now()
  where "documentRevisionId" = overlay."documentRevisionId"
    and status = 'approved';

  update public.engineering_overlay_versions
  set status = 'approved',
      "approvedByUserId" = (select auth.uid())::text,
      "approvedAt" = now(),
      "updatedAt" = now()
  where id = overlay.id
  returning * into approved;

  insert into public.engineering_overlay_operations (
    "versionId",
    "projectId",
    operation,
    "afterValue",
    "actorUserId"
  )
  values (
    approved.id,
    approved."projectId",
    'versionApproved',
    to_jsonb(approved),
    (select auth.uid())::text
  );
  return approved;
end;
$$;

alter table public.engineering_quantity_takeoffs
  add column if not exists "overlayVersionId" text
    references public.engineering_overlay_versions(id) on delete restrict,
  add column if not exists "overlaySnapshotSha256" text;

alter table public.engineering_quantity_takeoffs
  drop constraint if exists engineering_quantity_takeoffs_overlay_sha256;
alter table public.engineering_quantity_takeoffs
  add constraint engineering_quantity_takeoffs_overlay_sha256 check (
    "overlaySnapshotSha256" is null
    or "overlaySnapshotSha256" ~ '^[0-9a-f]{64}$'
  );

create or replace function public.create_engineering_overlay_quantity_takeoff(
  analysis_job_id text,
  profile_id text,
  overlay_version_id text,
  overlay_snapshot_sha256 text
)
returns public.engineering_quantity_takeoffs
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  analysis public.engineering_analysis_jobs;
  profile public.engineering_quantity_profiles;
  overlay public.engineering_overlay_versions;
  created_takeoff public.engineering_quantity_takeoffs;
begin
  select * into analysis
  from public.engineering_analysis_jobs
  where id = analysis_job_id
  for update;
  if not found
     or not private.can_access_engineering_project(analysis."projectId") then
    raise exception using errcode = '42501', message = 'Analysis not available.';
  end if;
  if analysis.status <> 'completed' then
    raise exception using
      errcode = '55000',
      message = 'Complete the finding review before quantity takeoff.';
  end if;

  select * into overlay
  from public.engineering_overlay_versions
  where id = overlay_version_id;
  if not found
     or overlay.status <> 'approved'
     or overlay."analysisJobId" <> analysis.id
     or overlay."documentRevisionId" <> analysis."documentRevisionId" then
    raise exception using
      errcode = '55000',
      message = 'An approved assisted-review layer is required.';
  end if;
  if overlay_snapshot_sha256 !~ '^[0-9a-f]{64}$' then
    raise exception using errcode = '22023', message = 'Invalid overlay SHA-256.';
  end if;

  select * into profile
  from public.engineering_quantity_profiles
  where id = profile_id
    and "isActive" = true;
  if not found then
    raise exception using errcode = 'P0002', message = 'Profile not available.';
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
    "overlayVersionId",
    "overlaySnapshotSha256",
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
    overlay_snapshot_sha256,
    overlay.id,
    overlay_snapshot_sha256,
    (select auth.uid())::text
  )
  on conflict ("analysisJobId", "profileId") do update
  set status = case
        when public.engineering_quantity_takeoffs.status in ('failed', 'cancelled')
          then 'processing'
        else public.engineering_quantity_takeoffs.status
      end,
      progress = case
        when public.engineering_quantity_takeoffs.status in ('failed', 'cancelled')
          then 0.01
        else public.engineering_quantity_takeoffs.progress
      end,
      "analysisResultSha256" = case
        when public.engineering_quantity_takeoffs.status in ('failed', 'cancelled')
          then excluded."analysisResultSha256"
        else public.engineering_quantity_takeoffs."analysisResultSha256"
      end,
      "overlayVersionId" = case
        when public.engineering_quantity_takeoffs.status in ('failed', 'cancelled')
          then excluded."overlayVersionId"
        else public.engineering_quantity_takeoffs."overlayVersionId"
      end,
      "overlaySnapshotSha256" = case
        when public.engineering_quantity_takeoffs.status in ('failed', 'cancelled')
          then excluded."overlaySnapshotSha256"
        else public.engineering_quantity_takeoffs."overlaySnapshotSha256"
      end,
      "errorCode" = case
        when public.engineering_quantity_takeoffs.status in ('failed', 'cancelled')
          then null
        else public.engineering_quantity_takeoffs."errorCode"
      end,
      "errorMessage" = case
        when public.engineering_quantity_takeoffs.status in ('failed', 'cancelled')
          then null
        else public.engineering_quantity_takeoffs."errorMessage"
      end,
      "updatedAt" = now()
  returning * into created_takeoff;

  if created_takeoff."overlayVersionId" is distinct from overlay.id then
    raise exception using
      errcode = '55000',
      message = 'A takeoff already exists for another overlay version.';
  end if;
  return created_takeoff;
end;
$$;

alter table public.engineering_overlay_versions enable row level security;
alter table public.engineering_overlay_versions force row level security;
alter table public.engineering_overlay_elements enable row level security;
alter table public.engineering_overlay_elements force row level security;
alter table public.engineering_overlay_operations enable row level security;
alter table public.engineering_overlay_operations force row level security;

create policy engineering_overlay_versions_select
on public.engineering_overlay_versions
for select to authenticated
using (private.can_access_engineering_project("projectId"));

create policy engineering_overlay_elements_select
on public.engineering_overlay_elements
for select to authenticated
using (private.can_access_engineering_project("projectId"));

create policy engineering_overlay_operations_select
on public.engineering_overlay_operations
for select to authenticated
using (private.can_access_engineering_project("projectId"));

revoke all on public.engineering_overlay_versions from public, anon;
revoke all on public.engineering_overlay_elements from public, anon;
revoke all on public.engineering_overlay_operations from public, anon;
grant select on public.engineering_overlay_versions to authenticated;
grant select on public.engineering_overlay_elements to authenticated;
grant select on public.engineering_overlay_operations to authenticated;
grant all on public.engineering_overlay_versions to service_role;
grant all on public.engineering_overlay_elements to service_role;
grant all on public.engineering_overlay_operations to service_role;

revoke all on function public.create_engineering_overlay_version(text, boolean)
  from public, anon;
revoke all on function public.save_engineering_overlay_element(
  text, text, integer, text, text, text, jsonb, jsonb, text, numeric, text, text
) from public, anon;
revoke all on function public.review_engineering_overlay_element(
  text, text, text
) from public, anon;
revoke all on function public.bulk_review_engineering_overlay_elements(
  text, text
) from public, anon;
revoke all on function public.approve_engineering_overlay_version(text)
  from public, anon;
revoke all on function public.create_engineering_overlay_quantity_takeoff(
  text, text, text, text
) from public, anon;
revoke execute on function public.create_engineering_quantity_takeoff(
  text, text
) from authenticated;

grant execute on function public.create_engineering_overlay_version(
  text, boolean
) to authenticated;
grant execute on function public.save_engineering_overlay_element(
  text, text, integer, text, text, text, jsonb, jsonb, text, numeric, text, text
) to authenticated;
grant execute on function public.review_engineering_overlay_element(
  text, text, text
) to authenticated;
grant execute on function public.bulk_review_engineering_overlay_elements(
  text, text
) to authenticated;
grant execute on function public.approve_engineering_overlay_version(text)
  to authenticated;
grant execute on function public.create_engineering_overlay_quantity_takeoff(
  text, text, text, text
) to authenticated;

do $$
begin
  begin
    alter publication supabase_realtime
      add table public.engineering_overlay_versions;
  exception when duplicate_object then null;
  end;
  begin
    alter publication supabase_realtime
      add table public.engineering_overlay_elements;
  exception when duplicate_object then null;
  end;
end
$$;
