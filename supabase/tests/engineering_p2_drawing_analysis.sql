begin;

create extension if not exists pgtap with schema extensions;

select plan(13);

select has_table('public', 'engineering_rule_packs');
select has_table('public', 'engineering_analysis_scales');
select has_table('public', 'engineering_analysis_pages');
select has_table('public', 'engineering_rfis');
select has_table('public', 'engineering_occurrences');

select has_function(
  'public',
  'create_engineering_analysis_job',
  array['text', 'text', 'numeric', 'text', 'numeric', 'numeric', 'jsonb']
);
select has_function(
  'public',
  'update_engineering_analysis_progress',
  array['text', 'numeric', 'text', 'text', 'text', 'text', 'text']
);
select has_function(
  'public',
  'complete_engineering_analysis',
  array['text', 'text', 'text', 'jsonb']
);
select has_function(
  'public',
  'review_engineering_finding',
  array['text', 'text', 'text']
);
select has_function(
  'public',
  'create_engineering_action_from_finding',
  array[
    'text',
    'text',
    'text',
    'text',
    'text',
    'text',
    'timestamp with time zone',
    'text'
  ]
);

select is(
  length(
    (
      select "contentSha256"
      from public.engineering_rule_packs
      where id = 'granith-abnt-iso-base-v1'
    )
  ),
  64,
  'rule pack receives a deterministic SHA-256'
);

select lives_ok(
  $$update public.engineering_rule_packs
    set "isActive" = not "isActive"
    where id = 'granith-abnt-iso-base-v1'$$,
  'rule pack may be activated or deactivated'
);

select throws_like(
  $$update public.engineering_rule_packs
    set title = title || ' changed'
    where id = 'granith-abnt-iso-base-v1'$$,
  '%immutable%',
  'rule pack content is immutable'
);

select * from finish();

rollback;
