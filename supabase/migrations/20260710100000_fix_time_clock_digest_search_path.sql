-- Fix receipt hash generation for time_clock_afd_events when pgcrypto is
-- installed in Supabase's extensions schema instead of public.

create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;

create or replace function public.prepare_time_clock_afd_event()
returns trigger
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $$
declare
  assigned_nsr bigint;
  last_hash text;
begin
  if new."establishmentId" is null or trim(new."establishmentId") = '' then
    new."establishmentId" := 'default';
  end if;

  insert into public.time_clock_establishments (id)
  values (new."establishmentId")
  on conflict (id) do nothing;

  update public.time_clock_establishments
     set "nextNsr" = "nextNsr" + 1
   where id = new."establishmentId"
   returning "nextNsr" - 1 into assigned_nsr;

  new.nsr := assigned_nsr;

  select "eventHash"
    into last_hash
    from public.time_clock_afd_events
   where "establishmentId" = new."establishmentId"
   order by nsr desc
   limit 1;

  new."previousHash" := last_hash;

  new."eventHash" := encode(
    digest(
      concat_ws(
        '|',
        new."establishmentId",
        new.nsr::text,
        new."eventKind",
        new."eventSource",
        new."punchType",
        coalesce(new."employeeId", ''),
        new."employeeCpf",
        new."projectId",
        new."eventAt"::text,
        new."timeZone",
        coalesce(new.latitude::text, ''),
        coalesce(new.longitude::text, ''),
        new."geofenceStatus",
        coalesce(new."previousHash", ''),
        new."rawPayload"::text
      ),
      'sha256'
    ),
    'hex'
  );

  if new."receiptCode" is null or trim(new."receiptCode") = '' then
    new."receiptCode" := upper(substr(new."eventHash", 1, 16));
  end if;

  return new;
end;
$$;
