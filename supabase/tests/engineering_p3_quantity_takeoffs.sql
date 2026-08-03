begin;

create extension if not exists pgtap with schema extensions;

select plan(17);

select has_table('public', 'engineering_quantity_profiles');
select has_table('public', 'engineering_quantity_takeoffs');
select has_table('public', 'engineering_quantity_items');
select has_table('public', 'engineering_quantity_elements');
select has_table('public', 'engineering_quantity_item_costs');
select has_view('public', 'engineering_catalog_items');

select has_function(
  'public',
  'create_engineering_quantity_takeoff',
  array['text', 'text']
);
select has_function(
  'public',
  'fail_engineering_quantity_takeoff',
  array['text', 'text', 'text', 'text']
);
select has_function(
  'public',
  'complete_engineering_quantity_takeoff',
  array['text', 'text', 'text', 'text', 'text', 'jsonb']
);
select has_function(
  'public',
  'review_engineering_quantity_item',
  array[
    'text',
    'text',
    'text',
    'numeric',
    'integer',
    'numeric',
    'integer',
    'numeric',
    'text',
    'numeric'
  ]
);
select has_function(
  'public',
  'generate_requisition_from_engineering_takeoff',
  array['text', 'text']
);
select has_function(
  'public',
  'generate_budget_from_engineering_takeoff',
  array['text', 'integer']
);

select is(
  length(
    (
      select "contentSha256"
      from public.engineering_quantity_profiles
      where id = 'granith-electrical-base-v1'
    )
  ),
  64,
  'quantity profile receives a deterministic SHA-256'
);

select lives_ok(
  $$update public.engineering_quantity_profiles
    set "isActive" = not "isActive"
    where id = 'granith-electrical-base-v1'$$,
  'quantity profile may be activated or deactivated'
);

select throws_like(
  $$update public.engineering_quantity_profiles
    set title = title || ' changed'
    where id = 'granith-electrical-base-v1'$$,
  '%immutable%',
  'quantity profile content is immutable'
);

select is(
  private.calculate_engineering_quantity(
    'length',
    100,
    '{
      "wastePercent": 10,
      "curveCount": 2,
      "curveAllowance": 0.2,
      "connectionCount": 2,
      "connectionAllowance": 0.15
    }'::jsonb
  ),
  110.700000::numeric,
  'length formula includes waste, curves and connections'
);

select is(
  private.calculate_engineering_quantity(
    'area',
    100,
    '{"wastePercent": 8}'::jsonb
  ),
  108.000000::numeric,
  'area formula applies waste without linear allowances'
);

select * from finish();

rollback;
