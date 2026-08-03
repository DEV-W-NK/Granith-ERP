-- Granith Engenharia P0 foundation.
-- The ERP remains the canonical owner of shared projects, employees,
-- material requisitions and Granith tasks.

create schema if not exists private;
create extension if not exists pgcrypto;

create table if not exists public.engineering_user_profiles (
  "userId" text primary key references public.users(id) on delete cascade,
  "employeeId" text references public.employees(id) on delete set null,
  role text not null default 'engineer',
  "isActive" boolean not null default true,
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now(),
  constraint engineering_user_profiles_role_check check (
    role in ('engineer', 'administrator')
  )
);

create index if not exists idx_engineering_profiles_employee
  on public.engineering_user_profiles ("employeeId")
  where "employeeId" is not null;

insert into public.engineering_user_profiles (
  "userId",
  "employeeId",
  role,
  "isActive"
)
select
  users.id,
  coalesce(nullif(users."employeeId", ''), nullif(users.employee_id, '')),
  'administrator',
  true
from public.users users
where users.role = 'admin'
on conflict ("userId") do update
set role = 'administrator',
    "isActive" = true,
    "employeeId" = coalesce(
      excluded."employeeId",
      public.engineering_user_profiles."employeeId"
    ),
    "updatedAt" = now();

create or replace function private.current_engineering_role()
returns text
language sql
stable
security definer
set search_path = public, private, pg_temp
as $$
  select case
    when private.is_admin() then 'administrator'
    else (
      select profile.role
      from public.engineering_user_profiles profile
      where profile."userId"::text = (select auth.uid())::text
        and profile."isActive" = true
      limit 1
    )
  end;
$$;

create or replace function private.can_access_engineering()
returns boolean
language sql
stable
security definer
set search_path = public, private, pg_temp
as $$
  select coalesce(
    private.current_engineering_role() in ('engineer', 'administrator'),
    false
  );
$$;

create or replace function private.can_manage_engineering_profiles()
returns boolean
language sql
stable
security definer
set search_path = public, private, pg_temp
as $$
  select private.is_admin() or private.can_manage_access();
$$;

create or replace function private.can_read_engineering_financials()
returns boolean
language sql
stable
security definer
set search_path = public, private, pg_temp
as $$
  select coalesce(
    private.current_engineering_role() = 'administrator',
    false
  );
$$;

create or replace function private.can_access_engineering_project(
  project_id text
)
returns boolean
language sql
stable
security definer
set search_path = public, private, pg_temp
as $$
  select private.can_access_engineering()
    and nullif(trim(project_id), '') is not null
    and (
      private.can_read_projects()
      or private.current_employee_assigned_to_project(trim(project_id))
    );
$$;

revoke all on function private.current_engineering_role()
  from public, anon;
revoke all on function private.can_access_engineering()
  from public, anon;
revoke all on function private.can_manage_engineering_profiles()
  from public, anon;
revoke all on function private.can_read_engineering_financials()
  from public, anon;
revoke all on function private.can_access_engineering_project(text)
  from public, anon;
grant execute on function private.current_engineering_role()
  to authenticated;
grant execute on function private.can_access_engineering()
  to authenticated;
grant execute on function private.can_manage_engineering_profiles()
  to authenticated;
grant execute on function private.can_read_engineering_financials()
  to authenticated;
grant execute on function private.can_access_engineering_project(text)
  to authenticated;

create or replace function public.get_current_engineering_profile()
returns table (
  "userId" text,
  email text,
  "employeeId" text,
  "employeeName" text,
  role text,
  "canViewFinancialValues" boolean
)
language sql
stable
security definer
set search_path = public, private, pg_temp
as $$
  select
    users.id,
    users.email,
    coalesce(
      nullif(profile."employeeId", ''),
      nullif(users."employeeId", ''),
      nullif(users.employee_id, '')
    ),
    coalesce(
      employee.name,
      nullif(users."employeeName", ''),
      nullif(users.employee_name, ''),
      nullif(users."displayName", ''),
      nullif(users.display_name, ''),
      users.email
    ),
    private.current_engineering_role(),
    private.can_read_engineering_financials()
  from public.users users
  left join public.engineering_user_profiles profile
    on profile."userId" = users.id
   and profile."isActive" = true
  left join public.employees employee
    on employee.id = coalesce(
      nullif(profile."employeeId", ''),
      nullif(users."employeeId", ''),
      nullif(users.employee_id, '')
    )
  where users.id::text = (select auth.uid())::text
    and users.status = 'ativo'
    and private.can_access_engineering()
  limit 1;
