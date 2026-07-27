-- Shared task management for Granith ERP and Granith Mobile.
-- Timers are derived from server timestamps so they keep running while every
-- client is closed. Each interval is also stored separately for auditing.

create table if not exists public.granith_tasks (
  id text primary key default gen_random_uuid()::text,
  title text not null,
  description text not null default '',
  status text not null default 'pending',
  priority text not null default 'medium',
  "supervisorId" text not null references public.employees(id) on delete restrict,
  "supervisorName" text not null default '',
  "assigneeId" text not null references public.employees(id) on delete restrict,
  "assigneeName" text not null default '',
  "projectId" text references public.projects(id) on delete set null,
  "projectName" text not null default '',
  "budgetId" text references public.budgets(id) on delete set null,
  "budgetName" text not null default '',
  "sourceType" text not null default 'general',
  "dueAt" timestamptz,
  "estimatedMinutes" integer not null default 0,
  "startedAt" timestamptz,
  "activeTimerStartedAt" timestamptz,
  "accumulatedSeconds" bigint not null default 0,
  "completedAt" timestamptz,
  "createdByUserId" text,
  "createdByEmployeeId" text,
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now(),
  version integer not null default 1,
  constraint granith_tasks_title_not_blank check (length(trim(title)) > 0),
  constraint granith_tasks_status_check check (
    status in ('pending', 'inProgress', 'paused', 'completed', 'cancelled')
  ),
  constraint granith_tasks_priority_check check (
    priority in ('low', 'medium', 'high', 'urgent')
  ),
  constraint granith_tasks_source_type_check check (
    "sourceType" in ('general', 'project', 'budget')
  ),
  constraint granith_tasks_single_source_check check (
    not ("projectId" is not null and "budgetId" is not null)
  ),
  constraint granith_tasks_nonnegative_time_check check (
    "accumulatedSeconds" >= 0 and "estimatedMinutes" >= 0
  )
);

create table if not exists public.granith_task_time_entries (
  id text primary key default gen_random_uuid()::text,
  "taskId" text not null references public.granith_tasks(id) on delete cascade,
  "employeeId" text not null references public.employees(id) on delete restrict,
  "startedAt" timestamptz not null,
  "endedAt" timestamptz,
  "durationSeconds" bigint not null default 0,
  source text not null default 'web',
  "clientOccurredAt" timestamptz,
  "createdByUserId" text,
  "createdAt" timestamptz not null default now(),
  constraint granith_task_entries_duration_check check ("durationSeconds" >= 0),
  constraint granith_task_entries_source_check check (
    source in ('web', 'mobile', 'mobile_offline', 'system')
  )
);

create index if not exists idx_granith_tasks_assignee_status
  on public.granith_tasks ("assigneeId", status, "updatedAt" desc);
create index if not exists idx_granith_tasks_supervisor_status
  on public.granith_tasks ("supervisorId", status, "updatedAt" desc);
create index if not exists idx_granith_tasks_project
  on public.granith_tasks ("projectId") where "projectId" is not null;
create index if not exists idx_granith_tasks_budget
  on public.granith_tasks ("budgetId") where "budgetId" is not null;
create index if not exists idx_granith_tasks_due
  on public.granith_tasks ("dueAt") where "dueAt" is not null;
create index if not exists idx_granith_task_entries_task_started
  on public.granith_task_time_entries ("taskId", "startedAt" desc);
create unique index if not exists idx_granith_task_single_open_entry
  on public.granith_task_time_entries ("taskId")
  where "endedAt" is null;
create unique index if not exists idx_granith_task_single_active_assignee
  on public.granith_tasks ("assigneeId")
  where "activeTimerStartedAt" is not null;

create or replace function private.current_task_employee_id()
returns text
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select coalesce(
    (
      select coalesce(
        nullif(u.employee_id, ''),
        nullif(u."employeeId", '')
      )
      from public.users u
      where u.id::text = auth.uid()::text
      limit 1
    ),
    (
      select e.id::text
      from public.employees e
      where lower(e.email) = lower(coalesce(auth.jwt() ->> 'email', ''))
      limit 1
    )
  );
$$;

