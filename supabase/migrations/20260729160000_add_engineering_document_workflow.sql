-- Granith Engenharia P1: technical document governance.
-- Original revisions are append-only. Workflow changes must use the RPCs below.

alter table public.engineering_documents
  add column if not exists "requiresDigitalSignature" boolean not null default false;

alter table public.engineering_document_revisions
  drop constraint if exists engineering_revisions_status_check;

alter table public.engineering_document_revisions
  add constraint engineering_revisions_status_check check (
    status in (
      'draft',
      'underReview',
      'approved',
      'rejected',
      'revisionRequested',
      'superseded'
    )
  );

create table if not exists public.engineering_document_review_events (
  id bigint generated always as identity primary key,
  "projectId" text not null references public.projects(id) on delete cascade,
  "documentId" text not null
    references public.engineering_documents(id) on delete cascade,
  "documentRevisionId" text not null
    references public.engineering_document_revisions(id) on delete restrict,
  decision text not null,
  comment text not null default '',
  "actorUserId" text not null default '',
  "createdAt" timestamptz not null default now(),
  constraint engineering_review_events_decision_check check (
    decision in (
      'submitted',
      'approved',
      'rejected',
      'revisionRequested',
      'published',
      'unpublished',
      'signatureRequested',
      'signatureCompleted',
      'signatureFailed'
    )
  )
);

create table if not exists public.engineering_signature_requests (
  id text primary key default gen_random_uuid()::text,
  "projectId" text not null references public.projects(id) on delete cascade,
  "documentId" text not null
    references public.engineering_documents(id) on delete cascade,
  "documentRevisionId" text not null
    references public.engineering_document_revisions(id) on delete restrict,
  provider text not null default 'external',
  policy text not null default 'PAdES-AD-RB',
  "policyOid" text not null default '2.16.76.1.7.1.11.1.3',
  status text not null default 'queued',
  "providerRequestId" text,
  "signedFilePath" text,
  "signedSha256" text,
  "certificateSubject" text,
  "certificateSerial" text,
  "certificateIssuer" text,
  "certificateValidFrom" timestamptz,
  "certificateValidTo" timestamptz,
  "requestedByUserId" text not null default '',
  "requestedAt" timestamptz not null default now(),
  "completedAt" timestamptz,
  "errorCode" text,
  "errorMessage" text,
  "updatedAt" timestamptz not null default now(),
  constraint engineering_signature_policy_check check (
    policy in ('PAdES-AD-RB', 'PAdES-AD-RT')
  ),
  constraint engineering_signature_status_check check (
    status in (
      'queued',
      'awaitingProvider',
      'processing',
      'completed',
      'failed',
      'cancelled'
    )
  ),
  constraint engineering_signature_completed_fields_check check (
    status <> 'completed'
    or (
      nullif("signedFilePath", '') is not null
      and nullif("signedSha256", '') is not null
      and "completedAt" is not null
    )
  )
);

create table if not exists public.engineering_client_document_publications (
  id text primary key default gen_random_uuid()::text,
  "projectId" text not null references public.projects(id) on delete cascade,
  "documentId" text not null
    references public.engineering_documents(id) on delete cascade,
  "documentRevisionId" text not null
    references public.engineering_document_revisions(id) on delete restrict,
  title text not null,
  notes text not null default '',
  "publishedByUserId" text not null default '',
  "publishedAt" timestamptz not null default now(),
  "revokedByUserId" text,
  "revokedAt" timestamptz
);

create unique index if not exists
  idx_engineering_publication_active_revision
on public.engineering_client_document_publications ("documentRevisionId")
where "revokedAt" is null;

create index if not exists idx_engineering_review_events_revision
  on public.engineering_document_review_events (
    "documentRevisionId",
    "createdAt" desc
  );

create index if not exists idx_engineering_signature_revision
  on public.engineering_signature_requests (
    "documentRevisionId",
    "requestedAt" desc
  );

create index if not exists idx_engineering_publications_project
  on public.engineering_client_document_publications (
    "projectId",
    "publishedAt" desc
  )
  where "revokedAt" is null;

create or replace function private.guard_engineering_revision_immutability()
returns trigger
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
begin
  if auth.role() = 'service_role'
    or (select auth.uid()) is null
    or current_setting('granith.engineering_document_workflow', true) = 'on'
  then
    return case when tg_op = 'DELETE' then old else new end;
  end if;

  raise exception
    using
      errcode = '42501',
      message = 'Revisoes tecnicas sao imutaveis; use o workflow documental.';
