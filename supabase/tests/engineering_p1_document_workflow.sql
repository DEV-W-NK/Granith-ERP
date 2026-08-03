begin;

select plan(9);

insert into public.users (id, email, role, permissions)
values (
  '21000000-0000-0000-0000-000000000001',
  'engineering-p1@granith.test',
  'employee',
  array['projects.read']
);

insert into public.employees (id, name, email, role, status)
values (
  'engineering-employee-p1',
  'Engineering P1',
  'engineering-p1@granith.test',
  'coordenador',
  'ativo'
);

insert into public.engineering_user_profiles (
  "userId",
  "employeeId",
  role,
  "isActive"
)
values (
  '21000000-0000-0000-0000-000000000001',
  'engineering-employee-p1',
  'engineer',
  true
);

insert into public.projects (
  id,
  name,
  client,
  status,
  "projectKey",
  "startDate",
  "coordinatorId"
)
values (
  'engineering-project-p1',
  'Engineering P1 Project',
  'Engineering Client',
  'planning',
  'engineering_project_p1',
  now(),
  'engineering-employee-p1'
);

insert into public.engineering_documents (
  id,
  "projectId",
  title,
  "requiresDigitalSignature"
)
values
  (
    'engineering-document-p1',
    'engineering-project-p1',
    'Planta P1',
    false
  ),
  (
    'engineering-document-signed-p1',
    'engineering-project-p1',
    'Memorial assinado P1',
    true
  );

insert into public.engineering_document_revisions (
  id,
  "documentId",
  "projectId",
  "revisionCode",
  "filePath",
  "originalFileName",
  "sizeBytes",
  sha256
)
values
  (
    'engineering-revision-p1',
    'engineering-document-p1',
    'engineering-project-p1',
    'R00',
    'engineering-project-p1/engineering-document-p1/r00/planta.pdf',
    'planta.pdf',
    1024,
    repeat('a', 64)
  ),
  (
    'engineering-revision-signed-p1',
    'engineering-document-signed-p1',
    'engineering-project-p1',
    'R00',
    'engineering-project-p1/engineering-document-signed-p1/r00/memorial.pdf',
    'memorial.pdf',
    2048,
    repeat('b', 64)
  );

set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"21000000-0000-0000-0000-000000000001","email":"engineering-p1@granith.test"}',
  true
);

select throws_ok(
  $$
    update public.engineering_document_revisions
    set status = 'approved'
    where id = 'engineering-revision-p1'
  $$,
  '42501',
  null,
  'revision status cannot be changed directly'
);

select is(
  (
    select status
    from public.submit_engineering_revision('engineering-revision-p1', '')
  ),
  'underReview',
  'draft revision can be submitted'
);

select is(
  (
    select status
    from public.review_engineering_revision(
      'engineering-revision-p1',
      'approved',
      'Aprovada no teste P1'
    )
  ),
  'approved',
  'submitted revision can be approved'
);

select ok(
  nullif(
    public.publish_engineering_revision(
      'engineering-revision-p1',
      'Publicacao P1'
    ),
    ''
  ) is not null,
  'approved revision can be published'
);

select is(
  (
    select count(*)::integer
    from public.engineering_client_document_publications
    where "documentRevisionId" = 'engineering-revision-p1'
      and "revokedAt" is null
  ),
  1,
  'publication is active'
);

select is(
  (
    select status
    from public.submit_engineering_revision(
      'engineering-revision-signed-p1',
      ''
    )
  ),
  'underReview',
  'signature-required revision can be submitted'
);

select is(
  (
    select status
    from public.review_engineering_revision(
      'engineering-revision-signed-p1',
      'approved',
      ''
    )
  ),
  'approved',
  'signature-required revision can be approved'
);

select throws_ok(
  $$
    select public.publish_engineering_revision(
      'engineering-revision-signed-p1',
      ''
    )
  $$,
  '23514',
  null,
  'unsigned required revision cannot be published'
);

select ok(
  (
    select count(*) >= 3
    from public.engineering_document_review_events
    where "documentRevisionId" = 'engineering-revision-p1'
  ),
  'workflow decisions are recorded in the immutable ledger'
);

select * from finish();
rollback;