$$;

revoke all on function public.get_current_engineering_profile()
  from public, anon;
grant execute on function public.get_current_engineering_profile()
  to authenticated;

create or replace function public.set_engineering_user_profile(
  p_user_id text,
  p_role text,
  p_is_active boolean default true
)
returns public.engineering_user_profiles
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_profile public.engineering_user_profiles%rowtype;
  v_employee_id text;
begin
  if not private.can_manage_engineering_profiles() then
    raise exception 'Engineering profile management is not allowed.'
      using errcode = '42501';
  end if;

  if p_role not in ('engineer', 'administrator') then
    raise exception 'Invalid engineering role.'
      using errcode = '22023';
  end if;

  select coalesce(
    nullif(users."employeeId", ''),
    nullif(users.employee_id, '')
  )
  into v_employee_id
  from public.users users
  where users.id::text = trim(p_user_id)
    and users.status = 'ativo'
  limit 1;

  if not found then
    raise exception 'Active Granith user was not found.'
      using errcode = 'P0002';
  end if;

  insert into public.engineering_user_profiles (
    "userId",
    "employeeId",
    role,
    "isActive"
  )
  values (
    trim(p_user_id),
    v_employee_id,
    p_role,
    coalesce(p_is_active, true)
  )
  on conflict ("userId") do update
  set "employeeId" = excluded."employeeId",
      role = excluded.role,
      "isActive" = excluded."isActive",
      "updatedAt" = clock_timestamp()
  returning * into v_profile;

  return v_profile;
end;
$$;

revoke all on function public.set_engineering_user_profile(
  text,
  text,
  boolean
) from public, anon;
grant execute on function public.set_engineering_user_profile(
  text,
  text,
  boolean
) to authenticated;

create or replace function public.get_engineering_project_people()
returns table (
  "projectId" text,
  "employeeId" text,
  "employeeName" text,
  "jobTitle" text,
  "employeeRole" text
)
language sql
stable
security definer
set search_path = public, private, pg_temp
as $$
  with accessible_projects as (
    select project.id
    from public.projects project
    where private.can_access_engineering_project(project.id::text)
  ),
  project_employee_ids as (
    select project.id as project_id, project."coordinatorId" as employee_id
    from public.projects project
    join accessible_projects accessible on accessible.id = project.id
    where project."coordinatorId" is not null

    union

    select team."projectId", team."leaderId"
    from public.teams team
    join accessible_projects accessible on accessible.id = team."projectId"
    where team."isActive" = true
      and team."leaderId" is not null

    union

    select team."projectId", member_id
    from public.teams team
    join accessible_projects accessible on accessible.id = team."projectId"
    cross join lateral unnest(team."memberIds") member_id
    where team."isActive" = true
  )
  select distinct
    relation.project_id,
    employee.id,
    employee.name,
    employee."jobTitle",
    employee.role
  from project_employee_ids relation
  join public.employees employee on employee.id = relation.employee_id
  where employee.status <> 'desligado'
  order by employee.name;
$$;

revoke all on function public.get_engineering_project_people()
  from public, anon;
grant execute on function public.get_engineering_project_people()
  to authenticated;

-- Engineering users share the existing material and task workflows. They
-- still need an active employee link and an assignment to the target project.
create or replace function private.can_request_mobile_materials()
returns boolean
language sql
stable
security definer
set search_path = public, private, pg_temp
as $$
  select private.has_min_employee_role(2)
    or private.can_access_engineering();
$$;

grant execute on function private.can_request_mobile_materials()
  to authenticated;

drop policy if exists material_requisitions_select_authorized
  on public.material_requisitions;
