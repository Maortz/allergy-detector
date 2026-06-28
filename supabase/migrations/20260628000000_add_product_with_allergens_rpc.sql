-- Issue #331 — fix 404 on POST /rest/v1/rpc/add_product_with_allergens.
--
-- The function exists in `schema.sql` but was never added to a migration, so
-- `supabase db push` (which applies `migrations/`, not `schema.sql`) never
-- deployed it to the hosted project — PostgREST therefore can't find it in the
-- schema cache and returns 404. This migration brings the deployed database in
-- line with `schema.sql` for the add-product path:
--
--   1. the `category` column the function writes into (the initial migration's
--      `products` table predates it), and
--   2. the `add_product_with_allergens` function itself, plus an explicit
--      EXECUTE grant for the roles the app uses.
--
-- All statements are idempotent (`add column if not exists` / `create or
-- replace` / `grant`) so re-applying — or applying on a DB already seeded from
-- `schema.sql` — is a no-op.

-- 1. Column the function inserts into (added to `products` in schema.sql but
--    missing from the initial migration).
alter table products add column if not exists category text;

-- 2. Atomic product + allergen insert (issue #45). Kept byte-for-byte in sync
--    with the definition in `schema.sql`. A function body is one implicit
--    transaction, so the product and its product_allergens rows commit together
--    — no orphaned-product window. SECURITY INVOKER (default) so existing
--    RLS/grants apply unchanged.
create or replace function add_product_with_allergens(
  p_name_he text,
  p_barcode text default null,
  p_brand_id uuid default null,
  p_category text default null,
  p_ingredients text default null,
  p_is_kosher boolean default false,
  p_image_url text default null,
  contain_ids uuid[] default '{}',
  may_contain_ids uuid[] default '{}'
)
returns table (
  id uuid,
  name_he text,
  barcode text,
  brand_id uuid,
  category text,
  ingredients text,
  is_kosher boolean,
  image_url text,
  is_archived boolean,
  brand_name_he text,
  brand_trust_score float
)
language plpgsql
as $$
declare
  new_product_id uuid;
begin
  insert into products (name_he, barcode, brand_id, category, ingredients, is_kosher, image_url)
  values (p_name_he, p_barcode, p_brand_id, p_category, p_ingredients, p_is_kosher, p_image_url)
  returning products.id into new_product_id;

  insert into product_allergens (product_id, allergen_id, severity)
  select new_product_id, allergen_id, 'contains'
  from unnest(contain_ids) as allergen_id
  union all
  select new_product_id, allergen_id, 'may_contain'
  from unnest(may_contain_ids) as allergen_id;

  return query
  select
    p.id, p.name_he, p.barcode, p.brand_id, p.category, p.ingredients,
    p.is_kosher, p.image_url, p.is_archived,
    b.name_he as brand_name_he, b.trust_score as brand_trust_score
  from products p
  left join brands b on b.id = p.brand_id
  where p.id = new_product_id;
end;
$$;

-- 3. PostgREST calls run as `anon` / `authenticated` (no auth in the MVP).
--    Functions default to EXECUTE for PUBLIC, but grant explicitly so a future
--    `REVOKE ... FROM PUBLIC` hardening pass doesn't silently 403 this RPC.
grant execute on function add_product_with_allergens(
  text, text, uuid, text, text, boolean, text, uuid[], uuid[]
) to anon, authenticated;
