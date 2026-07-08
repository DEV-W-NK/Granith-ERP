-- Eventos operacionais que alimentam o outbox de push mobile.
-- O envio real para FCM deve ser feito por Edge Function/worker lendo
-- public.mobile_push_notifications com status = 'pending'.

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
      'system'
    )
  );

create or replace function private.mobile_notification_user_id_for_employee(
  p_employee_id text
)
returns text
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  with employee_row as (
    select e.id::text as id, lower(e.email) as email
    from public.employees e
    where e.id::text = nullif(p_employee_id, '')
    limit 1
  )
  select u.id::text
  from public.users u
  left join employee_row e on true
  where (
      nullif(u.employee_id, '') = e.id
      or nullif(u."employeeId", '') = e.id
      or (
        e.email is not null
        and lower(u.email) = e.email
      )
    )
    and coalesce(u.status, 'ativo') = 'ativo'
  order by
    case
      when nullif(u.employee_id, '') = e.id then 0
      when nullif(u."employeeId", '') = e.id then 1
      else 2
    end
  limit 1;
$$;

create or replace function private.enqueue_mobile_push_notification(
  p_recipient_user_id text default null,
  p_recipient_employee_id text default null,
  p_title text default '',
  p_body text default '',
  p_category text default 'system',
  p_action_route text default '',
  p_payload jsonb default '{}'::jsonb,
  p_priority text default 'normal'
)
returns text
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_recipient_user_id text := nullif(p_recipient_user_id, '');
  v_recipient_employee_id text := nullif(p_recipient_employee_id, '');
  v_notification_id text;
begin
  if nullif(trim(coalesce(p_title, '')), '') is null then
    return null;
  end if;

  if v_recipient_user_id is null and v_recipient_employee_id is not null then
    v_recipient_user_id :=
      private.mobile_notification_user_id_for_employee(v_recipient_employee_id);
  end if;

  if v_recipient_user_id is null and v_recipient_employee_id is null then
    return null;
  end if;

  insert into public.mobile_push_notifications (
    "recipientUserId",
    "recipientEmployeeId",
    title,
    body,
    category,
    "actionRoute",
    payload,
    priority,
    status,
    "createdByUserId"
  )
  values (
    v_recipient_user_id,
    v_recipient_employee_id,
    trim(p_title),
    coalesce(p_body, ''),
    coalesce(nullif(p_category, ''), 'system'),
    coalesce(p_action_route, ''),
    coalesce(p_payload, '{}'::jsonb),
    coalesce(nullif(p_priority, ''), 'normal'),
    'pending',
    case
      when (select auth.uid()) is null then null
      else (select auth.uid())::text
    end
  )
  returning id into v_notification_id;

  return v_notification_id;
end;
$$;

create or replace function private.enqueue_mobile_push_for_subject(
  p_subject_id text,
  p_title text,
  p_body text default '',
  p_category text default 'system',
  p_action_route text default '',
  p_payload jsonb default '{}'::jsonb,
  p_priority text default 'normal'
)
returns text
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_subject_id text := nullif(p_subject_id, '');
  v_user_id text;
  v_employee_id text;
begin
  if v_subject_id is null then
    return null;
  end if;

  select e.id::text
  into v_employee_id
  from public.employees e
  where e.id::text = v_subject_id
  limit 1;

  if v_employee_id is null then
    select u.id::text
    into v_user_id
    from public.users u
    where u.id::text = v_subject_id
    limit 1;
  end if;

  return private.enqueue_mobile_push_notification(
    v_user_id,
    v_employee_id,
    p_title,
    p_body,
    p_category,
    p_action_route,
    p_payload,
    p_priority
  );
end;
$$;

create or replace function private.mobile_requisition_status_label(
  p_status text
)
returns text
language sql
immutable
as $$
  select case coalesce(p_status, '')
    when 'pending' then 'pendente'
    when 'approved' then 'aprovada'
    when 'rejected' then 'rejeitada'
    when 'purchased' then 'em compras'
    when 'delivered' then 'entregue'
    else coalesce(p_status, 'atualizada')
  end;
$$;

