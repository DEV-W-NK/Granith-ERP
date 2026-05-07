alter table public.benefits
  add column if not exists "valueMode" text not null default 'fixedMonthly',
  add column if not exists "defaultValue" numeric(14,2) not null default 0,
  add column if not exists "reimbursementLimit" numeric(14,2) not null default 0;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'benefits_value_mode_check'
  ) then
    alter table public.benefits
      add constraint benefits_value_mode_check
      check ("valueMode" in ('fixedMonthly', 'reimbursement'));
  end if;

  if not exists (
    select 1 from pg_constraint where conname = 'benefits_default_value_non_negative'
  ) then
    alter table public.benefits
      add constraint benefits_default_value_non_negative
      check ("defaultValue" >= 0);
  end if;

  if not exists (
    select 1 from pg_constraint where conname = 'benefits_reimbursement_limit_non_negative'
  ) then
    alter table public.benefits
      add constraint benefits_reimbursement_limit_non_negative
      check ("reimbursementLimit" >= 0);
  end if;
end $$;
