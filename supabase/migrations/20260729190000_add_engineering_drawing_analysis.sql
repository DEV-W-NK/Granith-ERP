-- Granith Engenharia P2: local drawing analysis with mandatory human review.

create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;

create table if not exists public.engineering_rule_packs (
  id text primary key default gen_random_uuid()::text,
  code text not null unique,
  version text not null,
  title text not null,
  description text not null default '',
  authority text not null default 'Granith',
  "references" text[] not null default '{}',
  disciplines text[] not null default '{Geral}',
  rules jsonb not null default '[]'::jsonb,
  "contentSha256" text not null default '',
  "isActive" boolean not null default true,
  "createdByUserId" text not null default '',
  "createdAt" timestamptz not null default now(),
  unique (code, version),
  constraint engineering_rule_pack_code_not_blank
    check (length(trim(code)) > 0),
  constraint engineering_rule_pack_version_not_blank
    check (length(trim(version)) > 0),
  constraint engineering_rule_pack_rules_array
    check (jsonb_typeof(rules) = 'array'),
  constraint engineering_rule_pack_sha256
    check ("contentSha256" ~ '^[0-9a-f]{64}$')
);

create or replace function private.prepare_engineering_rule_pack()
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
    'authority', new.authority,
    'references', to_jsonb(new."references"),
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
    new.authority,
    new."references",
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
    old.authority,
    old."references",
    old.disciplines,
    old.rules,
    old."contentSha256",
    old."createdByUserId",
    old."createdAt"
  ) then
    raise exception using
      errcode = '55000',
      message = 'Rule packs are immutable. Create a new version.';
  end if;

  return new;
end;
$$;

revoke all on function private.prepare_engineering_rule_pack()
  from public, anon, authenticated;

drop trigger if exists prepare_engineering_rule_pack_row
  on public.engineering_rule_packs;
create trigger prepare_engineering_rule_pack_row
before insert or update on public.engineering_rule_packs
for each row execute function private.prepare_engineering_rule_pack();

insert into public.engineering_rule_packs (
  id,
  code,
  version,
  title,
  description,
  authority,
  "references",
  disciplines,
  rules,
  "createdByUserId"
)
values (
  'granith-abnt-iso-base-v1',
  'GRANITH_ABNT_ISO_BASE',
  '1.0.0',
  'Representacao tecnica - base assistiva',
  'Regras auxiliares. Nao substituem validacao profissional ou acesso as normas licenciadas.',
  'Granith',
  array['ABNT NBR 6492', 'ABNT NBR 10068', 'ISO 128'],
  array['Geral', 'Arquitetura', 'Eletrica', 'Hidraulica', 'Mecanica'],
  '[
    {
      "code": "DOC-SCALE-001",
      "kind": "declared_scale",
      "category": "document_control",
      "severity": "high",
      "title": "Escala da prancha",
      "suggestedAction": "Confirmar carimbo, formato da folha e escala de impressao."
    },
    {
      "code": "DOC-REV-001",
      "kind": "required_text",
      "category": "document_control",
      "severity": "medium",
      "title": "Identificacao de revisao nao localizada",
      "terms": ["REVISAO"],
      "suggestedAction": "Conferir a identificacao e o historico de revisoes no carimbo."
    },
    {
      "code": "DOC-RESP-001",
      "kind": "required_text",
      "category": "document_control",
      "severity": "medium",
      "title": "Responsabilidade tecnica nao localizada",
      "terms": ["RESPONSAVEL"],
      "suggestedAction": "Conferir responsavel tecnico, registro e assinatura aplicaveis."
    },
    {
      "code": "GEO-CONT-001",
      "kind": "line_continuity",
      "category": "geometry",
      "severity": "medium",
      "title": "Possivel trajeto interrompido",
      "endpointTolerance": 0.004,
      "minimumNormalizedLength": 0.05,
      "maxFindingsPerPage": 6,
      "suggestedAction": "Inspecionar o ponto final e validar a continuidade do sistema."
    },
    {
      "code": "SYM-LEG-001",
      "kind": "symbol_legend",
      "category": "symbols",
      "severity": "low",
      "title": "Legenda nao localizada",
      "minimumSymbols": 12,
      "legendTerms": ["LEGENDA", "SIMBOLOGIA"],
      "suggestedAction": "Validar se todos os simbolos utilizados estao documentados."
    },
    {
      "code": "OCR-QUAL-001",
      "kind": "ocr_quality",
      "category": "ocr",
      "severity": "info",
      "title": "OCR com baixa confianca",
      "minimumAverageConfidence": 0.58,
      "suggestedAction": "Usar arquivo vetorial ou digitalizacao com maior resolucao."
    }
  ]'::jsonb,
  'migration'
)
on conflict (id) do nothing;

