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

-- ---------------------------------------------------------------------------
-- Auth foundation (issue #79) — user-owned tables + RLS.
--
-- Backend only: no auth UI ships in this issue. The app bootstraps an
-- anonymous Supabase session on startup (see app/lib/services/auth_service.dart),
-- so `auth.uid()` is non-null for every client and these rows are scoped to it.
-- A guest can later be upgraded to an email/OTP account in place — the same
-- `auth.users.id` is retained, so rows written while anonymous survive the
-- upgrade with no migration.
-- ---------------------------------------------------------------------------

create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  email text,
  avatar_data text,
  selected_allergen_ids uuid[] not null default '{}',
  product_filter_level text not null default 'caution_and_above',
  has_completed_onboarding boolean not null default false,
  is_admin boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table favorites (
  user_id uuid not null references auth.users(id) on delete cascade,
  product_id uuid not null references products(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, product_id)
);

create table reviews (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users(id) on delete cascade,
  product_id uuid not null references products(id) on delete cascade,
  decision text not null check (decision in ('approve', 'reject')),
  reason text,
  created_at timestamptz not null default now()
);

create index idx_favorites_user on favorites(user_id);
create index idx_reviews_user on reviews(user_id);
create index idx_reviews_product on reviews(product_id);

alter table profiles  enable row level security;
alter table favorites enable row level security;
alter table reviews   enable row level security;

create policy "profiles are self-owned"
  on profiles for all
  using (auth.uid() = id)
  with check (auth.uid() = id);

create policy "favorites are self-owned"
  on favorites for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "reviews are self-owned"
  on reviews for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  insert into public.profiles (id, email)
  values (new.id, new.email)
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Keep profiles.updated_at in sync with the last modification. Without this the
-- column holds the row's creation time forever, returning stale timestamps once
-- the profile-sync follow-up starts writing to this table.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_set_updated_at
  before update on profiles
  for each row execute function public.set_updated_at();

-- Prevent privilege escalation: the owner-only RLS policy lets a user update any
-- column on their own row, which would otherwise include self-granting
-- `is_admin = true`. This before-update trigger freezes `is_admin` for ordinary
-- client roles (`anon` / `authenticated`), so it can only be changed by a
-- trusted backend (the `service_role` key or a superuser/admin migration).
create or replace function public.guard_profiles_is_admin()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
declare
  _claims jsonb;
begin
  -- Tolerate a malformed/non-JSON request.jwt.claims setting: a bad cast here
  -- would otherwise abort an ordinary profile update under security definer.
  begin
    _claims := current_setting('request.jwt.claims', true)::jsonb;
  exception when others then
    _claims := null;
  end;

  if new.is_admin is distinct from old.is_admin
     and _claims is not null
     and coalesce(_claims ->> 'role', '') <> 'service_role'
  then
    new.is_admin = old.is_admin;
  end if;
  return new;
end;
$$;

create trigger profiles_guard_is_admin
  before update on profiles
  for each row execute function public.guard_profiles_is_admin();
