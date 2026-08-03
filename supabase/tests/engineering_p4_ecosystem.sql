begin;

create extension if not exists pgtap with schema extensions;

select plan(17);

select has_table('public', 'engineering_technical_reports');
select has_table('public', 'engineering_client_report_publications');
select has_table('public', 'engineering_delivery_reports');
select has_table('public', 'engineering_delivery_receipts');
select has_table('public', 'engineering_ecosystem_events');
select has_table('public', 'engineering_offline_operations');

select has_view('public', 'client_portal_engineering_reports');
select has_view('public', 'mobile_engineering_deliveries');
select has_view('public', 'mobile_engineering_documents');

select has_function(
  'public',
  'create_engineering_delivery',
  array[
    'text',
    'text',
    'text',
    'text',
    'text',
    'text',
    'timestamptz',
    'text[]',
    'text[]',
    'text'
  ]
);
select has_function(
  'public',
  'send_engineering_delivery',
  array['text', 'text']
);
select has_function(
  'public',
  'acknowledge_engineering_delivery',
  array['text', 'text', 'text', 'text', 'text']
);
select has_function(
  'public',
  'register_engineering_technical_report',
  array[
    'text',
    'text',
    'text',
    'text',
    'text',
    'text',
    'text',
    'bigint',
    'text',
    'jsonb',
    'text'
  ]
);
select has_function(
  'public',
  'review_engineering_technical_report',
  array['text', 'text', 'text']
);
select has_function(
  'public',
  'publish_engineering_technical_report',
  array['text', 'text']
);
select has_function(
  'public',
  'unpublish_engineering_technical_report',
  array['text', 'text']
);
select has_function(
  'public',
  'apply_engineering_offline_operation',
  array['text', 'text', 'jsonb']
);

select * from finish();

rollback;