create policy material_requisitions_select_authorized
on public.material_requisitions
for select to authenticated
using (
  private.can_read_purchases()
  or "requesterId" in (
    private.current_employee_id(),
    (select auth.uid())::text
  )
  or private.can_access_engineering_project("projectId"::text)
);

drop policy if exists granith_tasks_select_related
  on public.granith_tasks;
drop policy if exists granith_tasks_insert_supervisor
  on public.granith_tasks;
drop policy if exists granith_tasks_update_supervisor
  on public.granith_tasks;
drop policy if exists granith_tasks_delete_supervisor
  on public.granith_tasks;

create policy granith_tasks_select_related
on public.granith_tasks
for select to authenticated
using (
  private.can_manage_people()
  or private.has_min_employee_role(3)
  or "supervisorId" = private.current_task_employee_id()
  or "assigneeId" = private.current_task_employee_id()
  or "createdByUserId" = (select auth.uid())::text
  or (
    "projectId" is not null
    and private.can_access_engineering_project("projectId"::text)
  )
);

create policy granith_tasks_insert_supervisor
on public.granith_tasks
for insert to authenticated
with check (
  private.can_manage_people()
  or private.has_min_employee_role(3)
  or (
    private.has_min_employee_role(2)
    and "supervisorId" = private.current_task_employee_id()
  )
  or (
    "projectId" is not null
    and private.can_access_engineering_project("projectId"::text)
  )
);

create policy granith_tasks_update_supervisor
on public.granith_tasks
for update to authenticated
using (
  private.can_manage_people()
  or private.has_min_employee_role(3)
  or "supervisorId" = private.current_task_employee_id()
  or (
    "projectId" is not null
    and private.can_access_engineering_project("projectId"::text)
  )
)
with check (
  private.can_manage_people()
  or private.has_min_employee_role(3)
  or "supervisorId" = private.current_task_employee_id()
  or (
    "projectId" is not null
    and private.can_access_engineering_project("projectId"::text)
  )
);

create policy granith_tasks_delete_supervisor
on public.granith_tasks
for delete to authenticated
using (
  private.can_manage_people()
  or private.has_min_employee_role(3)
  or "supervisorId" = private.current_task_employee_id()
  or (
    "projectId" is not null
    and private.can_access_engineering_project("projectId"::text)
  )
);

create table if not exists public.engineering_documents (
  id text primary key default gen_random_uuid()::text,
  "projectId" text not null references public.projects(id) on delete cascade,
  title text not null,
  discipline text not null default 'Geral',
  "documentType" text not null default 'drawing',
  "currentRevisionId" text,
  "createdByUserId" text not null default '',
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now(),
  "archivedAt" timestamptz,
  constraint engineering_documents_title_not_blank check (
    length(trim(title)) > 0
  ),
  constraint engineering_documents_type_check check (
    "documentType" in (
      'drawing',
      'report',
      'specification',
      'memorial',
      'certificate',
      'other'
    )
  )
);

create table if not exists public.engineering_document_revisions (
  id text primary key default gen_random_uuid()::text,
  "documentId" text not null
    references public.engineering_documents(id) on delete cascade,
  "projectId" text not null references public.projects(id) on delete cascade,
  "revisionCode" text not null default 'R00',
  "filePath" text not null,
  "originalFileName" text not null,
  "mimeType" text not null default 'application/pdf',
  "sizeBytes" bigint not null default 0,
  "sha256" text not null default '',
  "pageCount" integer not null default 0,
  status text not null default 'draft',
  notes text not null default '',
  "uploadedByUserId" text not null default '',
  "reviewedByUserId" text,
  "reviewedAt" timestamptz,
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now(),
  constraint engineering_revisions_status_check check (
    status in (
      'draft',
      'underReview',
      'approved',
      'revisionRequested',
      'superseded'
    )
  ),
  constraint engineering_revisions_size_check check ("sizeBytes" >= 0),
  constraint engineering_revisions_page_count_check check ("pageCount" >= 0),
  unique ("documentId", "revisionCode"),
  unique ("filePath")
);

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'engineering_documents_current_revision_fk'
  ) then
    alter table public.engineering_documents
      add constraint engineering_documents_current_revision_fk
      foreign key ("currentRevisionId")
      references public.engineering_document_revisions(id)
      on delete set null;
  end if;
