-- Daily log signature flow:
-- - project coordinator or admin can sign a pending log;
-- - signed logs are locked against business edits;
-- - client portal can read only signed logs for its own projects.

drop policy if exists daily_logs_select_signed_for_client on public.daily_logs;
create policy daily_logs_select_signed_for_client
on public.daily_logs
for select
to authenticated
using (
  status = 'signed'
  and "signedAt" is not null
  and private.client_can_access_project("projectId"::text)
);

drop policy if exists daily_logs_sign_project_coordinator on public.daily_logs;
create policy daily_logs_sign_project_coordinator
on public.daily_logs
for update
to authenticated
using (
  status <> 'signed'
  and "signedAt" is null
  and (
    private.is_admin()
    or "coordinatorId"::text = private.current_employee_id()
  )
)
with check (
  status = 'signed'
  and "signedAt" is not null
  and (
    private.is_admin()
    or (
      "coordinatorId"::text = private.current_employee_id()
      and "signedByCoordinatorId"::text = private.current_employee_id()
    )
  )
);

create or replace function public.enforce_daily_log_signature_rules()
returns trigger
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  current_employee text;
  admin_user boolean;
begin
  current_employee := private.current_employee_id();
  admin_user := private.is_admin();

  if old.status = 'signed' or old."signedAt" is not null then
    if new."projectId" is distinct from old."projectId"
      or new."projectName" is distinct from old."projectName"
      or new.date is distinct from old.date
      or new."weatherMorning" is distinct from old."weatherMorning"
      or new."weatherAfternoon" is distinct from old."weatherAfternoon"
      or new.manpower is distinct from old.manpower
      or new."activitiesDescription" is distinct from old."activitiesDescription"
      or new.impediments is distinct from old.impediments
      or new."photoUrls" is distinct from old."photoUrls"
      or new."createdByUserId" is distinct from old."createdByUserId"
      or new.status is distinct from old.status
      or new."coordinatorId" is distinct from old."coordinatorId"
      or new."coordinatorName" is distinct from old."coordinatorName"
      or new."signatureRequestedAt" is distinct from old."signatureRequestedAt"
      or new."signedAt" is distinct from old."signedAt"
      or new."signedByCoordinatorId" is distinct from old."signedByCoordinatorId"
      or new."signedByCoordinatorName" is distinct from old."signedByCoordinatorName" then
      raise exception 'Signed daily logs cannot be edited.';
    end if;
  end if;

  if new.status = 'signed'
    and (old.status is distinct from 'signed' or old."signedAt" is null) then
    if not admin_user and nullif(old."coordinatorId", '') is null then
      raise exception 'Daily log does not have a coordinator to sign it.';
    end if;

    if not admin_user and current_employee is distinct from old."coordinatorId"::text then
      raise exception 'Only the project coordinator can sign this daily log.';
    end if;

    if not admin_user and new."signedByCoordinatorId" is distinct from old."coordinatorId" then
      raise exception 'Signature must be registered with the project coordinator.';
    end if;

    if new."signedAt" is null then
      raise exception 'Signature timestamp is required.';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_daily_logs_signature_rules on public.daily_logs;
create trigger trg_daily_logs_signature_rules
before update on public.daily_logs
for each row
execute function public.enforce_daily_log_signature_rules();