create or replace function private.mobile_route_status_label(p_status text)
returns text
language sql
immutable
as $$
  select case coalesce(p_status, '')
    when 'planned' then 'planejada'
    when 'inProgress' then 'em rota'
    when 'completed' then 'concluida'
    when 'cancelled' then 'cancelada'
    else coalesce(p_status, 'atualizada')
  end;
$$;

create or replace function private.notify_employee_benefit_change()
returns trigger
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_title text;
  v_body text;
  v_benefit_name text;
begin
  v_benefit_name := coalesce(nullif(new."benefitName", ''), 'beneficio');

  if tg_op = 'INSERT' and new."isActive" then
    v_title := 'Beneficio vinculado';
    v_body := 'Voce recebeu o beneficio ' || v_benefit_name || '.';
  elsif tg_op = 'UPDATE' then
    if new."isActive" and not coalesce(old."isActive", false) then
      v_title := 'Beneficio reativado';
      v_body := 'Seu beneficio ' || v_benefit_name || ' foi reativado.';
    elsif old."isActive" and not new."isActive" then
      v_title := 'Beneficio encerrado';
      v_body := 'Seu beneficio ' || v_benefit_name || ' foi encerrado.';
    elsif new."isActive" and (
      new."monthlyValue" is distinct from old."monthlyValue"
      or new."benefitName" is distinct from old."benefitName"
      or new."endDate" is distinct from old."endDate"
    ) then
      v_title := 'Beneficio atualizado';
      v_body := 'Seu beneficio ' || v_benefit_name || ' foi atualizado.';
    end if;
  end if;

  if v_title is not null then
    perform private.enqueue_mobile_push_notification(
      null,
      new."employeeId",
      v_title,
      v_body,
      'benefit',
      'benefits',
      jsonb_build_object(
        'employeeBenefitId', new.id,
        'benefitId', new."benefitId",
        'benefitName', new."benefitName",
        'isActive', new."isActive"
      ),
      'normal'
    );
  end if;

  return new;
end;
$$;

drop trigger if exists trg_notify_employee_benefit_change
  on public.employee_benefits;
create trigger trg_notify_employee_benefit_change
after insert or update on public.employee_benefits
for each row execute function private.notify_employee_benefit_change();

create or replace function private.notify_purchase_delivery_route_change()
returns trigger
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_title text;
  v_body text;
  v_route_name text;
  v_driver_id text;
begin
  v_route_name := coalesce(nullif(new.name, ''), 'sua rota');
  v_driver_id := nullif(new."driverId", '');

  if v_driver_id is null then
    return new;
  end if;

  if tg_op = 'INSERT' then
    v_title := 'Nova rota atribuida';
    v_body := 'Voce recebeu ' || v_route_name || ' para coleta/entrega.';
  elsif tg_op = 'UPDATE' then
    if new."driverId" is distinct from old."driverId" then
      v_title := 'Nova rota atribuida';
      v_body := 'Voce recebeu ' || v_route_name || ' para coleta/entrega.';
    elsif new.status is distinct from old.status then
      v_title := 'Rota ' || private.mobile_route_status_label(new.status);
      v_body := 'A rota ' || v_route_name || ' esta '
        || private.mobile_route_status_label(new.status) || '.';
    end if;
  end if;

  if v_title is not null then
    perform private.enqueue_mobile_push_notification(
      null,
      v_driver_id,
      v_title,
      v_body,
      'route',
      'delivery_routes',
      jsonb_build_object(
        'routeId', new.id,
        'routeName', new.name,
        'status', new.status,
        'scheduledDate', new."scheduledDate"
      ),
      case when new.status in ('planned', 'inProgress') then 'high' else 'normal' end
    );
  end if;

  return new;
end;
$$;

drop trigger if exists trg_notify_purchase_delivery_route_change
  on public.purchase_delivery_routes;
create trigger trg_notify_purchase_delivery_route_change
after insert or update on public.purchase_delivery_routes
for each row execute function private.notify_purchase_delivery_route_change();

create or replace function private.notify_team_project_assignments()
returns trigger
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_project_name text;
  v_employee_id text;
  v_new_ids text[];
  v_old_ids text[];
