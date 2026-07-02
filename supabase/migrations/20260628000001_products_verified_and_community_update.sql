-- Issue #350 — bring `migrations/` in line with `schema.sql` for the
-- community-review approval flow (issue #263).
--
-- `schema.sql` defines a `verified` column on `products`, a
-- `products_community_update` RLS policy, and a column-level UPDATE grant that
-- restricts anon/authenticated writes to that single column. None of these were
-- ever added to a migration, so a database built from `migrations/` alone is
-- missing the column — the community-update policy can't be created and the
-- approval flow silently breaks. This migration closes that gap.
--
-- All statements are idempotent (`add column if not exists` / guarded
-- `create policy` / `grant`) so re-applying — or applying on a DB already seeded
-- from `schema.sql` — is a no-op.

-- 1. verified flag (community review approval sets this, issue #263). Added to
--    `products` in schema.sql but missing from the initial migration.
alter table products add column if not exists verified boolean not null default false;

-- 2. Community update policy: anon/authenticated may flip verified once a product
--    is approved. MVP keeps the row-level gate open; tighten to a reviewer /
--    auth.uid() check once auth + roles land. `create policy` has no
--    `if not exists`, so guard it explicitly.
do $$
begin
  if not exists (
    select 1 from pg_policies
    where tablename = 'products' and policyname = 'products_community_update'
  ) then
    execute 'create policy "products_community_update" on products
      for update using (true) with check (true)';
  end if;
end
$$;

-- 3. RLS cannot restrict *which columns* are writable — only column-level
--    privileges can. Without this, the open update policy above would let any
--    anon/authenticated client overwrite product names, allergen data, or
--    barcodes. Restrict the update grant to the `verified` column so a community
--    approval can only flip that flag (issue #263 AC).
revoke update on products from anon, authenticated;
grant update (verified) on products to anon, authenticated;