alter table public.engineering_analysis_jobs
  drop constraint if exists engineering_analysis_status_check;
alter table public.engineering_analysis_jobs
  add constraint engineering_analysis_status_check check (
    status in (
      'awaitingScale',
      'queued',
      'processing',
      'requiresReview',
      'completed',
      'failed',
      'cancelled'
    )
  );

alter table public.engineering_analysis_jobs
  add column if not exists "rulePackId" text
    references public.engineering_rule_packs(id) on delete restrict,
  add column if not exists "workerRunId" text,
  add column if not exists "workerVersion" text,
  add column if not exists "inputSha256" text,
  add column if not exists "resultSha256" text,
  add column if not exists "resultStoragePath" text,
  add column if not exists "resultSummary" jsonb not null default '{}'::jsonb,
  add column if not exists "ocrUsed" boolean not null default false,
  add column if not exists "vectorObjectCount" integer not null default 0,
  add column if not exists "lineSegmentCount" integer not null default 0;

create table if not exists public.engineering_analysis_scales (
  id text primary key default gen_random_uuid()::text,
  "projectId" text not null references public.projects(id) on delete cascade,
  "analysisJobId" text not null unique
    references public.engineering_analysis_jobs(id) on delete cascade,
  "documentRevisionId" text not null
    references public.engineering_document_revisions(id) on delete cascade,
  denominator numeric(14,4) not null,
  source text not null default 'manual',
  "referencePdfPoints" numeric(14,4),
  "referenceRealMillimeters" numeric(14,4),
  "confirmedByUserId" text not null default '',
  "confirmedAt" timestamptz not null default now(),
  evidence jsonb not null default '{}'::jsonb,
  constraint engineering_analysis_scale_denominator
    check (denominator > 0),
  constraint engineering_analysis_scale_source
    check (source in ('manual', 'titleBlock', 'calibrated')),
  constraint engineering_analysis_scale_reference_pair check (
    (
      "referencePdfPoints" is null
      and "referenceRealMillimeters" is null
    )
    or (
      "referencePdfPoints" > 0
      and "referenceRealMillimeters" > 0
    )
  )
);

create table if not exists public.engineering_analysis_pages (
  id text primary key default gen_random_uuid()::text,
  "projectId" text not null references public.projects(id) on delete cascade,
  "analysisJobId" text not null
    references public.engineering_analysis_jobs(id) on delete cascade,
  "documentRevisionId" text not null
    references public.engineering_document_revisions(id) on delete cascade,
  "pageNumber" integer not null,
  "widthPoints" numeric(14,4) not null,
  "heightPoints" numeric(14,4) not null,
  "textContent" text not null default '',
  "textBlocks" jsonb not null default '[]'::jsonb,
  "vectorObjects" jsonb not null default '[]'::jsonb,
  "lineSegments" jsonb not null default '[]'::jsonb,
  symbols jsonb not null default '[]'::jsonb,
  "ocrUsed" boolean not null default false,
  "ocrWords" jsonb not null default '[]'::jsonb,
  "ocrError" text,
  "createdAt" timestamptz not null default now(),
  unique ("analysisJobId", "pageNumber"),
  constraint engineering_analysis_page_number check ("pageNumber" > 0),
  constraint engineering_analysis_page_size
    check ("widthPoints" > 0 and "heightPoints" > 0),
  constraint engineering_analysis_page_json_arrays check (
    jsonb_typeof("textBlocks") = 'array'
    and jsonb_typeof("vectorObjects") = 'array'
    and jsonb_typeof("lineSegments") = 'array'
    and jsonb_typeof(symbols) = 'array'
    and jsonb_typeof("ocrWords") = 'array'
  )
);

