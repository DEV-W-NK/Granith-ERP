-- Retry/backoff real para o outbox de push mobile.
-- Falhas transitorias continuam pendentes ate maxAttempts; falhas definitivas
-- ou ausencia de token ativo encerram a notificacao como failed.

alter table public.mobile_push_notifications
  add column if not exists attempts integer not null default 0,
  add column if not exists "maxAttempts" integer not null default 5,
  add column if not exists "lastAttemptAt" timestamptz,
  add column if not exists "nextAttemptAt" timestamptz default now();

alter table public.mobile_push_notifications
  drop constraint if exists mobile_push_notifications_attempts_check;

alter table public.mobile_push_notifications
  add constraint mobile_push_notifications_attempts_check check (
    attempts >= 0
    and "maxAttempts" between 1 and 20
    and attempts <= "maxAttempts"
  );

update public.mobile_push_notifications
set "nextAttemptAt" = coalesce("nextAttemptAt", "createdAt", now())
where status = 'pending'
  and "nextAttemptAt" is null;

drop index if exists idx_mobile_push_notifications_dispatch;

create index if not exists idx_mobile_push_notifications_dispatch_retry
  on public.mobile_push_notifications (
    status,
    "nextAttemptAt",
    priority,
    "createdAt"
  )
  where status = 'pending';