end;
$$;

revoke all on function private.guard_engineering_revision_immutability()
  from public, anon, authenticated;

drop trigger if exists guard_engineering_revision_immutability
  on public.engineering_document_revisions;
create trigger guard_engineering_revision_immutability
before update or delete on public.engineering_document_revisions
for each row execute function private.guard_engineering_revision_immutability();

create or replace function private.prepare_engineering_revision_insert()
returns trigger
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  expected_project_id text;
begin
  select document."projectId"
  into expected_project_id
  from public.engineering_documents document
  where document.id = new."documentId";

  if expected_project_id is null or expected_project_id <> new."projectId" then
    raise exception
      using
        errcode = '23514',
        message = 'A revisao deve pertencer a mesma obra do documento.';
  end if;

  if auth.role() = 'authenticated' then
    new.status := 'draft';
    new."reviewedByUserId" := null;
    new."reviewedAt" := null;
  end if;

  new."updatedAt" := clock_timestamp();
  return new;
end;
$$;

revoke all on function private.prepare_engineering_revision_insert()
  from public, anon, authenticated;

drop trigger if exists validate_engineering_revision_insert
  on public.engineering_document_revisions;
create trigger validate_engineering_revision_insert
before insert on public.engineering_document_revisions
for each row execute function private.prepare_engineering_revision_insert();

create or replace function private.sync_engineering_current_revision()
returns trigger
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
begin
  update public.engineering_documents
  set
    "currentRevisionId" = new.id,
    "updatedAt" = clock_timestamp()
  where id = new."documentId";
  return new;
end;
$$;

revoke all on function private.sync_engineering_current_revision()
  from public, anon, authenticated;

drop trigger if exists sync_engineering_current_revision
  on public.engineering_document_revisions;
create trigger sync_engineering_current_revision
after insert on public.engineering_document_revisions
for each row execute function private.sync_engineering_current_revision();

create or replace function private.record_engineering_review_event(
  revision public.engineering_document_revisions,
  event_decision text,
  event_comment text default ''
)
returns void
language sql
security definer
set search_path = public, private, pg_temp
as $$
  insert into public.engineering_document_review_events (
    "projectId",
    "documentId",
    "documentRevisionId",
    decision,
    comment,
    "actorUserId"
  )
  values (
    revision."projectId",
    revision."documentId",
    revision.id,
    event_decision,
    coalesce(event_comment, ''),
    coalesce((select auth.uid())::text, 'system')
  );
$$;

revoke all on function private.record_engineering_review_event(
  public.engineering_document_revisions,
  text,
  text
) from public, anon, authenticated;

create or replace function public.submit_engineering_revision(
  revision_id text,
  review_comment text default ''
)
returns public.engineering_document_revisions
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  revision public.engineering_document_revisions;
begin
  select *
  into revision
  from public.engineering_document_revisions
  where id = nullif(trim(revision_id), '')
  for update;

  if revision.id is null
    or not private.can_access_engineering_project(revision."projectId")
  then
    raise exception using errcode = '42501', message = 'Revisao indisponivel.';
  end if;

  if revision.status <> 'draft' then
    raise exception
      using
        errcode = '23514',
        message = 'Somente uma nova revisao em rascunho pode ser enviada para analise.';
  end if;

  perform set_config('granith.engineering_document_workflow', 'on', true);
  update public.engineering_document_revisions
  set
    status = 'underReview',
    "reviewedByUserId" = null,
    "reviewedAt" = null,
    "updatedAt" = clock_timestamp()
  where id = revision.id
  returning * into revision;

  perform private.record_engineering_review_event(
    revision,
    'submitted',
    review_comment
  );
  return revision;
end;
$$;

create or replace function public.review_engineering_revision(
  revision_id text,
  decision text,
  review_comment text default ''
)
returns public.engineering_document_revisions
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  revision public.engineering_document_revisions;
  normalized_decision text := nullif(trim(decision), '');