create or replace function private.prepare_granith_task()
returns trigger
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
begin
  select e.name into new."supervisorName"
  from public.employees e
  where e.id = new."supervisorId";

  select e.name into new."assigneeName"
  from public.employees e
  where e.id = new."assigneeId";

  if new."projectId" is not null then
    select p.name into new."projectName"
    from public.projects p
    where p.id = new."projectId";
    new."budgetId" := null;
    new."budgetName" := '';
    new."sourceType" := 'project';
  elsif new."budgetId" is not null then
    select concat_ws(' - ', nullif(b."clientName", ''), nullif(b."projectName", ''))
    into new."budgetName"
    from public.budgets b
    where b.id = new."budgetId";
    new."projectId" := null;
    new."projectName" := '';
    new."sourceType" := 'budget';
  else
    new."projectName" := '';
    new."budgetName" := '';
    new."sourceType" := 'general';
  end if;

  if tg_op = 'INSERT' then
    new."createdByUserId" := coalesce(
      nullif(new."createdByUserId", ''),
      auth.uid()::text
    );
    new."createdByEmployeeId" := coalesce(
      nullif(new."createdByEmployeeId", ''),
      private.current_task_employee_id()
    );
    new."createdAt" := coalesce(new."createdAt", now());
    new.version := 1;
  else
    new.version := old.version + 1;
  end if;

  new."updatedAt" := now();
  return new;
end;
$$;

drop trigger if exists prepare_granith_task_row on public.granith_tasks;
create trigger prepare_granith_task_row
before insert or update on public.granith_tasks
for each row execute function private.prepare_granith_task();

alter table public.granith_tasks enable row level security;
alter table public.granith_tasks force row level security;
alter table public.granith_task_time_entries enable row level security;
alter table public.granith_task_time_entries force row level security;

drop policy if exists granith_tasks_select_related on public.granith_tasks;
create policy granith_tasks_select_related
on public.granith_tasks
for select
to authenticated
using (
  private.can_manage_people()
  or private.has_min_employee_role(3)
  or "supervisorId" = private.current_task_employee_id()
  or "assigneeId" = private.current_task_employee_id()
  or "createdByUserId" = auth.uid()::text
);

drop policy if exists granith_tasks_insert_supervisor on public.granith_tasks;
create policy granith_tasks_insert_supervisor
on public.granith_tasks
for insert
to authenticated
with check (
  private.can_manage_people()
  or private.has_min_employee_role(3)
  or (
    private.has_min_employee_role(2)
    and "supervisorId" = private.current_task_employee_id()
  )
);

drop policy if exists granith_tasks_update_supervisor on public.granith_tasks;
create policy granith_tasks_update_supervisor
on public.granith_tasks
for update
to authenticated
using (
  private.can_manage_people()
  or private.has_min_employee_role(3)
  or "supervisorId" = private.current_task_employee_id()
)
with check (
  private.can_manage_people()
  or private.has_min_employee_role(3)
  or "supervisorId" = private.current_task_employee_id()
);

drop policy if exists granith_tasks_delete_supervisor on public.granith_tasks;
create policy granith_tasks_delete_supervisor
on public.granith_tasks
for delete
to authenticated
using (
  private.can_manage_people()
  or private.has_min_employee_role(3)
  or "supervisorId" = private.current_task_employee_id()
);

drop policy if exists granith_task_entries_select_related
  on public.granith_task_time_entries;
create policy granith_task_entries_select_related
on public.granith_task_time_entries
for select
to authenticated
using (
  private.can_manage_people()
  or private.has_min_employee_role(3)
  or "employeeId" = private.current_task_employee_id()
  or exists (
    select 1
    from public.granith_tasks task
    where task.id = "taskId"
      and task."supervisorId" = private.current_task_employee_id()
  )
);

revoke all on public.granith_tasks from anon;
revoke all on public.granith_task_time_entries from anon;
grant select, insert, update, delete on public.granith_tasks to authenticated;
grant select on public.granith_task_time_entries to authenticated;
grant all on public.granith_tasks to service_role;
grant all on public.granith_task_time_entries to service_role;
grant execute on function private.current_task_employee_id() to authenticated;

create or replace function public.set_granith_task_timer(
  p_task_id text,
  p_action text,
  p_source text default 'web',
  p_occurred_at timestamptz default null
)
returns public.granith_tasks
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_task public.granith_tasks%rowtype;
  v_employee_id text := private.current_task_employee_id();
  v_now timestamptz := now();
  v_event_at timestamptz;
  v_elapsed bigint := 0;
  v_source text;