end
$$;

create table if not exists public.engineering_annotations (
  id text primary key default gen_random_uuid()::text,
  "projectId" text not null references public.projects(id) on delete cascade,
  "documentRevisionId" text not null
    references public.engineering_document_revisions(id) on delete cascade,
  "pageNumber" integer not null default 1,
  kind text not null default 'comment',
  geometry jsonb not null default '{}'::jsonb,
  content text not null default '',
  status text not null default 'open',
  "createdByUserId" text not null default '',
  "resolvedByUserId" text,
  "resolvedAt" timestamptz,
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now(),
  constraint engineering_annotations_page_check check ("pageNumber" > 0),
  constraint engineering_annotations_kind_check check (
    kind in ('comment', 'measurement', 'issue', 'stamp', 'markup')
  ),
  constraint engineering_annotations_status_check check (
    status in ('open', 'resolved', 'cancelled')
  )
);

create table if not exists public.engineering_analysis_jobs (
  id text primary key default gen_random_uuid()::text,
  "projectId" text not null references public.projects(id) on delete cascade,
  "documentRevisionId" text not null
    references public.engineering_document_revisions(id) on delete cascade,
  status text not null default 'queued',
  progress numeric(5,4) not null default 0,
  "requestedByUserId" text not null default '',
  "workerId" text,
  "rulePackVersion" text,
  "errorCode" text,
  "errorMessage" text,
  "startedAt" timestamptz,
  "finishedAt" timestamptz,
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now(),
  constraint engineering_analysis_status_check check (
    status in (
      'queued',
      'processing',
      'requiresReview',
      'completed',
      'failed',
      'cancelled'
    )
  ),
  constraint engineering_analysis_progress_check check (
    progress >= 0 and progress <= 1
  )
);

create table if not exists public.engineering_findings (
  id text primary key default gen_random_uuid()::text,
  "projectId" text not null references public.projects(id) on delete cascade,
  "analysisJobId" text not null
    references public.engineering_analysis_jobs(id) on delete cascade,
  "documentRevisionId" text not null
    references public.engineering_document_revisions(id) on delete cascade,
  "pageNumber" integer not null default 1,
  severity text not null default 'medium',
  status text not null default 'open',
  category text not null default 'general',
  title text not null,
  description text not null default '',
  "ruleCode" text,
  geometry jsonb not null default '{}'::jsonb,
  confidence numeric(5,4),
  "reviewedByUserId" text,
  "reviewedAt" timestamptz,
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now(),
  constraint engineering_findings_page_check check ("pageNumber" > 0),
  constraint engineering_findings_severity_check check (
    severity in ('info', 'low', 'medium', 'high', 'critical')
  ),
  constraint engineering_findings_status_check check (
    status in ('open', 'accepted', 'rejected', 'resolved')
  ),
  constraint engineering_findings_confidence_check check (
    confidence is null or (confidence >= 0 and confidence <= 1)
  )
);

create table if not exists public.engineering_deliveries (
  id text primary key default gen_random_uuid()::text,
  "projectId" text not null references public.projects(id) on delete cascade,
  title text not null,
  recipient text not null default '',
  "recipientEmail" text,
  status text not null default 'preparing',
  "dueAt" timestamptz,
  "sentAt" timestamptz,
  "acknowledgedAt" timestamptz,
  "createdByUserId" text not null default '',
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now(),
  constraint engineering_deliveries_status_check check (
    status in (
      'preparing',
      'sent',
      'acknowledged',
      'revisionRequested',
      'cancelled'
    )
  )
);

create table if not exists public.engineering_delivery_documents (
  id text primary key default gen_random_uuid()::text,
  "projectId" text not null references public.projects(id) on delete cascade,
  "deliveryId" text not null
    references public.engineering_deliveries(id) on delete cascade,
  "documentRevisionId" text not null
    references public.engineering_document_revisions(id) on delete restrict,
  "createdAt" timestamptz not null default now(),
  unique ("deliveryId", "documentRevisionId")
);