begin
  if normalized_decision not in ('approved', 'rejected', 'revisionRequested') then
    raise exception
      using errcode = '22023', message = 'Decisao documental invalida.';
  end if;

  select *
  into revision
  from public.engineering_document_revisions
  where id = nullif(trim(revision_id), '')
  for update;

  if revision.id is null
    or not private.can_access_engineering_project(revision."projectId")
  then
    raise exception using errcode = '42501', message = 'Revisao indisponivel.';
  end if;

  if revision.status <> 'underReview' then
    raise exception
      using
        errcode = '23514',
        message = 'A revisao precisa estar em analise para receber uma decisao.';
  end if;

  if normalized_decision <> 'approved'
    and nullif(trim(review_comment), '') is null
  then
    raise exception
      using
        errcode = '22023',
        message = 'Informe o motivo da rejeicao ou da solicitacao de revisao.';
  end if;

  perform set_config('granith.engineering_document_workflow', 'on', true);

  if normalized_decision = 'approved' then
    update public.engineering_document_revisions
    set
      status = 'superseded',
      "updatedAt" = clock_timestamp()
    where "documentId" = revision."documentId"
      and id <> revision.id
      and status = 'approved';
  end if;

  update public.engineering_document_revisions
  set
    status = normalized_decision,
    "reviewedByUserId" = (select auth.uid())::text,
    "reviewedAt" = clock_timestamp(),
    "updatedAt" = clock_timestamp()
  where id = revision.id
  returning * into revision;

  perform private.record_engineering_review_event(
    revision,
    normalized_decision,
    review_comment
  );
  return revision;
end;
$$;

create or replace function public.request_engineering_signature(
  revision_id text,
  signature_policy text default 'PAdES-AD-RB',
  signature_provider text default 'external'
)
returns text
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  revision public.engineering_document_revisions;
  request_id text;
  normalized_policy text := nullif(trim(signature_policy), '');
begin
  if normalized_policy not in ('PAdES-AD-RB', 'PAdES-AD-RT') then
    raise exception
      using errcode = '22023', message = 'Politica PAdES invalida.';
  end if;

  select *
  into revision
  from public.engineering_document_revisions
  where id = nullif(trim(revision_id), '');

  if revision.id is null
    or not private.can_access_engineering_project(revision."projectId")
  then
    raise exception using errcode = '42501', message = 'Revisao indisponivel.';
  end if;

  if revision.status <> 'approved' then
    raise exception
      using errcode = '23514', message = 'Apenas revisoes aprovadas podem ser assinadas.';
  end if;

  select request.id
  into request_id
  from public.engineering_signature_requests request
  where request."documentRevisionId" = revision.id
    and request.status in ('queued', 'awaitingProvider', 'processing', 'completed')
  order by request."requestedAt" desc
  limit 1;

  if request_id is not null then
    return request_id;
  end if;

  insert into public.engineering_signature_requests (
    "projectId",
    "documentId",
    "documentRevisionId",
    provider,
    policy,
    "policyOid",
    "requestedByUserId"
  )
  values (
    revision."projectId",
    revision."documentId",
    revision.id,
    coalesce(nullif(trim(signature_provider), ''), 'external'),
    normalized_policy,
    case
      when normalized_policy = 'PAdES-AD-RB'
        then '2.16.76.1.7.1.11.1.3'
      else '2.16.76.1.7.1.12.1.3'
    end,
    (select auth.uid())::text
  )
  returning id into request_id;

  perform private.record_engineering_review_event(
    revision,
    'signatureRequested',
    normalized_policy
  );
  return request_id;
end;
$$;

create or replace function public.publish_engineering_revision(
  revision_id text,
  publication_notes text default ''
)
returns text
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  revision public.engineering_document_revisions;
  document public.engineering_documents;
  publication_id text;
begin
  select *
  into revision
  from public.engineering_document_revisions
  where id = nullif(trim(revision_id), '');

  if revision.id is null
    or not private.can_access_engineering_project(revision."projectId")
  then
    raise exception using errcode = '42501', message = 'Revisao indisponivel.';
  end if;

  if revision.status <> 'approved' then
    raise exception
      using errcode = '23514', message = 'Apenas revisoes aprovadas podem ser publicadas.';
  end if;

  select *
  into document
  from public.engineering_documents
  where id = revision."documentId";

  if document."requiresDigitalSignature"
    and not exists (
      select 1
      from public.engineering_signature_requests signature
      where signature."documentRevisionId" = revision.id
        and signature.status = 'completed'
    )
  then
    raise exception
      using
        errcode = '23514',
        message = 'Conclua a assinatura PAdES antes de publicar este documento.';
  end if;

  select publication.id
  into publication_id
  from public.engineering_client_document_publications publication
  where publication."documentRevisionId" = revision.id
    and publication."revokedAt" is null
  limit 1;

  if publication_id is null then
    insert into public.engineering_client_document_publications (
      "projectId",
      "documentId",
      "documentRevisionId",
      title,
      notes,
      "publishedByUserId"
    )
    values (
      revision."projectId",
      revision."documentId",
      revision.id,
      document.title,
      coalesce(publication_notes, ''),
      (select auth.uid())::text
    )
    returning id into publication_id;

    perform private.record_engineering_review_event(
      revision,
      'published',
      publication_notes
    );
  end if;

  return publication_id;