begin
  if auth.uid() is null then
    raise exception 'Authentication required.';
  end if;

  select *
  into v_task
  from public.granith_tasks
  where id = p_task_id
  for update;

  if not found then
    raise exception 'Task not found.';
  end if;

  if v_employee_id is null then
    raise exception 'Authenticated user is not linked to an employee.';
  end if;

  if v_task."assigneeId" <> v_employee_id
    and not private.can_manage_people() then
    raise exception 'Only the assignee can control this timer.';
  end if;

  v_event_at := coalesce(p_occurred_at, v_now);
  v_event_at := least(v_now, greatest(v_now - interval '7 days', v_event_at));
  v_source := case
    when p_source in ('web', 'mobile', 'mobile_offline', 'system') then p_source
    else 'web'
  end;

  if p_action = 'start' then
    if v_task.status in ('completed', 'cancelled') then
      raise exception 'Completed or cancelled tasks cannot be started.';
    end if;

    if v_task."activeTimerStartedAt" is null then
      insert into public.granith_task_time_entries (
        "taskId",
        "employeeId",
        "startedAt",
        source,
        "clientOccurredAt",
        "createdByUserId"
      )
      values (
        v_task.id,
        v_task."assigneeId",
        v_event_at,
        v_source,
        p_occurred_at,
        auth.uid()::text
      );

      update public.granith_tasks
      set
        status = 'inProgress',
        "startedAt" = coalesce("startedAt", v_event_at),
        "activeTimerStartedAt" = v_event_at
      where id = v_task.id;
    end if;
  elsif p_action in ('pause', 'complete') then
    if v_task."activeTimerStartedAt" is not null then
      v_event_at := greatest(v_event_at, v_task."activeTimerStartedAt");
      v_elapsed := greatest(
        0,
        floor(extract(epoch from (v_event_at - v_task."activeTimerStartedAt")))::bigint
      );

      update public.granith_task_time_entries
      set
        "endedAt" = v_event_at,
        "durationSeconds" = v_elapsed,
        "clientOccurredAt" = coalesce(p_occurred_at, "clientOccurredAt")
      where "taskId" = v_task.id
        and "endedAt" is null;
    end if;

    update public.granith_tasks
    set
      status = case when p_action = 'complete' then 'completed' else 'paused' end,
      "accumulatedSeconds" = "accumulatedSeconds" + v_elapsed,
      "activeTimerStartedAt" = null,
      "completedAt" = case
        when p_action = 'complete' then v_event_at
        else null
      end
    where id = v_task.id;
  else
    raise exception 'Unsupported timer action.';
  end if;

  select * into v_task
  from public.granith_tasks
  where id = p_task_id;
  return v_task;
end;
$$;

revoke all on function public.set_granith_task_timer(
  text,
  text,
  text,
  timestamptz
) from public, anon;
grant execute on function public.set_granith_task_timer(
  text,
  text,
  text,
  timestamptz
) to authenticated, service_role;

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
      'task',
      'system'
    )
  );

create or replace function private.notify_granith_task_change()
returns trigger
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_title text;
  v_body text;
  v_recipient text;
  v_priority text := 'normal';
begin
  if tg_op = 'INSERT' then
    v_title := 'Nova tarefa atribuida';
    v_body := new.title;
    v_recipient := new."assigneeId";
  elsif new."assigneeId" is distinct from old."assigneeId" then
    v_title := 'Tarefa atribuida a voce';
    v_body := new.title;
    v_recipient := new."assigneeId";
  elsif new.status = 'completed' and old.status is distinct from 'completed' then
    v_title := 'Tarefa concluida';
    v_body := new."assigneeName" || ' concluiu: ' || new.title;
    v_recipient := new."supervisorId";
  elsif new.priority is distinct from old.priority
    or new."dueAt" is distinct from old."dueAt" then
    v_title := 'Tarefa atualizada';
    v_body := new.title;
    v_recipient := new."assigneeId";
  end if;

  if new.priority = 'urgent' then
    v_priority := 'high';
  end if;

  if v_title is not null and nullif(v_recipient, '') is not null then
    perform private.enqueue_mobile_push_notification(
      null,
      v_recipient,
      v_title,
      v_body,
      'task',
      'tasks',
      jsonb_build_object(
        'taskId', new.id,
        'status', new.status,
        'priority', new.priority,
        'supervisorId', new."supervisorId",
        'assigneeId', new."assigneeId"
      ),
      v_priority
    );
  end if;

  return new;
end;
$$;

drop trigger if exists notify_granith_task_change
  on public.granith_tasks;
create trigger notify_granith_task_change
after insert or update on public.granith_tasks
for each row execute function private.notify_granith_task_change();

do $$
begin
  alter publication supabase_realtime add table public.granith_tasks;
exception
  when duplicate_object then null;
end;
$$;