create table if not exists public.engineering_audit_events (
  id bigint generated always as identity primary key,
  "projectId" text references public.projects(id) on delete set null,
  "actorUserId" text,
  action text not null,
  "entityType" text not null,
  "entityId" text not null,
  payload jsonb not null default '{}'::jsonb,
  "createdAt" timestamptz not null default now()
);

create index if not exists idx_engineering_documents_project
  on public.engineering_documents ("projectId", "updatedAt" desc)
  where "archivedAt" is null;
create index if not exists idx_engineering_revisions_project
  on public.engineering_document_revisions ("projectId", "createdAt" desc);
create index if not exists idx_engineering_annotations_revision
  on public.engineering_annotations ("documentRevisionId", "pageNumber");
create index if not exists idx_engineering_analysis_project_status
  on public.engineering_analysis_jobs ("projectId", status, "createdAt" desc);
create index if not exists idx_engineering_findings_job_status
  on public.engineering_findings ("analysisJobId", status, severity);
create index if not exists idx_engineering_deliveries_project
  on public.engineering_deliveries ("projectId", status, "dueAt");
create index if not exists idx_engineering_audit_project
  on public.engineering_audit_events ("projectId", "createdAt" desc);

create or replace function private.prepare_engineering_record()
returns trigger
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
begin
  if tg_op = 'INSERT' then
    if to_jsonb(new) ? 'createdByUserId' then
      new := jsonb_populate_record(
        new,
        jsonb_build_object(
          'createdByUserId',
          coalesce(
            nullif(to_jsonb(new) ->> 'createdByUserId', ''),
            (select auth.uid())::text
          )
        )
      );
    end if;

    if to_jsonb(new) ? 'uploadedByUserId' then
      new := jsonb_populate_record(
        new,
        jsonb_build_object(
          'uploadedByUserId',
          coalesce(
            nullif(to_jsonb(new) ->> 'uploadedByUserId', ''),
            (select auth.uid())::text
          )
        )
      );
    end if;

    if to_jsonb(new) ? 'requestedByUserId' then
      new := jsonb_populate_record(
        new,
        jsonb_build_object(
          'requestedByUserId',
          coalesce(
            nullif(to_jsonb(new) ->> 'requestedByUserId', ''),
            (select auth.uid())::text
          )
        )
      );
    end if;
  end if;

  if to_jsonb(new) ? 'updatedAt' then
    new := jsonb_populate_record(
      new,
      jsonb_build_object('updatedAt', clock_timestamp())
    );
  end if;

  return new;
end;
$$;

revoke all on function private.prepare_engineering_record()
  from public, anon, authenticated;

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'engineering_user_profiles',
    'engineering_documents',
    'engineering_document_revisions',
    'engineering_annotations',
    'engineering_analysis_jobs',
    'engineering_findings',
    'engineering_deliveries'
  ]
  loop
    execute format(
      'drop trigger if exists prepare_%I_row on public.%I',
      table_name,
      table_name
    );
    execute format(
      'create trigger prepare_%I_row before insert or update on public.%I
       for each row execute function private.prepare_engineering_record()',
      table_name,
      table_name
    );
  end loop;
end
$$;

create or replace function private.record_engineering_audit()
returns trigger
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  row_data jsonb;
  entity_id text;
  project_id text;
begin
  row_data := case when tg_op = 'DELETE' then to_jsonb(old) else to_jsonb(new) end;
  entity_id := coalesce(row_data ->> 'id', '');
  project_id := nullif(row_data ->> 'projectId', '');

  insert into public.engineering_audit_events (
    "projectId",
    "actorUserId",
    action,
    "entityType",
    "entityId",
    payload
  )
  values (
    project_id,
    (select auth.uid())::text,
    lower(tg_op),
    tg_table_name,
    entity_id,
    jsonb_build_object('row', row_data)
  );

  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

revoke all on function private.record_engineering_audit()
  from public, anon, authenticated;

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'engineering_documents',
    'engineering_document_revisions',
    'engineering_annotations',
    'engineering_analysis_jobs',
    'engineering_findings',
    'engineering_deliveries',
    'engineering_delivery_documents'
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