end;
$$;

create or replace function public.unpublish_engineering_revision(
  publication_id text,
  revocation_reason text default ''
)
returns boolean
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  publication public.engineering_client_document_publications;
  revision public.engineering_document_revisions;
begin
  select *
  into publication
  from public.engineering_client_document_publications
  where id = nullif(trim(publication_id), '')
    and "revokedAt" is null
  for update;

  if publication.id is null
    or not private.can_access_engineering_project(publication."projectId")
  then
    raise exception using errcode = '42501', message = 'Publicacao indisponivel.';
  end if;

  update public.engineering_client_document_publications
  set
    "revokedAt" = clock_timestamp(),
    "revokedByUserId" = (select auth.uid())::text
  where id = publication.id;

  select *
  into revision
  from public.engineering_document_revisions
  where id = publication."documentRevisionId";

  perform private.record_engineering_review_event(
    revision,
    'unpublished',
    revocation_reason
  );
  return true;
end;
$$;

revoke all on function public.submit_engineering_revision(text, text)
  from public, anon;
revoke all on function public.review_engineering_revision(text, text, text)
  from public, anon;
revoke all on function public.request_engineering_signature(text, text, text)
  from public, anon;
revoke all on function public.publish_engineering_revision(text, text)
  from public, anon;
revoke all on function public.unpublish_engineering_revision(text, text)
  from public, anon;

grant execute on function public.submit_engineering_revision(text, text)
  to authenticated;
grant execute on function public.review_engineering_revision(text, text, text)
  to authenticated;
grant execute on function public.request_engineering_signature(text, text, text)
  to authenticated;
grant execute on function public.publish_engineering_revision(text, text)
  to authenticated;
grant execute on function public.unpublish_engineering_revision(text, text)
  to authenticated;

alter table public.engineering_document_review_events enable row level security;
alter table public.engineering_document_review_events force row level security;
alter table public.engineering_signature_requests enable row level security;
alter table public.engineering_signature_requests force row level security;
alter table public.engineering_client_document_publications enable row level security;
alter table public.engineering_client_document_publications force row level security;

drop policy if exists engineering_review_events_select
  on public.engineering_document_review_events;
create policy engineering_review_events_select
on public.engineering_document_review_events
for select to authenticated
using (private.can_access_engineering_project("projectId"));

drop policy if exists engineering_signature_requests_select
  on public.engineering_signature_requests;
create policy engineering_signature_requests_select
on public.engineering_signature_requests
for select to authenticated
using (private.can_access_engineering_project("projectId"));

drop policy if exists engineering_publications_select
  on public.engineering_client_document_publications;
create policy engineering_publications_select
on public.engineering_client_document_publications
for select to authenticated
using (
  private.can_access_engineering_project("projectId")
  or private.client_can_access_project("projectId")
);

drop policy if exists engineering_document_revisions_update
  on public.engineering_document_revisions;
drop policy if exists engineering_document_revisions_delete
  on public.engineering_document_revisions;
revoke update, delete on public.engineering_document_revisions
  from authenticated;

revoke all on public.engineering_document_review_events from public, anon;
revoke all on public.engineering_signature_requests from public, anon;
revoke all on public.engineering_client_document_publications from public, anon;
grant select on public.engineering_document_review_events to authenticated;
grant select on public.engineering_signature_requests to authenticated;
grant select on public.engineering_client_document_publications to authenticated;
grant all on public.engineering_document_review_events to service_role;
grant all on public.engineering_signature_requests to service_role;
grant all on public.engineering_client_document_publications to service_role;

