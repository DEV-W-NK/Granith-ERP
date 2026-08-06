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
    lower(trim(coalesce(classification_code, ''))) = ''
    or lower(trim(coalesce(classification_code, ''))) like '%.unclassified'
    or (
      coalesce(element_properties ->> 'detector', '') = 'OpenCV/contours'
      and lower(trim(coalesce(classification_code, ''))) in (
        'symbol.complex',
        'symbol.unknown',
        'symbol.generic'
      )
      and coalesce(
        lower(element_properties ->> 'technicalClassificationConfirmed'),
        'false'
      ) <> 'true'
    );
$$;

revoke all on function private.engineering_overlay_needs_classification(
  text,
  jsonb
) from public, anon, authenticated;

comment on function private.engineering_overlay_needs_classification(
  text,
  jsonb
) is
  'Blocks only provisional overlay classifications. Reviewer-assigned technical codes remain approvable.';