alter table public.engineering_user_profiles enable row level security;
alter table public.engineering_user_profiles force row level security;
alter table public.engineering_documents enable row level security;
alter table public.engineering_documents force row level security;
alter table public.engineering_document_revisions enable row level security;
alter table public.engineering_document_revisions force row level security;
alter table public.engineering_annotations enable row level security;
alter table public.engineering_annotations force row level security;
alter table public.engineering_analysis_jobs enable row level security;
alter table public.engineering_analysis_jobs force row level security;
alter table public.engineering_findings enable row level security;
alter table public.engineering_findings force row level security;
alter table public.engineering_deliveries enable row level security;
alter table public.engineering_deliveries force row level security;
alter table public.engineering_delivery_documents enable row level security;
alter table public.engineering_delivery_documents force row level security;
alter table public.engineering_audit_events enable row level security;
alter table public.engineering_audit_events force row level security;

drop policy if exists engineering_profiles_select on public.engineering_user_profiles;
drop policy if exists engineering_profiles_manage on public.engineering_user_profiles;
create policy engineering_profiles_select
on public.engineering_user_profiles
for select to authenticated
using (
  "userId"::text = (select auth.uid())::text
  or private.can_manage_engineering_profiles()
);
create policy engineering_profiles_manage
on public.engineering_user_profiles
for all to authenticated
using (private.can_manage_engineering_profiles())
with check (private.can_manage_engineering_profiles());

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'engineering_documents',
    'engineering_document_revisions',
    'engineering_annotations',
    'engineering_analysis_jobs',
    'engineering_findings',
    'engineering_deliveries',
    'engineering_delivery_documents'
  ]
  loop
    execute format(
      'drop policy if exists %I_select on public.%I',
      table_name,
      table_name
    );
    execute format(
      'drop policy if exists %I_insert on public.%I',
      table_name,
      table_name
    );
    execute format(
      'drop policy if exists %I_update on public.%I',
      table_name,
      table_name
    );
    execute format(
      'drop policy if exists %I_delete on public.%I',
      table_name,
      table_name
    );
    execute format(
      'create policy %I_select on public.%I for select to authenticated
       using (private.can_access_engineering_project("projectId"::text))',
      table_name,
      table_name
    );
    execute format(
      'create policy %I_insert on public.%I for insert to authenticated
       with check (private.can_access_engineering_project("projectId"::text))',
      table_name,
      table_name
    );
    execute format(
      'create policy %I_update on public.%I for update to authenticated
       using (private.can_access_engineering_project("projectId"::text))
       with check (private.can_access_engineering_project("projectId"::text))',
      table_name,
      table_name
    );
    execute format(
      'create policy %I_delete on public.%I for delete to authenticated
       using (private.can_access_engineering_project("projectId"::text))',
      table_name,
      table_name
    );
  end loop;
end
$$;

drop policy if exists engineering_audit_select
  on public.engineering_audit_events;
create policy engineering_audit_select
on public.engineering_audit_events
for select to authenticated
using (
  "projectId" is not null
  and private.can_access_engineering_project("projectId"::text)
);

revoke all on public.engineering_user_profiles from anon;
revoke all on public.engineering_documents from anon;
revoke all on public.engineering_document_revisions from anon;
revoke all on public.engineering_annotations from anon;
revoke all on public.engineering_analysis_jobs from anon;
revoke all on public.engineering_findings from anon;
revoke all on public.engineering_deliveries from anon;
revoke all on public.engineering_delivery_documents from anon;
revoke all on public.engineering_audit_events from anon;

grant select, insert, update, delete on public.engineering_user_profiles
  to authenticated;
grant select, insert, update, delete on public.engineering_documents
  to authenticated;
grant select, insert, update, delete on public.engineering_document_revisions
  to authenticated;
grant select, insert, update, delete on public.engineering_annotations
  to authenticated;
grant select, insert, update, delete on public.engineering_analysis_jobs
  to authenticated;
grant select, insert, update, delete on public.engineering_findings
  to authenticated;
grant select, insert, update, delete on public.engineering_deliveries
  to authenticated;
grant select, insert, update, delete on public.engineering_delivery_documents
  to authenticated;
grant select on public.engineering_audit_events to authenticated;