create or replace view public.client_portal_engineering_documents
with (security_barrier = true)
as
select
  publication.id as "publicationId",
  publication."projectId",
  publication."documentId",
  publication."documentRevisionId",
  publication.title,
  document.discipline,
  document."documentType",
  revision."revisionCode",
  revision."originalFileName",
  revision."mimeType",
  revision."sizeBytes",
  revision.sha256,
  revision."pageCount",
  coalesce(signature."signedFilePath", revision."filePath") as "filePath",
  case
    when signature."signedFilePath" is not null then 'engineering-derived'
    else 'engineering-documents'
  end as bucket,
  signature."signedFilePath" is not null as "digitallySigned",
  signature.policy as "signaturePolicy",
  signature."certificateSubject",
  publication.notes,
  publication."publishedAt"
from public.engineering_client_document_publications publication
join public.engineering_documents document
  on document.id = publication."documentId"
join public.engineering_document_revisions revision
  on revision.id = publication."documentRevisionId"
left join lateral (
  select request.*
  from public.engineering_signature_requests request
  where request."documentRevisionId" = revision.id
    and request.status = 'completed'
  order by request."completedAt" desc
  limit 1
) signature on true
where publication."revokedAt" is null
  and revision.status = 'approved'
  and private.client_can_access_project(publication."projectId");

revoke all on public.client_portal_engineering_documents from public, anon;
grant select on public.client_portal_engineering_documents to authenticated;

drop policy if exists engineering_storage_select on storage.objects;
create policy engineering_storage_select
on storage.objects
for select to authenticated
using (
  bucket_id in ('engineering-documents', 'engineering-derived')
  and (
    private.can_access_engineering_project((storage.foldername(name))[1])
    or exists (
      select 1
      from public.engineering_client_document_publications publication
      join public.engineering_document_revisions revision
        on revision.id = publication."documentRevisionId"
      where publication."revokedAt" is null
        and revision.status = 'approved'
        and publication."projectId" = (storage.foldername(name))[1]
        and private.client_can_access_project(publication."projectId")
        and (
          (
            storage.objects.bucket_id = 'engineering-documents'
            and revision."filePath" = storage.objects.name
          )
          or (
            storage.objects.bucket_id = 'engineering-derived'
            and exists (
              select 1
              from public.engineering_signature_requests signature
              where signature."documentRevisionId" = revision.id
                and signature.status = 'completed'
                and signature."signedFilePath" = storage.objects.name
            )
          )
        )
    )
  )
);

drop policy if exists engineering_storage_update on storage.objects;
drop policy if exists engineering_storage_immutable_update on storage.objects;
create policy engineering_storage_immutable_update
on storage.objects
as restrictive
for update to authenticated
using (bucket_id not in ('engineering-documents', 'engineering-derived'))
with check (bucket_id not in ('engineering-documents', 'engineering-derived'));

drop policy if exists engineering_storage_delete on storage.objects;
create policy engineering_storage_delete
on storage.objects
for delete to authenticated
using (
  bucket_id in ('engineering-documents', 'engineering-derived')
  and private.can_access_engineering_project((storage.foldername(name))[1])
  and not exists (
    select 1
    from public.engineering_document_revisions revision
    where revision."filePath" = storage.objects.name
  )
  and not exists (
    select 1
    from public.engineering_signature_requests signature
    where signature."signedFilePath" = storage.objects.name
  )
);

drop policy if exists engineering_storage_immutable_delete on storage.objects;
create policy engineering_storage_immutable_delete
on storage.objects
as restrictive
for delete to authenticated
using (
  bucket_id not in ('engineering-documents', 'engineering-derived')
  or (
    private.can_access_engineering_project((storage.foldername(name))[1])
    and not exists (
      select 1
      from public.engineering_document_revisions revision
      where revision."filePath" = storage.objects.name
    )
    and not exists (
      select 1
      from public.engineering_signature_requests signature
      where signature."signedFilePath" = storage.objects.name
    )
  )
);

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'engineering_document_review_events',
    'engineering_signature_requests',
    'engineering_client_document_publications'
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
    add table public.engineering_annotations;
exception
  when duplicate_object then null;
end
$$;

do $$
begin
  alter publication supabase_realtime
    add table public.engineering_document_review_events;
exception
  when duplicate_object then null;
end
$$;

do $$
begin
  alter publication supabase_realtime
    add table public.engineering_signature_requests;
exception
  when duplicate_object then null;
end
$$;

do $$
begin
  alter publication supabase_realtime
    add table public.engineering_client_document_publications;
exception
  when duplicate_object then null;
end
$$;
