begin;

select plan(13);

select is(
  (select public from storage.buckets where id = 'project-images'),
  false,
  'project-images bucket is private'
);

insert into public.users (id, email, role, permissions)
values
  (
    '10000000-0000-0000-0000-000000000001',
    'p0-reader@granith.test',
    'employee',
    array['projects.read']
  ),
  (
    '10000000-0000-0000-0000-000000000002',
    'p0-writer@granith.test',
    'employee',
    array['projects.read', 'projects.write']
  ),
  (
    '10000000-0000-0000-0000-000000000003',
    'p0-finance@granith.test',
    'employee',
    array['financial.read']
  ),
  (
    '10000000-0000-0000-0000-000000000004',
    'p0-admin@granith.test',
    'admin',
    '{}'::text[]
  );

insert into public.projects (
  id,
  name,
  client,
  status,
  "projectKey",
  "startDate"
)
values (
  'p0-project-existing',
  'P0 Existing Project',
  'P0 Client',
  'planning',
  'p0_existing_project',
  now()
);

set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"10000000-0000-0000-0000-000000000001","email":"p0-reader@granith.test"}',
  true
);

select ok(private.can_read_projects(), 'reader can read projects');
select is(private.can_write_projects(), false, 'reader cannot write projects');
select lives_ok(
  $$select id from public.projects where id = 'p0-project-existing'$$,
  'reader can query projects'
);
select throws_ok(
  $$
    insert into public.projects (
      id, name, client, status, "projectKey", "startDate"
    )
    values (
      'p0-project-denied',
      'Denied',
      'P0 Client',
      'planning',
      'p0_project_denied',
      now()
    )
  $$,
  '42501',
  null,
  'reader cannot insert projects'
);

select set_config(
  'request.jwt.claims',
  '{"sub":"10000000-0000-0000-0000-000000000002","email":"p0-writer@granith.test"}',
  true
);
select ok(private.can_write_projects(), 'writer can write projects');
select lives_ok(
  $$
    insert into public.projects (
      id, name, client, status, "projectKey", "startDate"
    )
    values (
      'p0-project-writer',
      'Writer Project',
      'P0 Client',
      'planning',
      'p0_project_writer',
      now()
    )
  $$,
  'writer can insert projects'
);
select throws_ok(
  $$delete from public.projects where id = 'p0-project-writer'$$,
  '42501',
  null,
  'physical deletion is blocked'
);
select is(
  public.archive_record('projects', 'p0-project-writer', 'p0 test'),
  true,
  'writer can archive a project'
);
select is(
  (select count(*)::integer from public.projects where id = 'p0-project-writer'),
  0,
  'archived rows are hidden by restrictive RLS'
);

select set_config(
  'request.jwt.claims',
  '{"sub":"10000000-0000-0000-0000-000000000003","email":"p0-finance@granith.test"}',
  true
);
select ok(private.can_read_financial(), 'finance can read financial records');
select is(
  (select count(*)::integer from public.purchases),
  0,
  'finance-only user cannot read purchases'
);

select set_config(
  'request.jwt.claims',
  '{"sub":"10000000-0000-0000-0000-000000000004","email":"p0-admin@granith.test"}',
  true
);
select ok(private.can_read_audit(), 'administrator can read the audit ledger');

select * from finish();
rollback;
