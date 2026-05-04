-- Granith ERP - Disable unused GraphQL surface.
-- The Flutter app uses the Supabase Data API through PostgREST, not GraphQL.
-- Disabling pg_graphql removes schema discovery through /graphql/v1 without
-- changing table access through supabase_flutter .from(...).

drop extension if exists pg_graphql;

do $$
begin
  if to_regclass('public."GranithERP"') is not null then
    execute 'revoke all privileges on table public."GranithERP" from anon, authenticated';
  end if;
end $$;
