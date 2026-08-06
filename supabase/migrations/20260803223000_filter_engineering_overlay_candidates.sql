create or replace function private.engineering_overlay_needs_classification(
  classification_code text,
  element_properties jsonb
)
returns boolean
language sql
immutable
set search_path = public, private, pg_temp
as $$
  select
    lower(trim(coalesce(classification_code, ''))) like '%.unclassified'
    or (
      coalesce(element_properties ->> 'detector', '') = 'OpenCV/contours'
      and lower(trim(coalesce(classification_code, ''))) like 'symbol.%'
    );
$$;

revoke all on function private.engineering_overlay_needs_classification(
  text,
  jsonb
) from public, anon, authenticated;

create or replace function private.filter_engineering_overlay_candidate()
returns trigger
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  detector text := coalesce(new.properties ->> 'detector', '');
  normalized_code text := lower(trim(coalesce(new."classificationCode", '')));
  candidate_width numeric;
  candidate_height numeric;
  candidate_aspect numeric;
  existing_symbol_candidates integer;
begin
  -- Raw Hough segments describe walls, tables, text and dimensions. They are
  -- evidence for the worker, not reviewable technical paths.
  if detector = 'OpenCV/HoughLinesP'
     and normalized_code = 'route.unclassified' then
    return null;
  end if;

  -- Keep only bounded, sufficiently confident contour suggestions. Once a
  -- reviewer assigns a technical code, the corrected element is preserved.
  if detector = 'OpenCV/contours'
     and normalized_code like 'symbol.%' then
    candidate_width := case
      when coalesce(new.geometry ->> 'width', '') ~ '^[0-9]+([.][0-9]+)?$'
        then (new.geometry ->> 'width')::numeric
      else 0
    end;
    candidate_height := case
      when coalesce(new.geometry ->> 'height', '') ~ '^[0-9]+([.][0-9]+)?$'
        then (new.geometry ->> 'height')::numeric
      else 0
    end;
    candidate_aspect := candidate_width / greatest(candidate_height, 0.000001);

    if coalesce(new.confidence, 0) < 0.70
       or candidate_width < 0.006
       or candidate_height < 0.006
       or candidate_width > 0.06
       or candidate_height > 0.06
       or candidate_aspect < 0.35
       or candidate_aspect > 2.85 then
      return null;
    end if;

    select count(*) into existing_symbol_candidates
    from public.engineering_overlay_elements element
    where element."versionId" = new."versionId"
      and element."pageNumber" = new."pageNumber"
      and coalesce(element.properties ->> 'detector', '') = 'OpenCV/contours'
      and lower(element."classificationCode") like 'symbol.%';

    if existing_symbol_candidates >= 150 then
      return null;
    end if;
  end if;

  return new;
end;
$$;

revoke all on function private.filter_engineering_overlay_candidate()
  from public, anon, authenticated;

drop trigger if exists filter_engineering_overlay_candidate
  on public.engineering_overlay_elements;
create trigger filter_engineering_overlay_candidate
before insert on public.engineering_overlay_elements
for each row execute function private.filter_engineering_overlay_candidate();

create or replace function private.validate_engineering_overlay_approval()
returns trigger
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  unclassified_count integer;
begin
  if new.status = 'approved'
     and old.status is distinct from new.status then
    select count(*) into unclassified_count
    from public.engineering_overlay_elements element
    where element."versionId" = new.id
      and element."reviewStatus" = 'accepted'
      and private.engineering_overlay_needs_classification(
        element."classificationCode",
        element.properties
      );

    if unclassified_count > 0 then
      raise exception using
        errcode = '55000',
        message = format(
          'Classify %s accepted overlay element(s) before approval.',
          unclassified_count
        );
    end if;
  end if;
  return new;
end;
$$;

revoke all on function private.validate_engineering_overlay_approval()
  from public, anon, authenticated;

drop trigger if exists validate_engineering_overlay_approval
  on public.engineering_overlay_versions;
create trigger validate_engineering_overlay_approval
before update of status on public.engineering_overlay_versions
for each row execute function private.validate_engineering_overlay_approval();

comment on function private.filter_engineering_overlay_candidate() is
  'Prevents raw OpenCV detector output from becoming thousands of review items.';

comment on function private.validate_engineering_overlay_approval() is
  'Requires accepted assisted-review elements to have a technical classification.';