alter table public.engineering_findings
  add column if not exists "rulePackId" text
    references public.engineering_rule_packs(id) on delete restrict,
  add column if not exists "rulePackVersion" text,
  add column if not exists source text not null default 'composite',
  add column if not exists evidence jsonb not null default '{}'::jsonb,
  add column if not exists "suggestedAction" text not null default '',
  add column if not exists "reviewComment" text not null default '';

alter table public.engineering_findings
  drop constraint if exists engineering_findings_source_check;
alter table public.engineering_findings
  add constraint engineering_findings_source_check check (
    source in ('text', 'vector', 'ocr', 'vision', 'composite')
  );

create table if not exists public.engineering_rfis (
  id text primary key default gen_random_uuid()::text,
  "projectId" text not null references public.projects(id) on delete cascade,
  "analysisJobId" text references public.engineering_analysis_jobs(id)
    on delete set null,
  "findingId" text references public.engineering_findings(id) on delete set null,
  "documentRevisionId" text references public.engineering_document_revisions(id)
    on delete set null,
  code text not null,
  title text not null,
  question text not null,
  status text not null default 'open',
  "assignedEmployeeId" text references public.employees(id) on delete set null,
  "dueAt" timestamptz,
  response text not null default '',
  "respondedByUserId" text,
  "respondedAt" timestamptz,
  "createdByUserId" text not null default '',
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now(),
  unique ("findingId"),
  constraint engineering_rfi_status_check
    check (status in ('open', 'responded', 'closed', 'cancelled'))
);

create table if not exists public.engineering_occurrences (
  id text primary key default gen_random_uuid()::text,
  "projectId" text not null references public.projects(id) on delete cascade,
  "analysisJobId" text references public.engineering_analysis_jobs(id)
    on delete set null,
  "findingId" text references public.engineering_findings(id) on delete set null,
  "documentRevisionId" text references public.engineering_document_revisions(id)
    on delete set null,
  title text not null,
  description text not null,
  severity text not null default 'medium',
  status text not null default 'open',
  "assignedEmployeeId" text references public.employees(id) on delete set null,
  "dueAt" timestamptz,
  "resolvedByUserId" text,
  "resolvedAt" timestamptz,
  "createdByUserId" text not null default '',
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now(),
  unique ("findingId"),
  constraint engineering_occurrence_severity_check
    check (severity in ('info', 'low', 'medium', 'high', 'critical')),
  constraint engineering_occurrence_status_check
    check (status in ('open', 'inProgress', 'resolved', 'cancelled'))
);

alter table public.granith_tasks
  add column if not exists "engineeringFindingId" text
    references public.engineering_findings(id) on delete set null;
create unique index if not exists idx_granith_task_engineering_finding
  on public.granith_tasks ("engineeringFindingId")
  where "engineeringFindingId" is not null;

create index if not exists idx_engineering_rule_packs_active
  on public.engineering_rule_packs ("isActive", code, version);
create index if not exists idx_engineering_analysis_pages_job
  on public.engineering_analysis_pages ("analysisJobId", "pageNumber");
create index if not exists idx_engineering_rfis_project_status
  on public.engineering_rfis ("projectId", status, "updatedAt" desc);
create index if not exists idx_engineering_occurrences_project_status
  on public.engineering_occurrences ("projectId", status, "updatedAt" desc);

create sequence if not exists public.engineering_rfi_number_seq;

create or replace function public.create_engineering_analysis_job(
  revision_id text,
  rule_pack_id text,
  scale_denominator numeric,
  scale_source text default 'manual',
  reference_pdf_points numeric default null,
  reference_real_millimeters numeric default null,
  scale_evidence jsonb default '{}'::jsonb
)
returns public.engineering_analysis_jobs
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  revision public.engineering_document_revisions;
  rule_pack public.engineering_rule_packs;
  job public.engineering_analysis_jobs;
