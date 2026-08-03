begin;

select plan(11);

insert into public.users (id, email, role, permissions)
values
  (
    '20000000-0000-0000-0000-000000000001',
    'engineering-worker@granith.test',
    'employee',
    array['projects.read']
  ),
  (
    '20000000-0000-0000-0000-000000000002',
    'engineering-admin@granith.test',
    'employee',
    array['projects.read']
  );

insert into public.employees (id, name, email, role, status)
values
  (
    'engineering-employee-worker',
    'Engineering Worker',
    'engineering-worker@granith.test',
    'funcionario',
    'ativo'
  ),
  (
    'engineering-employee-admin',
    'Engineering Administrator',
    'engineering-admin@granith.test',
    'coordenador',
    'ativo'
  );

insert into public.engineering_user_profiles (
  "userId",
  "employeeId",
  role,
  "isActive"
)
values
  (
    '20000000-0000-0000-0000-000000000001',
    'engineering-employee-worker',
    'engineer',
    true
  ),
  (
    '20000000-0000-0000-0000-000000000002',
    'engineering-employee-admin',
    'administrator',
    true
  );

insert into public.projects (
  id,
  name,
  client,
  status,
  "projectKey",
  "startDate",
  budget,
  "coordinatorId"
)
values (
  'engineering-project-p0',
  'Engineering P0 Project',
  'Engineering Client',
  'planning',
  'engineering_project_p0',
  now(),
  150000,
  'engineering-employee-worker'
);

insert into public.material_requisitions (
  id,
  "projectId",
  "projectName",
  "requesterName",
  "requesterId",
  status,
  items
)
values (
  'engineering-requisition-p0',
  'engineering-project-p0',
  'Engineering P0 Project',
  'Engineering Worker',
  'engineering-employee-worker',
  'pending',
  '[{"itemName":"Cabo","quantity":10,"unit":"m","estimatedUnitPrice":25}]'
);

select is(
  (select public from storage.buckets where id = 'engineering-documents'),
  false,
  'engineering document bucket is private'
);

set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"20000000-0000-0000-0000-000000000001","email":"engineering-worker@granith.test"}',
  true
);

select is(
  private.current_engineering_role(),
  'engineer',
  'worker resolves the engineer role'
);
select ok(
  private.can_access_engineering_project('engineering-project-p0'),
  'worker can access an assigned engineering project'
);
select is(
  (
    select "canViewFinancialValues"
    from public.get_current_engineering_profile()
  ),
  false,
  'worker profile denies financial values'
);
select is(
  (
    select budget
    from public.engineering_project_workspace
    where id = 'engineering-project-p0'
  ),
  null::numeric,
  'project budget is masked for worker'
);
select is(
  (
    select items -> 0 ? 'estimatedUnitPrice'
    from public.engineering_material_requisitions
    where id = 'engineering-requisition-p0'
  ),
  false,
  'requisition item price is removed for worker'
);
select is(
  private.can_manage_engineering_profiles(),
  false,
  'worker cannot manage engineering profiles'
);

select set_config(
  'request.jwt.claims',
  '{"sub":"20000000-0000-0000-0000-000000000002","email":"engineering-admin@granith.test"}',
  true
);

select is(
  private.current_engineering_role(),
  'administrator',
  'administrator resolves the engineering administrator role'
);
select ok(
  private.can_read_engineering_financials(),
  'engineering administrator can read financial values'
);
select is(
  (
    select budget
    from public.engineering_project_workspace
    where id = 'engineering-project-p0'
  ),
  150000::numeric,
  'project budget is visible to engineering administrator'
);
select is(
  (
    select items -> 0 ? 'estimatedUnitPrice'
    from public.engineering_material_requisitions
    where id = 'engineering-requisition-p0'
  ),
  true,
  'requisition item price remains visible to engineering administrator'
);
select is(
  (
    select role
    from public.get_current_engineering_profile()
  ),
  'administrator',
  'profile RPC returns the server-side administrator role'
);

select * from finish();
rollback;