grant all on public.engineering_user_profiles to service_role;
grant all on public.engineering_documents to service_role;
grant all on public.engineering_document_revisions to service_role;
grant all on public.engineering_annotations to service_role;
grant all on public.engineering_analysis_jobs to service_role;
grant all on public.engineering_findings to service_role;
grant all on public.engineering_deliveries to service_role;
grant all on public.engineering_delivery_documents to service_role;
grant all on public.engineering_audit_events to service_role;

create or replace view public.engineering_project_workspace
with (security_invoker = true)
as
select
  project.id,
  project.name,
  project.client,
  project.description,
  project.status,
  project."startDate",
  project."endDate",
  project.location,
  project.tags,
  project."teamSize",
  project."imageUrl",
  project."coordinatorId",
  project."coordinatorName",
  project."updatedAt",
  case
    when private.can_read_engineering_financials() then project.budget
    else null
  end as budget,
  case
    when private.can_read_engineering_financials() then project."currentCost"
    else null
  end as "currentCost"
from public.projects project
where private.can_access_engineering_project(project.id::text);

revoke all on public.engineering_project_workspace from public, anon;
grant select on public.engineering_project_workspace to authenticated;

create or replace view public.engineering_material_requisitions
with (security_invoker = true)
as
select
  requisition.id,
  requisition."projectId",
  requisition."projectName",
  requisition."requesterName",
  requisition."requesterId",
  requisition."requestDate",
  requisition.status,
  requisition.priority,
  requisition."rejectionReason",
  requisition."purchaseId",
  requisition."createdAt",
  case
    when private.can_read_engineering_financials() then requisition.items
    else (
      select coalesce(
        jsonb_agg(
          item
          - 'estimatedUnitPrice'
          - 'unitPrice'
          - 'price'
          - 'total'
          - 'estimatedTotal'
        ),
        '[]'::jsonb
      )
      from jsonb_array_elements(requisition.items) item
    )
  end as items
from public.material_requisitions requisition
where requisition."projectId" is not null
  and private.can_access_engineering_project(requisition."projectId"::text);

revoke all on public.engineering_material_requisitions from public, anon;
grant select on public.engineering_material_requisitions to authenticated;

insert into storage.buckets (id, name, public)
values
  ('engineering-documents', 'engineering-documents', false),
  ('engineering-derived', 'engineering-derived', false)
on conflict (id) do update set public = false;

drop policy if exists engineering_storage_select on storage.objects;
drop policy if exists engineering_storage_insert on storage.objects;
drop policy if exists engineering_storage_update on storage.objects;
drop policy if exists engineering_storage_delete on storage.objects;

create policy engineering_storage_select
on storage.objects
for select to authenticated
using (
  bucket_id in ('engineering-documents', 'engineering-derived')
  and private.can_access_engineering_project(
    (storage.foldername(name))[1]
  )
);

create policy engineering_storage_insert
on storage.objects
for insert to authenticated
with check (
  bucket_id in ('engineering-documents', 'engineering-derived')
  and private.can_access_engineering_project(
    (storage.foldername(name))[1]
  )
);

create policy engineering_storage_update
on storage.objects
for update to authenticated
using (
  bucket_id in ('engineering-documents', 'engineering-derived')
  and private.can_access_engineering_project(
    (storage.foldername(name))[1]
  )
)
with check (
  bucket_id in ('engineering-documents', 'engineering-derived')
  and private.can_access_engineering_project(
    (storage.foldername(name))[1]
  )
);

create policy engineering_storage_delete
on storage.objects
for delete to authenticated
using (
  bucket_id in ('engineering-documents', 'engineering-derived')
  and private.can_access_engineering_project(
    (storage.foldername(name))[1]
  )
);

do $$
begin
  alter publication supabase_realtime
    add table public.engineering_documents;
exception
  when duplicate_object then null;
end
$$;

do $$
begin
  alter publication supabase_realtime
    add table public.engineering_document_revisions;
exception
  when duplicate_object then null;
end
$$;

do $$
begin
  alter publication supabase_realtime
    add table public.engineering_analysis_jobs;
exception
  when duplicate_object then null;
end
$$;

do $$
begin
  alter publication supabase_realtime
    add table public.engineering_findings;
exception
  when duplicate_object then null;
end
$$;