begin
  select * into revision
  from public.engineering_document_revisions
  where id = revision_id;

  if revision.id is null
    or not private.can_access_engineering_project(revision."projectId") then
    raise exception using errcode = '42501', message = 'Revision not available.';
  end if;

  select * into rule_pack
  from public.engineering_rule_packs
  where id = rule_pack_id
    and "isActive" = true;

  if rule_pack.id is null then
    raise exception using errcode = '22023', message = 'Rule pack not available.';
  end if;
  if scale_denominator is null or scale_denominator <= 0 then
    raise exception using errcode = '22023', message = 'Scale confirmation is required.';
  end if;
  if scale_source not in ('manual', 'titleBlock', 'calibrated') then
    raise exception using errcode = '22023', message = 'Invalid scale source.';
  end if;
  if (
    (reference_pdf_points is null) <>
    (reference_real_millimeters is null)
  ) then
    raise exception using errcode = '22023', message = 'Incomplete scale calibration.';
  end if;

  insert into public.engineering_analysis_jobs (
    "projectId",
    "documentRevisionId",
    status,
    progress,
    "rulePackId",
    "rulePackVersion",
    "inputSha256",
    "requestedByUserId"
  )
  values (
    revision."projectId",
    revision.id,
    'queued',
    0,
    rule_pack.id,
    rule_pack.version,
    revision.sha256,
    (select auth.uid())::text
  )
  returning * into job;

  insert into public.engineering_analysis_scales (
    "projectId",
    "analysisJobId",
    "documentRevisionId",
    denominator,
    source,
    "referencePdfPoints",
    "referenceRealMillimeters",
    "confirmedByUserId",
    evidence
  )
  values (
    revision."projectId",
    job.id,
    revision.id,
    scale_denominator,
    scale_source,
    reference_pdf_points,
    reference_real_millimeters,
    (select auth.uid())::text,
    coalesce(scale_evidence, '{}'::jsonb)
  );

  return job;
end;
$$;

create or replace function public.update_engineering_analysis_progress(
  job_id text,
  new_progress numeric,
  worker_run_id text,
  worker_version text,
  new_status text default 'processing',
  error_code text default null,
  error_message text default null
)
returns public.engineering_analysis_jobs
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  job public.engineering_analysis_jobs;
begin
  select * into job
  from public.engineering_analysis_jobs
  where id = job_id
  for update;

  if job.id is null
    or not private.can_access_engineering_project(job."projectId") then
    raise exception using errcode = '42501', message = 'Analysis job not available.';
  end if;
  if job.status not in ('queued', 'processing') then
    raise exception using errcode = '55000', message = 'Analysis job is immutable.';
  end if;
  if new_status not in ('processing', 'failed', 'cancelled') then
    raise exception using errcode = '22023', message = 'Invalid analysis status.';
  end if;

  update public.engineering_analysis_jobs
  set status = new_status,
      progress = greatest(0, least(1, coalesce(new_progress, progress))),
      "workerRunId" = coalesce(nullif(worker_run_id, ''), "workerRunId"),
      "workerVersion" = coalesce(nullif(worker_version, ''), "workerVersion"),
      "errorCode" = error_code,
      "errorMessage" = error_message,
      "startedAt" = coalesce("startedAt", now()),
      "finishedAt" = case
        when new_status in ('failed', 'cancelled') then now()
        else null
      end
  where id = job.id
  returning * into job;

  return job;
end;
$$;

create or replace function public.complete_engineering_analysis(
  job_id text,
  result_sha256 text,
  result_storage_path text,
  result_payload jsonb
)
returns public.engineering_analysis_jobs
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  job public.engineering_analysis_jobs;
  rule_pack public.engineering_rule_packs;
  revision public.engineering_document_revisions;
  analysis_scale public.engineering_analysis_scales;
  page jsonb;
  finding jsonb;
  summary jsonb;
  finding_count integer := 0;
