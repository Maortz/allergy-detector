create extension if not exists "uuid-ossp";

create type feedback_type as enum ('allergen_missing', 'allergen_wrong', 'product_info_wrong', 'other');

create table brands (
  id uuid primary key default uuid_generate_v4(),
  name_he text not null,
  name_en text,
  trust_score float not null default 0.5,
  logo_url text,
  external_source_id text,
  created_at timestamptz not null default now()
);

create table allergens (
  id uuid primary key default uuid_generate_v4(),
  name_he text not null unique,
  name_en text,
  emoji text,
  created_at timestamptz not null default now()
);

create table products (
  id uuid primary key default uuid_generate_v4(),
  name_he text not null,
  barcode text unique,
  brand_id uuid references brands(id),
  ingredients text,
  is_kosher boolean not null default false,
  image_url text,
  external_source_id text,
  last_synced_at timestamptz,
  is_archived boolean not null default false,
  created_at timestamptz not null default now()
);

create table product_allergens (
  product_id uuid not null references products(id) on delete cascade,
  allergen_id uuid not null references allergens(id) on delete cascade,
  severity text not null check (severity in ('contains', 'may_contain')),
  primary key (product_id, allergen_id, severity)
);

create table feedback_reports (
  id uuid primary key default uuid_generate_v4(),
  product_id uuid not null references products(id),
  type feedback_type not null default 'other',
  message text,
  submitted_at timestamptz not null default now(),
  resolved boolean not null default false
);

create index idx_products_barcode on products(barcode);
create index idx_products_name_he on products(name_he);
create index idx_products_brand_id on products(brand_id);
create index idx_product_allergens_product on product_allergens(product_id);
create index idx_product_allergens_allergen on product_allergens(allergen_id);
create index idx_feedback_product on feedback_reports(product_id);

-- Atomically insert a product and its allergen rows (issue #45).
--
-- A plpgsql function body runs inside a single implicit transaction, so the
-- product row and every product_allergens row commit together or not at all —
-- removing the orphaned-product window the old two-step client insert had
-- (product inserted, then allergen rows fail, leaving a childless product).
--
-- `contain_ids` / `may_contain_ids` are arrays of allergen UUIDs. Returns the
-- inserted product row joined with its brand fields, matching the shape the
-- client's `addProduct` already maps. SECURITY INVOKER (default) so existing
-- RLS/grants apply unchanged.
create or replace function add_product_with_allergens(
  p_name_he text,
  p_barcode text default null,
  p_brand_id uuid default null,
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
  insert into products (name_he, barcode, brand_id, ingredients, is_kosher, image_url)
  values (p_name_he, p_barcode, p_brand_id, p_ingredients, p_is_kosher, p_image_url)
  returning products.id into new_product_id;

  insert into product_allergens (product_id, allergen_id, severity)
  select new_product_id, allergen_id, 'contains'
  from unnest(contain_ids) as allergen_id
  union all
  select new_product_id, allergen_id, 'may_contain'
  from unnest(may_contain_ids) as allergen_id;

  return query
  select
    p.id, p.name_he, p.barcode, p.brand_id, p.ingredients,
    p.is_kosher, p.image_url, p.is_archived,
    b.name_he as brand_name_he, b.trust_score as brand_trust_score
  from products p
  left join brands b on b.id = p.brand_id
  where p.id = new_product_id;
end;
$$;