begin
  if not coalesce(new."isActive", true) then
    return new;
  end if;

  if nullif(new."projectId", '') is null then
    return new;
  end if;

  select p.name
  into v_project_name
  from public.projects p
  where p.id = new."projectId"
  limit 1;

  v_project_name := coalesce(nullif(v_project_name, ''), 'obra vinculada');

  select array_agg(distinct employee_id)
  into v_new_ids
  from unnest(
    coalesce(new."memberIds", '{}'::text[])
    || array[coalesce(new."leaderId", '')]
  ) as employee_id
  where nullif(employee_id, '') is not null;

  if tg_op = 'UPDATE'
    and new."projectId" is not distinct from old."projectId"
    and coalesce(old."isActive", true) then
    select array_agg(distinct employee_id)
    into v_old_ids
    from unnest(
      coalesce(old."memberIds", '{}'::text[])
      || array[coalesce(old."leaderId", '')]
    ) as employee_id
    where nullif(employee_id, '') is not null;
  else
    v_old_ids := '{}'::text[];
  end if;

  for v_employee_id in
    select employee_id
    from unnest(coalesce(v_new_ids, '{}'::text[])) as employee_id
    except
    select employee_id
    from unnest(coalesce(v_old_ids, '{}'::text[])) as employee_id
  loop
    perform private.enqueue_mobile_push_notification(
      null,
      v_employee_id,
      'Obra vinculada',
      'Voce foi vinculado a ' || v_project_name || ' pela equipe ' || new.name || '.',
      'project',
      'projects',
      jsonb_build_object(
        'teamId', new.id,
        'teamName', new.name,
        'projectId', new."projectId",
        'projectName', v_project_name
      ),
      'normal'
    );
  end loop;

  return new;
end;
$$;

drop trigger if exists trg_notify_team_project_assignments on public.teams;
create trigger trg_notify_team_project_assignments
after insert or update of "memberIds", "leaderId", "projectId", "isActive"
on public.teams
for each row execute function private.notify_team_project_assignments();

create or replace function private.notify_project_coordinator_assignment()
returns trigger
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
begin
  if nullif(new."coordinatorId", '') is null then
    return new;
  end if;

  if tg_op = 'INSERT'
    or new."coordinatorId" is distinct from old."coordinatorId" then
    perform private.enqueue_mobile_push_notification(
      null,
      new."coordinatorId",
      'Obra atribuida',
      'Voce foi definido como responsavel por ' || new.name || '.',
      'project',
      'projects',
      jsonb_build_object(
        'projectId', new.id,
        'projectName', new.name,
        'coordinatorId', new."coordinatorId"
      ),
      'normal'
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

create or replace function private.notify_material_requisition_change()
returns trigger
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_title text;
  v_body text;
  v_status_label text;
  v_category text := 'requisition';
begin
  if nullif(new."requesterId", '') is null then
    return new;
  end if;

  if tg_op = 'INSERT' then
    v_title := 'Requisicao registrada';
    v_body := 'Sua requisicao de material em '
      || coalesce(nullif(new."projectName", ''), 'obra')
      || ' foi registrada.';
  elsif tg_op = 'UPDATE' and new.status is distinct from old.status then
    v_status_label := private.mobile_requisition_status_label(new.status);
    v_title := 'Requisicao ' || v_status_label;
    v_body := 'Sua requisicao de material em '
      || coalesce(nullif(new."projectName", ''), 'obra')
      || ' esta ' || v_status_label || '.';

    if new.status in ('purchased', 'delivered') then
      v_category := 'purchase';
    end if;
  end if;

  if v_title is not null then
    perform private.enqueue_mobile_push_for_subject(
      new."requesterId",
      v_title,
      v_body,
      v_category,
      'material_requisitions',
      jsonb_build_object(
        'requisitionId', new.id,
        'projectId', new."projectId",
        'projectName', new."projectName",
        'status', new.status,
        'purchaseId', new."purchaseId"
      ),
      case when new.status in ('approved', 'rejected', 'delivered') then 'high' else 'normal' end
    );
  end if;

  return new;
end;
$$;

drop trigger if exists trg_notify_material_requisition_change
  on public.material_requisitions;
create trigger trg_notify_material_requisition_change
after insert or update of status
on public.material_requisitions
for each row execute function private.notify_material_requisition_change();
