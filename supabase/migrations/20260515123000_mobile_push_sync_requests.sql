-- Usa push notification tambem como sinal de sincronizacao do mobile.
-- Alem do alerta visual, o payload passa a dizer ao app quais caches devem
-- ser invalidados quando permissoes, cargo, equipes ou obras mudarem no ERP.

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
      'system'
    )
  );

create or replace function private.notify_project_coordinator_assignment()
returns trigger
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_old_coordinator_id text;
  v_new_coordinator_id text := nullif(new."coordinatorId", '');
  v_project_name text := coalesce(nullif(new.name, ''), 'obra');
begin
  if tg_op = 'UPDATE' then
    v_old_coordinator_id := nullif(old."coordinatorId", '');

    if v_old_coordinator_id is not null
      and v_old_coordinator_id is distinct from v_new_coordinator_id then
      perform private.enqueue_mobile_push_notification(
        null,
        v_old_coordinator_id,
        'Obra removida da sua coordenacao',
        'Voce deixou de ser responsavel por ' || v_project_name || '.',
        'project',
        'projects',
        jsonb_build_object(
          'sync', true,
          'syncReason', 'project_coordinator_removed',
          'syncTargets', jsonb_build_array('auth', 'workspace', 'projects', 'teams'),
          'projectId', new.id,
          'projectName', new.name,
          'coordinatorId', v_old_coordinator_id
        ),
        'high'
      );
    end if;
  end if;

  if v_new_coordinator_id is not null
    and (
      tg_op = 'INSERT'
      or v_new_coordinator_id is distinct from v_old_coordinator_id
    ) then
    perform private.enqueue_mobile_push_notification(
      null,
      v_new_coordinator_id,
      'Obra atribuida',
      'Voce foi definido como responsavel por ' || v_project_name || '.',
      'project',
      'projects',
      jsonb_build_object(
        'sync', true,
        'syncReason', 'project_coordinator_assigned',
        'syncTargets', jsonb_build_array('auth', 'workspace', 'projects', 'teams'),
        'projectId', new.id,
        'projectName', new.name,
        'coordinatorId', v_new_coordinator_id
      ),
      'high'
    );
  end if;

  return new;
end;
$$;

drop trigger if exists trg_notify_project_coordinator_assignment
  on public.projects;
create trigger trg_notify_project_coordinator_assignment
after insert or update of "coordinatorId"
on public.projects
for each row execute function private.notify_project_coordinator_assignment();

create or replace function private.notify_mobile_user_access_sync()
returns trigger
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_employee_id text := coalesce(
    nullif(new.employee_id, ''),
    nullif(new."employeeId", '')
  );
  v_title text := 'Acesso atualizado';
  v_body text := 'Suas permissoes no Granith foram atualizadas.';
begin
  if tg_op <> 'UPDATE' then
    return new;
  end if;

  if new.role is not distinct from old.role
    and new.permissions is not distinct from old.permissions
    and new.status is not distinct from old.status
    and new."employeeId" is not distinct from old."employeeId"
    and new.employee_id is not distinct from old.employee_id
    and new."employeeName" is not distinct from old."employeeName"
    and new.employee_name is not distinct from old.employee_name
    and new."displayName" is not distinct from old."displayName"
    and new.display_name is not distinct from old.display_name
    and new.email is not distinct from old.email then
    return new;
  end if;

  if new.status is distinct from old.status then
    v_title := 'Status de acesso atualizado';
    v_body := 'Seu status de acesso agora e ' || coalesce(new.status, 'atualizado') || '.';
  elsif new."employeeId" is distinct from old."employeeId"
    or new.employee_id is distinct from old.employee_id then
    v_title := 'Vinculo de funcionario atualizado';
    v_body := 'Seu login foi vinculado a outro cadastro de funcionario.';
  elsif new.role is distinct from old.role
    or new.permissions is distinct from old.permissions then
    v_title := 'Permissoes atualizadas';
    v_body := 'Seu perfil de acesso mudou. O app vai sincronizar os modulos liberados.';
  end if;

  perform private.enqueue_mobile_push_notification(
    new.id,
    v_employee_id,
    v_title,
    v_body,
    'sync',
    'sync',
    jsonb_build_object(
      'sync', true,
      'syncReason', 'user_access_changed',
      'syncTargets', jsonb_build_array('auth', 'workspace', 'permissions', 'profile'),
      'userId', new.id,
      'employeeId', v_employee_id,
      'role', new.role,
      'status', new.status
    ),
    'high'
  );

  return new;
end;
$$;

drop trigger if exists trg_notify_mobile_user_access_sync
  on public.users;
create trigger trg_notify_mobile_user_access_sync
after update of
  role,
  permissions,
  status,
  "employeeId",
  employee_id,
  "employeeName",
  employee_name,
  "displayName",
  display_name,
  email
on public.users
for each row execute function private.notify_mobile_user_access_sync();

create or replace function private.notify_mobile_employee_profile_sync()
returns trigger
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_user_id text;
  v_title text := 'Cadastro atualizado';
  v_body text := 'Seus dados de funcionario foram atualizados no ERP.';
begin
  if tg_op <> 'UPDATE' then
    return new;
  end if;

  if new.name is not distinct from old.name
    and new.email is not distinct from old.email
    and new.role is not distinct from old.role
    and new.sector is not distinct from old.sector
    and new.status is not distinct from old.status
    and new."jobRoleId" is not distinct from old."jobRoleId" then
    return new;
  end if;

  v_user_id := private.mobile_notification_user_id_for_employee(new.id);
  if v_user_id is null then
    return new;
  end if;

  if new.role is distinct from old.role
    or new."jobRoleId" is distinct from old."jobRoleId"
    or new.sector is distinct from old.sector then
    v_title := 'Cargo atualizado';
    v_body := 'Seu cargo, setor ou nivel operacional foi atualizado no ERP.';
  elsif new.status is distinct from old.status then
    v_title := 'Status de funcionario atualizado';
    v_body := 'Seu status de funcionario agora e ' || coalesce(new.status, 'atualizado') || '.';
  end if;

  perform private.enqueue_mobile_push_notification(
    v_user_id,
    new.id,
    v_title,
    v_body,
    'sync',
    'sync',
    jsonb_build_object(
      'sync', true,
      'syncReason', 'employee_profile_changed',
      'syncTargets', jsonb_build_array('auth', 'workspace', 'profile', 'permissions'),
      'employeeId', new.id,
      'employeeName', new.name,
      'employeeRole', new.role,
      'employeeStatus', new.status
    ),
    'high'
  );

  return new;
end;
$$;

drop trigger if exists trg_notify_mobile_employee_profile_sync
  on public.employees;
create trigger trg_notify_mobile_employee_profile_sync
after update of
  name,
  email,
  role,
  sector,
  status,
  "jobRoleId"
on public.employees
for each row execute function private.notify_mobile_employee_profile_sync();