begin
  select * into job
  from public.engineering_analysis_jobs
  where id = job_id
  for update;

  if job.id is null
    or not private.can_access_engineering_project(job."projectId") then
    raise exception using errcode = '42501', message = 'Analysis job not available.';
  end if;
  if job.status not in ('queued', 'processing') then
    raise exception using errcode = '55000', message = 'Analysis job is immutable.';
  end if;
  if result_payload ->> 'jobId' is distinct from job.id then
    raise exception using errcode = '22023', message = 'Result job mismatch.';
  end if;
  if result_sha256 !~ '^[0-9a-f]{64}$' then
    raise exception using errcode = '22023', message = 'Invalid result SHA-256.';
  end if;
  if result_storage_path not like job."projectId" || '/' || job.id || '/%' then
    raise exception using errcode = '22023', message = 'Invalid result storage path.';
  end if;
  if not exists (
    select 1
    from storage.objects object
    where object.bucket_id = 'engineering-derived'
      and object.name = result_storage_path
  ) then
    raise exception using errcode = '22023', message = 'Result artifact not found.';
  end if;

  select * into revision
  from public.engineering_document_revisions
  where id = job."documentRevisionId";
  if result_payload ->> 'inputSha256' is distinct from revision.sha256 then
    raise exception using errcode = '22023', message = 'Input SHA-256 mismatch.';
  end if;

  select * into rule_pack
  from public.engineering_rule_packs
  where id = job."rulePackId";
  if result_payload #>> '{rulePack,id}' is distinct from rule_pack.id
    or result_payload #>> '{rulePack,version}' is distinct from rule_pack.version
    or result_payload #>> '{rulePack,sha256}' is distinct from rule_pack."contentSha256" then
    raise exception using errcode = '22023', message = 'Rule pack mismatch.';
  end if;

  select * into analysis_scale
  from public.engineering_analysis_scales
  where "analysisJobId" = job.id;
  if (result_payload #>> '{scale,denominator}')::numeric
      is distinct from analysis_scale.denominator
    or result_payload #>> '{scale,source}'
      is distinct from analysis_scale.source then
    raise exception using errcode = '22023', message = 'Confirmed scale mismatch.';
  end if;

  if jsonb_typeof(result_payload -> 'pages') is distinct from 'array'
    or jsonb_typeof(result_payload -> 'findings') is distinct from 'array' then
    raise exception using errcode = '22023', message = 'Invalid result payload.';
  end if;

  for page in
    select value from jsonb_array_elements(result_payload -> 'pages')
  loop
    insert into public.engineering_analysis_pages (
      "projectId",
      "analysisJobId",
      "documentRevisionId",
      "pageNumber",
      "widthPoints",
      "heightPoints",
      "textContent",
      "textBlocks",
      "vectorObjects",
      "lineSegments",
      symbols,
      "ocrUsed",
      "ocrWords",
      "ocrError"
    )
    values (
      job."projectId",
      job.id,
      job."documentRevisionId",
      (page ->> 'pageNumber')::integer,
      (page ->> 'widthPoints')::numeric,
      (page ->> 'heightPoints')::numeric,
      coalesce(page ->> 'text', ''),
      coalesce(page -> 'textBlocks', '[]'::jsonb),
      coalesce(page -> 'vectorObjects', '[]'::jsonb),
      coalesce(page -> 'lineSegments', '[]'::jsonb),
      coalesce(page -> 'symbols', '[]'::jsonb),
      coalesce((page ->> 'ocrUsed')::boolean, false),
      coalesce(page -> 'ocrWords', '[]'::jsonb),
      nullif(page ->> 'ocrError', '')
    );
  end loop;

  for finding in
    select value from jsonb_array_elements(result_payload -> 'findings')
  loop
    insert into public.engineering_findings (
      "projectId",
      "analysisJobId",
      "documentRevisionId",
      "pageNumber",
      severity,
      status,
      category,
      title,
      description,
      "ruleCode",
      geometry,
      confidence,
      "rulePackId",
      "rulePackVersion",
      source,
      evidence,
      "suggestedAction"
    )
    values (
      job."projectId",
      job.id,
      job."documentRevisionId",
      greatest(1, coalesce((finding ->> 'pageNumber')::integer, 1)),
      coalesce(nullif(finding ->> 'severity', ''), 'medium'),
      'open',
      coalesce(nullif(finding ->> 'category', ''), 'general'),
      coalesce(nullif(finding ->> 'title', ''), 'Apontamento tecnico'),
      coalesce(finding ->> 'description', ''),
      nullif(finding ->> 'ruleCode', ''),
      coalesce(finding -> 'geometry', '{}'::jsonb),
      (finding ->> 'confidence')::numeric,
      rule_pack.id,
      rule_pack.version,
      coalesce(nullif(finding ->> 'source', ''), 'composite'),
      coalesce(finding -> 'evidence', '{}'::jsonb),
      coalesce(finding ->> 'suggestedAction', '')
    );
    finding_count := finding_count + 1;
  end loop;

  summary := coalesce(result_payload -> 'summary', '{}'::jsonb);
  update public.engineering_analysis_jobs
  set status = case when finding_count > 0 then 'requiresReview' else 'completed' end,
      progress = 1,
      "workerVersion" = coalesce(
        nullif(result_payload #>> '{engine,version}', ''),
        "workerVersion"
      ),
      "resultSha256" = result_sha256,
      "resultStoragePath" = result_storage_path,
      "resultSummary" = summary,
      "ocrUsed" = coalesce((summary ->> 'ocrPageCount')::integer, 0) > 0,
      "vectorObjectCount" = coalesce(
        (summary ->> 'vectorObjectCount')::integer,
        0
      ),
      "lineSegmentCount" = coalesce(
        (summary ->> 'lineSegmentCount')::integer,
        0
      ),
      "errorCode" = null,
      "errorMessage" = null,
      "startedAt" = coalesce("startedAt", now()),
      "finishedAt" = now()
  where id = job.id
  returning * into job;

  return job;
end;
$$;

create or replace function public.review_engineering_finding(
  finding_id text,
  decision text,
  review_comment text default ''
)
returns public.engineering_findings
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  finding public.engineering_findings;
begin
  select * into finding
  from public.engineering_findings
  where id = finding_id
  for update;

  if finding.id is null
    or not private.can_access_engineering_project(finding."projectId") then
    raise exception using errcode = '42501', message = 'Finding not available.';
  end if;
  if decision not in ('accepted', 'rejected', 'resolved') then
    raise exception using errcode = '22023', message = 'Invalid review decision.';
  end if;
  if finding.status <> 'open' and decision <> 'resolved' then
    raise exception using errcode = '55000', message = 'Finding already reviewed.';
  end if;
  if decision = 'resolved' and finding.status <> 'accepted' then
    raise exception using errcode = '55000', message = 'Accept finding before resolving.';
  end if;

  update public.engineering_findings
  set status = decision,
      "reviewComment" = coalesce(review_comment, ''),
      "reviewedByUserId" = (select auth.uid())::text,
      "reviewedAt" = now()
  where id = finding.id
  returning * into finding;

  if not exists (
    select 1
    from public.engineering_findings pending
    where pending."analysisJobId" = finding."analysisJobId"
      and pending.status = 'open'
  ) then
    update public.engineering_analysis_jobs
    set status = 'completed'
    where id = finding."analysisJobId"
      and status = 'requiresReview';
  end if;

  return finding;
end;
$$;

create or replace function public.create_engineering_action_from_finding(
  finding_id text,
  action_type text,
  action_title text,
  action_description text default '',
  assigned_employee_id text default null,
  supervisor_employee_id text default null,
  due_at timestamptz default null,
  action_priority text default 'medium'
)
returns jsonb
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  finding public.engineering_findings;
  entity_id text;
  project_name text;
  assignee_name text;
  supervisor_name text;
  rfi_code text;
begin
  select * into finding
  from public.engineering_findings
  where id = finding_id;

  if finding.id is null
    or not private.can_access_engineering_project(finding."projectId") then
    raise exception using errcode = '42501', message = 'Finding not available.';
  end if;
  if finding.status <> 'accepted' then
    raise exception using
      errcode = '55000',
      message = 'Human acceptance is required before creating an action.';
  end if;
  if action_type not in ('rfi', 'occurrence', 'task') then
    raise exception using errcode = '22023', message = 'Invalid action type.';
  end if;
  if nullif(trim(action_title), '') is null then
    raise exception using errcode = '22023', message = 'Action title is required.';
  end if;

  select name into project_name
  from public.projects
  where id = finding."projectId";

  if action_type = 'rfi' then
    rfi_code := 'RFI-' || to_char(now(), 'YYYY') || '-' ||
      lpad(nextval('public.engineering_rfi_number_seq')::text, 5, '0');
    insert into public.engineering_rfis (
      "projectId",
      "analysisJobId",
      "findingId",
      "documentRevisionId",
      code,
      title,
      question,
      "assignedEmployeeId",
      "dueAt",
      "createdByUserId"
    )
    values (
      finding."projectId",
      finding."analysisJobId",
      finding.id,
      finding."documentRevisionId",
      rfi_code,
      action_title,
      coalesce(nullif(action_description, ''), finding.description),
      assigned_employee_id,
      due_at,
      (select auth.uid())::text
    )
    returning id into entity_id;
  elsif action_type = 'occurrence' then
    insert into public.engineering_occurrences (
      "projectId",
      "analysisJobId",
      "findingId",
      "documentRevisionId",
      title,
      description,
      severity,
      "assignedEmployeeId",
      "dueAt",
      "createdByUserId"
    )
    values (
      finding."projectId",
      finding."analysisJobId",
      finding.id,
      finding."documentRevisionId",
      action_title,
      coalesce(nullif(action_description, ''), finding.description),
      finding.severity,
      assigned_employee_id,
      due_at,
      (select auth.uid())::text
    )
    returning id into entity_id;
  else
    if assigned_employee_id is null or supervisor_employee_id is null then
      raise exception using
        errcode = '22023',
        message = 'Task requires assignee and supervisor.';
    end if;
    if action_priority not in ('low', 'medium', 'high', 'urgent') then
      raise exception using errcode = '22023', message = 'Invalid task priority.';
    end if;

    select name into assignee_name
    from public.employees where id = assigned_employee_id;
    select name into supervisor_name
    from public.employees where id = supervisor_employee_id;
    if assignee_name is null or supervisor_name is null then
      raise exception using errcode = '22023', message = 'Employee not found.';
    end if;

    insert into public.granith_tasks (
      title,
      description,
      status,
      priority,
      "supervisorId",
      "supervisorName",
      "assigneeId",
      "assigneeName",
      "projectId",
      "projectName",
      "sourceType",
      "dueAt",
      "engineeringFindingId",
      "createdByUserId"
    )
    values (
      action_title,
      coalesce(nullif(action_description, ''), finding.description),
      'pending',
      action_priority,
      supervisor_employee_id,
      supervisor_name,
      assigned_employee_id,
      assignee_name,
      finding."projectId",
      coalesce(project_name, ''),
      'project',
      due_at,
      finding.id,
      (select auth.uid())::text
    )
    returning id into entity_id;
  end if;

  return jsonb_build_object('type', action_type, 'id', entity_id);
end;
$$;

revoke all on function public.create_engineering_analysis_job(
  text, text, numeric, text, numeric, numeric, jsonb
) from public, anon;
revoke all on function public.update_engineering_analysis_progress(
  text, numeric, text, text, text, text, text
) from public, anon;
revoke all on function public.complete_engineering_analysis(
  text, text, text, jsonb
) from public, anon;
revoke all on function public.review_engineering_finding(text, text, text)
  from public, anon;
revoke all on function public.create_engineering_action_from_finding(
  text, text, text, text, text, text, timestamptz, text
) from public, anon;

grant execute on function public.create_engineering_analysis_job(
  text, text, numeric, text, numeric, numeric, jsonb
) to authenticated;
grant execute on function public.update_engineering_analysis_progress(
  text, numeric, text, text, text, text, text
) to authenticated;
grant execute on function public.complete_engineering_analysis(
  text, text, text, jsonb
) to authenticated;
grant execute on function public.review_engineering_finding(text, text, text)
  to authenticated;
grant execute on function public.create_engineering_action_from_finding(
  text, text, text, text, text, text, timestamptz, text
) to authenticated;

alter table public.engineering_rule_packs enable row level security;
alter table public.engineering_rule_packs force row level security;
alter table public.engineering_analysis_scales enable row level security;
alter table public.engineering_analysis_scales force row level security;
alter table public.engineering_analysis_pages enable row level security;
alter table public.engineering_analysis_pages force row level security;
alter table public.engineering_rfis enable row level security;
alter table public.engineering_rfis force row level security;
alter table public.engineering_occurrences enable row level security;
alter table public.engineering_occurrences force row level security;

create policy engineering_rule_packs_select
on public.engineering_rule_packs
for select to authenticated
using (private.can_access_engineering());
create policy engineering_rule_packs_manage
on public.engineering_rule_packs
for all to authenticated
using (private.can_manage_engineering_profiles())
with check (private.can_manage_engineering_profiles());

create policy engineering_analysis_scales_select
on public.engineering_analysis_scales
for select to authenticated
using (private.can_access_engineering_project("projectId"));
create policy engineering_analysis_pages_select
on public.engineering_analysis_pages
for select to authenticated
using (private.can_access_engineering_project("projectId"));

create policy engineering_rfis_select
on public.engineering_rfis
for select to authenticated
using (private.can_access_engineering_project("projectId"));
create policy engineering_rfis_update
on public.engineering_rfis
for update to authenticated
using (private.can_access_engineering_project("projectId"))
with check (private.can_access_engineering_project("projectId"));

create policy engineering_occurrences_select
on public.engineering_occurrences
for select to authenticated
using (private.can_access_engineering_project("projectId"));
create policy engineering_occurrences_update
on public.engineering_occurrences
for update to authenticated
using (private.can_access_engineering_project("projectId"))
with check (private.can_access_engineering_project("projectId"));

drop policy if exists engineering_analysis_jobs_insert
  on public.engineering_analysis_jobs;
drop policy if exists engineering_analysis_jobs_update
  on public.engineering_analysis_jobs;
drop policy if exists engineering_analysis_jobs_delete
  on public.engineering_analysis_jobs;
drop policy if exists engineering_findings_insert
  on public.engineering_findings;
drop policy if exists engineering_findings_update
  on public.engineering_findings;
drop policy if exists engineering_findings_delete
  on public.engineering_findings;

revoke insert, update, delete on public.engineering_analysis_jobs
  from authenticated;
revoke insert, update, delete on public.engineering_findings
  from authenticated;

revoke all on public.engineering_rule_packs from public, anon;
revoke all on public.engineering_analysis_scales from public, anon;
revoke all on public.engineering_analysis_pages from public, anon;
revoke all on public.engineering_rfis from public, anon;
revoke all on public.engineering_occurrences from public, anon;
grant select on public.engineering_rule_packs to authenticated;
grant insert, update on public.engineering_rule_packs to authenticated;
grant select on public.engineering_analysis_scales to authenticated;
grant select on public.engineering_analysis_pages to authenticated;
grant select, update on public.engineering_rfis to authenticated;
grant select, update on public.engineering_occurrences to authenticated;
grant all on public.engineering_rule_packs to service_role;
grant all on public.engineering_analysis_scales to service_role;
grant all on public.engineering_analysis_pages to service_role;
grant all on public.engineering_rfis to service_role;
grant all on public.engineering_occurrences to service_role;

drop policy if exists engineering_analysis_result_immutable_delete
  on storage.objects;
create policy engineering_analysis_result_immutable_delete
on storage.objects
as restrictive
for delete to authenticated
using (
  bucket_id <> 'engineering-derived'
  or not exists (
    select 1
    from public.engineering_analysis_jobs job
    where job."resultStoragePath" = storage.objects.name
  )
);

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'engineering_analysis_scales',
    'engineering_analysis_pages',
    'engineering_rfis',
    'engineering_occurrences'
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
    add table public.engineering_findings;
exception when duplicate_object then null;
end
$$;
do $$
begin
  alter publication supabase_realtime
    add table public.engineering_rfis;
exception when duplicate_object then null;
end
$$;
do $$
begin
  alter publication supabase_realtime
    add table public.engineering_occurrences;
exception when duplicate_object then null;
end
$$;
