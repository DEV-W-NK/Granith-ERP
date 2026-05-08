alter table public.benefits
  add column if not exists "dailyValue" numeric(14,2) not null default 0;

alter table public.employee_benefits
  add column if not exists "dailyValue" numeric(14,2) not null default 0;

alter table public.benefits
  drop constraint if exists benefits_value_mode_check;

update public.benefits
set "dailyValue" = "defaultValue"
where "dailyValue" = 0
  and "defaultValue" > 0;

update public.benefits
set "defaultValue" = "dailyValue"
where "defaultValue" = 0
  and "dailyValue" > 0;

update public.employee_benefits
set "dailyValue" = "monthlyValue"
where "dailyValue" = 0
  and "monthlyValue" > 0;

update public.benefits
set "valueMode" = 'workedDay'
where "valueMode" = 'fixedMonthly';

alter table public.benefits
  alter column "valueMode" set default 'workedDay';

alter table public.benefits
  add constraint benefits_value_mode_check
  check ("valueMode" in ('workedDay', 'reimbursement'));

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'benefits_daily_value_non_negative'
  ) then
    alter table public.benefits
      add constraint benefits_daily_value_non_negative
      check ("dailyValue" >= 0);
  end if;
end $$;
