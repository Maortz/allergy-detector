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
  category text,
  ingredients text,
  is_kosher boolean not null default false,
  image_url text,
  external_source_id text,
  last_synced_at timestamptz,
  is_archived boolean not null default false,
  -- Community review approval flag (issue #263).
  -- Migration: supabase/migrations/20260628000001_products_verified_and_community_update.sql (issue #350).
  verified boolean not null default false,
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
-- Catalog tables RLS (issue #176).
--
-- brands / allergens / products / product_allergens are public read-only
-- catalog data. They were previously public by omission (no RLS). Enabling RLS
-- with an explicit `for select using (true)` policy makes the access model
-- intentional and documented, and lets policies be tightened per-table later
-- without auditing every read path. No write policies are defined: catalog
-- writes are performed by the service_role (admin sync scripts), which bypasses
-- RLS entirely.
-- ---------------------------------------------------------------------------
alter table brands            enable row level security;
alter table allergens         enable row level security;
alter table products          enable row level security;
alter table product_allergens enable row level security;

create policy "brands_public_read" on brands
  for select using (true);

create policy "allergens_public_read" on allergens
  for select using (true);

create policy "products_public_read" on products
  for select using (true);

-- Community peer-review marks a product verified once approved (issue #263).
-- MVP keeps the row-level gate open to the anon/authenticated roles the app uses;
-- tighten to a reviewer/auth.uid() check once auth + roles land.
-- Migration: supabase/migrations/20260628000001_products_verified_and_community_update.sql (issue #350).
create policy "products_community_update" on products
  for update using (true) with check (true);

-- RLS cannot restrict *which columns* are writable — only column-level privileges
-- can. Without this, the open update policy above would let any anon/authenticated
-- client overwrite product names, allergen data, or barcodes. Restrict the update
-- grant to the `verified` column so a community approval can only flip that flag,
-- matching issue #263's AC (only `verified = true` is affected by an approval).
-- Migration: supabase/migrations/20260628000001_products_verified_and_community_update.sql (issue #350).
revoke update on products from anon, authenticated;
grant update (verified) on products to anon, authenticated;

create policy "product_allergens_public_read" on product_allergens
  for select using (true);

-- Atomically insert a product and its allergen rows (issue #45).
--
-- A plpgsql function body runs inside a single implicit transaction, so the
-- product row and every product_allergens row commit together or not at all —
-- removing the orphaned-product window the old two-step client insert had
-- (product inserted, then allergen rows fail, leaving a childless product).
--
-- `contain_ids` / `may_contain_ids` are arrays of allergen UUIDs. Returns the
-- inserted product row joined with its brand fields, matching the shape the
-- client's `addProduct` already maps. SECURITY DEFINER so the INSERTs bypass
-- RLS: `products` / `product_allergens` only define SELECT policies (catalog
-- writes go through the service_role), so a SECURITY INVOKER call from
-- anon/authenticated would hit a row-level security violation. `set search_path
-- = public` pins schema resolution for the unqualified table references and
-- blocks the search-path injection SECURITY DEFINER functions are otherwise
-- vulnerable to.
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
security definer set search_path = public
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

-- PostgREST calls run as anon/authenticated (no auth in the MVP). Functions
-- default to EXECUTE for PUBLIC, but grant explicitly so a future
-- `REVOKE ... FROM PUBLIC` hardening pass doesn't silently 403 this RPC (#331).
grant execute on function add_product_with_allergens(
  text, text, uuid, text, text, boolean, text, uuid[], uuid[]
) to anon, authenticated;

-- Community peer-review queue (issue #54 / CR11).
--
-- Backs `CommunityReviewScreen` + `CommunityReviewController`. Each row is a
-- community-contributed allergen report for an existing product, awaiting a
-- reviewer's approve/reject decision.
--
-- `allergen_reports` is a JSONB array of `{ "allergen_id": uuid, "status":
-- 'contains' | 'may_contain' | 'absent' }` objects — the contributor's per
-- allergen breakdown. It is stored denormalised (rather than a child table)
-- because it is always read/written as one opaque blob alongside the review and
-- never queried by allergen.
create type pending_review_status as enum ('pending', 'approved', 'rejected');

create table pending_reviews (
  id uuid primary key default uuid_generate_v4(),
  product_id uuid not null references products(id) on delete cascade,
  contributor_id uuid,
  allergen_reports jsonb not null default '[]'::jsonb,
  contributor_note text,
  status pending_review_status not null default 'pending',
  rejection_reason text,
  reviewer_id uuid,
  created_at timestamptz not null default now(),
  reviewed_at timestamptz
);

create index idx_pending_reviews_status on pending_reviews(status, created_at);
create index idx_pending_reviews_contributor on pending_reviews(contributor_id);

-- No auth in the MVP (allergen profiles live client-side), so RLS is opened up
-- to the anon/authenticated roles the app actually uses. The policies are
-- defined now so the table is ready to tighten to `auth.uid()` ownership once
-- auth lands — see issue #54.
alter table pending_reviews enable row level security;

create policy "pending_reviews readable"
  on pending_reviews for select
  using (true);

create policy "pending_reviews insertable"
  on pending_reviews for insert
  with check (true);

create policy "pending_reviews updatable"
  on pending_reviews for update
  using (true)
  with check (true);

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

-- One profile row per auth user. The local SharedPreferences-only profile
-- (selected allergens, display name, filter level) is the MVP source of truth;
-- this table is the cross-device mirror to migrate it into. `is_admin` lives
-- here (server-trusted) so it can replace the client-mutable SharedPreferences
-- flag referenced in app/lib/models/user_profile.dart.
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

-- RLS: every user-owned table is locked to its owner. Without these policies an
-- enabled-RLS table denies all access, so each table gets an explicit
-- owner-only policy keyed on auth.uid().
alter table profiles  enable row level security;
alter table favorites enable row level security;
alter table reviews   enable row level security;

-- Profiles are self-owned, but deletes are NOT client-driven: the row is
-- provisioned by on_auth_user_created and must be removed only via the
-- auth.users lifecycle (cascade). Splitting the policy into select/insert/update
-- withholds the implicit delete grant a "for all" policy would confer.
create policy "profiles are self-readable"
  on profiles for select
  using (auth.uid() = id);

create policy "profiles are self-insertable"
  on profiles for insert
  with check (auth.uid() = id);

create policy "profiles are self-updatable"
  on profiles for update
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

-- Auto-provision a profile row when an auth user is created (incl. anonymous
-- sign-in), so the app never has to race a missing-profile insert on startup.
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

-- Prevent privilege escalation: the owner-only RLS policies let a user write any
-- column on their own row, which would otherwise include self-granting
-- `is_admin = true` — on UPDATE (changing the flag) or on INSERT (the
-- `handle_new_user` row can be deleted or raced, letting the client re-INSERT a
-- profile with `is_admin = true` since the self-insertable policy only checks
-- `auth.uid() = id`). This trigger freezes `is_admin` for ordinary client roles
-- (`anon` / `authenticated`) on both paths, so it can only be set by a trusted
-- backend (the `service_role` key or a superuser/admin migration). On INSERT the
-- frozen baseline is the column default (`false`); on UPDATE it is the prior
-- value — `coalesce(old.is_admin, false)` covers both since `old` is null on
-- INSERT.
create or replace function public.guard_profiles_is_admin()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
declare
  _claims jsonb;
  _baseline boolean := coalesce(old.is_admin, false);
begin
  -- Tolerate a malformed/non-JSON request.jwt.claims setting: a bad cast here
  -- would otherwise abort an ordinary profile write under security definer.
  begin
    _claims := current_setting('request.jwt.claims', true)::jsonb;
  exception when others then
    _claims := null;
  end;

  if new.is_admin is distinct from _baseline
     and _claims is not null
     and coalesce(_claims ->> 'role', '') <> 'service_role'
  then
    new.is_admin = _baseline;
  end if;
  return new;
end;
$$;

create trigger profiles_guard_is_admin
  before update on profiles
  for each row execute function public.guard_profiles_is_admin();

-- Same guard on INSERT: a client that lost its auto-provisioned row cannot
-- re-insert one with `is_admin = true` (baseline is `false` on this path).
create trigger profiles_guard_is_admin_insert
  before insert on profiles
  for each row execute function public.guard_profiles_is_admin();

-- ---------------------------------------------------------------------------
-- Server-enforced admin gate (issue #47).
--
-- `is_admin` is server-trusted: it lives on profiles, is frozen against client
-- self-escalation by guard_profiles_is_admin above, and the client sources it
-- read-only on session load (app/lib/services/profile_service.dart). The client
-- flag drives only *which UI* is shown (the admin drawer); it is NOT an
-- authority for writes. This helper + the policies below make the server the
-- authority, so a tampered client that forges its in-memory isAdmin still
-- cannot perform an admin mutation.
--
-- is_admin() returns true when the calling auth.uid() owns a profiles row with
-- is_admin = true. SECURITY DEFINER so the lookup itself isn't blocked by the
-- profiles owner-RLS, and search_path is pinned to '' per Supabase hardening
-- guidance (every reference is schema-qualified). STABLE: the result is fixed
-- within a statement, letting the planner cache it across rows.
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer set search_path = ''
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and is_admin = true
  );
$$;

-- Admin-only brand mutations. Catalog reads stay public (brands_public_read);
-- writes are gated to admins. The service_role sync scripts bypass RLS entirely
-- and are unaffected. Without these explicit policies, enabled RLS denies all
-- anon/authenticated writes — so this both *enables* the in-app admin brand
-- management and *enforces* that only admins can use it.
create policy "brands_admin_insert" on brands
  for insert with check (public.is_admin());

create policy "brands_admin_update" on brands
  for update using (public.is_admin()) with check (public.is_admin());

create policy "brands_admin_delete" on brands
  for delete using (public.is_admin());

-- ---------------------------------------------------------------------------
-- Anonymous user retention policy (issue #172).
--
-- Anonymous sign-ins (AuthService.ensureSession on cold start) accumulate in
-- auth.users. A guest that upgrades to email/OTP keeps the same id but flips
-- is_anonymous -> false, so `is_anonymous = true` is the durable "never
-- upgraded" signal. (The on_auth_user_created trigger gives every anon user a
-- profiles row, so "no profile row" can't identify abandonment.) Deleting the
-- auth user cascade-removes its profiles/favorites/reviews rows via their FKs.
--
-- Retention TTL is the function's `retention` argument (default 30 days) — the
-- single knob to change the window. The pg_cron job runs the purge daily.
-- ---------------------------------------------------------------------------
create or replace function public.purge_abandoned_anonymous_users(
  retention interval default '30 days'
)
returns bigint
language sql
security definer set search_path = ''
as $$
  with deleted as (
    delete from auth.users
    where is_anonymous = true
      and created_at < now() - retention
    returning 1
  )
  select count(*) from deleted;
$$;

-- Schedule the daily purge with pg_cron. Wrapped so the script still applies
-- on a Postgres without pg_cron (e.g. a bare local instance): it logs a notice
-- and skips scheduling instead of aborting. Idempotent — unschedules any prior
-- job of the same name before (re)creating it.
do $$
begin
  create extension if not exists pg_cron;

  if exists (
    select 1 from cron.job where jobname = 'purge-abandoned-anonymous-users'
  ) then
    perform cron.unschedule('purge-abandoned-anonymous-users');
  end if;

  perform cron.schedule(
    'purge-abandoned-anonymous-users',
    '30 3 * * *',
    $cron$ select public.purge_abandoned_anonymous_users(); $cron$
  );
exception
  when undefined_file or insufficient_privilege or feature_not_supported then
    raise notice 'pg_cron unavailable — skipping purge schedule; run public.purge_abandoned_anonymous_users() via an external scheduler';
  when invalid_schema_name or undefined_table then
    raise notice 'cron schema unavailable — skipping purge schedule';
end;
$$;
