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
