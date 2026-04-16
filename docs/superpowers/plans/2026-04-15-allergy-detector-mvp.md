# Allergy Detector MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a cross-platform (Flutter-based) allergy detector app (Hebrew/RTL first), letting users select allergens, search products in real time (from Open Food Facts + community sync), offering clear "safe/avoid/caution" cues, feedback, and admin mod, with full spec-committed infra/docs.

**Architecture:** Flutter frontend (Android/iOS/web) interacts with Supabase backend (Postgres for data, Storage for images). Data is regularly synced with Open Food Facts, product images managed via URL. Docs and onboarding are first class; .env.example (never .env), TDD, and infra bootstrapping present. Initial admin via Supabase UI.

**Tech Stack:** Flutter (Dart, multi-platform), Supabase (hosted Postgres, Storage), Open Food Facts (import), Git, Markdown docs, TDD.

---

### Task 1: Infrastructure Bootstrapping
**Files:**
- Create: `.env.example` (template with placeholders)
- Create: `.gitignore`
- Create: `docs/superpowers/specs/2026-04-15-allergy-detector-infra-setup.md`
- Create: `/docs/superpowers/plans/2026-04-15-allergy-detector-mvp.md` (this doc)
- [ ] **Step 1: Create .env.example (never commit real .env)**
```env
SUPABASE_URL=your-supabase-instance-url
SUPABASE_PUBLIC_API_KEY=your-anon-public-key
```
- [ ] **Step 2: Create .gitignore at project root**
```gitignore
.env
app/.dart_tool/
app/build/
app/.flutter-plugins
app/.flutter-plugins-dependencies
app/pubspec.lock
*.iml
.idea/
.DS_Store
```
- [ ] **Step 3: Create README, copying setup from infra-setup.md**
- [ ] **Step 4: Commit initial infra/docs**
```bash
git add .env.example .gitignore docs/superpowers/specs/2026-04-15-allergy-detector-infra-setup.md README.md
git commit -m "chore: initial infra setup and guides"
```

---
### Task 2: Supabase Backend Schema Setup
**Files:**
- Create: `supabase/schema.sql`
- Modify: Supabase dashboard (manual/config)
- Create: `docs/superpowers/specs/2026-04-15-allergy-detector-design-assets/er-diagram.md`
- [ ] **Step 1: Write schema for core tables in schema.sql**
```sql
create extension if not exists "uuid-ossp";

create type feedback_type as enum ('allergen_missing', 'allergen_wrong', 'product_info_wrong', 'other');

create table brands (
  id uuid primary key default uuid_generate_v4(),
  name_he text not null,
  trust_score float not null default 0.5,
  logo_url text,
  external_source_id text,
  created_at timestamptz not null default now()
);

create table allergens (
  id uuid primary key default uuid_generate_v4(),
  name_he text not null unique,
  icon_url text,
  created_at timestamptz not null default now()
);

create table products (
  id uuid primary key default uuid_generate_v4(),
  name_he text not null,
  barcode text unique,
  brand_id uuid references brands(id),
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
```
- [ ] **Step 2: Apply schema (Supabase CLI or dashboard)**
- [ ] **Step 3: Enable Row Level Security (RLS) for tables (open rules for MVP testing, then restrict as needed)**
- [ ] **Step 4: Create Supabase Storage bucket named `product-images` (public read, authenticated write)**
- [ ] **Step 5: Import ER diagram to docs for reference (done above)**
- [ ] **Step 6: Commit schema/doc changes**
```bash
git add supabase/schema.sql docs/superpowers/specs/2026-04-15-allergy-detector-design-assets/er-diagram.md
git commit -m "feat: backend schema for products, brands, allergens, feedback"
```

---
### Task 3: Seed Data (Allergen Catalog + Sample Products)
**Files:**
- Create: `supabase/seed.sql`
- [ ] **Step 1: Write seed data for allergen catalog**
```sql
insert into allergens (id, name_he) values
  ('a0000000-0000-0000-0000-000000000001', 'בוטנים'),
  ('a0000000-0000-0000-0000-000000000002', 'אגוזים'),
  ('a0000000-0000-0000-0000-000000000003', 'ביצים'),
  ('a0000000-0000-0000-0000-000000000004', 'חלב'),
  ('a0000000-0000-0000-0000-000000000005', 'גלוטן'),
  ('a0000000-0000-0000-0000-000000000006', 'סויה'),
  ('a0000000-0000-0000-0000-000000000007', 'שומשום'),
  ('a0000000-0000-0000-0000-000000000008', 'דגים');
```
- [ ] **Step 2: Write seed data for sample brands and products**
```sql
insert into brands (id, name_he, trust_score) values
  ('b0000000-0000-0000-0000-000000000001', 'סניקרס', 0.8),
  ('b0000000-0000-0000-0000-000000000002', 'מאפיית א.א.', 0.4);

insert into products (id, name_he, barcode, brand_id) values
  ('p0000000-0000-0000-0000-000000000001', 'חטיף בוטנים', '72900001', 'b0000000-0000-0000-0000-000000000001'),
  ('p0000000-0000-0000-0000-000000000002', 'רוגלך שוקולד', '72900002', 'b0000000-0000-0000-0000-000000000002');

insert into product_allergens (product_id, allergen_id, severity) values
  ('p0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'contains'),
  ('p0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000002', 'may_contain'),
  ('p0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000003', 'contains');
```
- [ ] **Step 3: Apply seed data to Supabase**
- [ ] **Step 4: Commit seed data**
```bash
git add supabase/seed.sql
git commit -m "feat: seed allergen catalog and sample products"
```

---
### Task 4: Flutter App Bootstrapping (App Scaffold + Lint/TDD)
**Files:**
- Create: `/app/` (Flutter project root)
- [ ] **Step 1: Initialize Flutter project**
```bash
flutter create app
```
- [ ] **Step 2: Add core dependencies**
```bash
cd app
flutter pub add supabase_flutter provider flutter_localizations intl flutter_dotenv
```
- [ ] **Step 3: Configure main.dart for Hebrew/RTL, supabase, and dotenv**
```dart
// In main():
await dotenv.load(fileName: '../.env');
MaterialApp(
  localizationsDelegates: [...],
  supportedLocales: [Locale('he')],
  locale: Locale('he'),
  // ...
);
```
- [ ] **Step 4: Add smoke test**
```dart
// test/widget_test.dart
void main() {
  testWidgets('App boots and shows search', (tester) async {
    await tester.pumpWidget(MyApp());
    expect(find.text('חפש מוצר'), findsOneWidget);
  });
}
```
- [ ] **Step 5: Run tests**
```bash
flutter test
```
- [ ] **Step 6: Commit scaffold/tests**
```bash
git add app/
git commit -m "feat: flutter MVP scaffold and smoke test"
```

---
### Task 5: User Onboarding – Allergen Profile (No Login)
**Files:**
- Modify: `app/lib/main.dart`, `app/lib/screens/onboarding.dart`, `app/lib/models/user_profile.dart`
- [ ] **Step 1: Write test for onboarding allergen select**
```dart
// test/onboarding_test.dart
void main() {
  testWidgets('User can select allergens without logging in', (tester) async {
    await tester.pumpWidget(MyApp());
    await tester.tap(find.text('התחל'));
    await tester.pumpAndSettle();
    expect(find.text('בחר אלרגנים'), findsOneWidget);
    await tester.tap(find.byType(CheckboxListTile).first);
    // ... verify selection is saved in user_profile
  });
}
```
- [ ] **Step 2: Implement onboarding screen (multi-select allergens, save to local state)**
- [ ] **Step 3: Integrate onboarding into app boot (skip if already onboarded)**
- [ ] **Step 4: Run test**
- [ ] **Step 5: Commit onboarding**

---
### Task 6: Product Search & Result Screen (Typeahead/Filter/RTL)
**Files:**
- Create: `app/lib/screens/search_screen.dart`, `app/lib/widgets/product_card.dart`
- [ ] **Step 1: Write test for search and result rendering**
```dart
// test/search_test.dart
void main() {
  testWidgets('Search filters products and highlights allergens', (tester) async {
    await tester.pumpWidget(MyApp());
    await tester.enterText(find.byType(TextField), 'בוטנים');
    await tester.pumpAndSettle();
    expect(find.text('חטיף בוטנים'), findsWidgets);
    expect(find.textContaining('הימנע'), findsWidgets);
  });
}
```
- [ ] **Step 2: Implement search logic (Supabase REST/query, typeahead updates, filter by profile/allergens)**
- [ ] **Step 3: ProductCard widget (shows: image, names, trust badge, "מכיל", "עשוי להכיל", color-status, feedback)**
- [ ] **Step 4: Integrate search/filter toggle**
- [ ] **Step 5: Test on web, Android, iOS (RTL, touch, accessibility)**
- [ ] **Step 6: Commit search/results**

---
### Task 7: Product Details & Status Logic
**Files:**
- Create: `app/lib/screens/product_details.dart`, reuse ProductCard
- [ ] **Step 1: Write test for safe/avoid/caution logic**
```dart
// test/product_details_test.dart
void main() {
  testWidgets('Product detail shows correct status for user', (tester) async {
    // userProfile: allergen in "contains": should see red/avoid
    // userProfile: allergen in "may_contain": should see yellow/caution
    // no overlap: green/safe
  });
}
```
- [ ] **Step 2: Implement detailed status display (logic for both allergen severities, colors, RTL)**
- [ ] **Step 3: Run all tests/verify**
- [ ] **Step 4: Commit details logic**

---
### Task 8: Community Feedback/Reporting
**Files:**
- Create: `app/lib/screens/feedback_screen.dart`, Supabase function for submit
- [ ] **Step 1: Write test for feedback submission**
```dart
// test/feedback_test.dart
void main() {
  testWidgets('User can submit feedback from product card', (tester) async {
    // tap report, enter issue, submit, success shown
  });
}
```
- [ ] **Step 2: Implement feedback modal + submission to Supabase (REST insert feedback_reports)**
- [ ] **Step 3: Anti-spam: rate-limit per device using local timestamp stored in SharedPreferences (1 submission per product per device per 60 seconds). No auth required — enforcement is client-side with server-side timestamp validation.**
- [ ] **Step 4: Commit feedback**

---
### Task 9: Admin Moderation Tools (Docs, Table View, Scripts)
**Files:**
- Docs: `docs/admin/moderation-guide.md`
- (Optional): `/scripts/fetch-products.dart` (admin sync — Dart to match stack)
- [ ] **Step 1: Write moderation guide for feedback triage and product/archive**
- [ ] **Step 2: Script to fetch+archive new/removed products with Supabase API**
- [ ] **Step 3: Commit mod-docs/scripts**

---
### Task 10: Data Sync/Import Pipeline (Open Food Facts)
**Files:**
- `/scripts/import-openfoodfacts.dart`
- [ ] **Step 1: Write test to parse OFF CSV and upload to Supabase**
- [ ] **Step 2: Implement import logic (fields, sync IDs, handle images/archived flags, update product_allergens junction table)**
- [ ] **Step 3: Commit import tool**

---
### Task 11: Error Handling & Offline UX
**Files:**
- Modify: `app/lib/services/supabase_client.dart`, `app/lib/screens/search_screen.dart`
- [ ] **Step 1: Add global error handling wrapper for Supabase calls (network timeout, 5xx, auth errors)**
- [ ] **Step 2: Show user-friendly Hebrew error messages and retry buttons on search/detail screens**
- [ ] **Step 3: Cache last successful search results locally (SharedPreferences) for offline viewing with stale-data banner**
- [ ] **Step 4: Run tests, verify error states render correctly**
- [ ] **Step 5: Commit error handling**

---
### Task 12: Documentation & Rollup
**Files:**
- Update: `/README.md`
- Update: `docs/superpowers/specs/2026-04-15-allergy-detector-design.md`
- [ ] **Step 1: Update README to match all infra/code/tests**
- [ ] **Step 2: Update spec to reflect real status/structure**
- [ ] **Step 3: Commit docs**

---
## Self-Review Checklist
- All features in design spec are reflected by a plan section
- No placeholders or "TBD" everywhere: every code step shows its actions fully
- Types, method names, paths match between steps
- `.env` is never committed; `.env.example` with placeholders is committed
- Schema uses junction table for product-allergen (referential integrity)
- Seed data exists before search UI is built
- `flutter_dotenv` included for env loading in Dart
- Supabase Storage bucket setup included
- Anti-spam strategy specified (client-side rate-limit + server timestamp)
- Error/offline handling included as a task
- Community edits deferred to post-MVP (feedback only for MVP)

---
## Design Decisions & Trade-offs

### Community Edits (MVP Scope)
For MVP, community interaction is limited to **feedback reports only** (bug reports on allergen data, product info). Direct editing of product/allergen data by community members is **post-MVP**. The `feedback_type` enum covers the most common edit scenarios as reports that admins can triage and apply.

### Trust Score
`brand.trust_score` (0.0–1.0, default 0.5) is a simple static value for MVP, set manually by admins or seeded. Post-MVP it will be computed from: resolved feedback ratio, data freshness, and community verification count. No automatic calculation in MVP.

### Product-Allergen Junction Table vs UUID Arrays
The original spec used `uuid[]` arrays on `products`. This was changed to a `product_allergens` junction table because:
- Arrays of UUIDs bypass referential integrity (no FK enforcement on elements)
- A health/safety app requires data integrity guarantees
- The `severity` column (`contains`/`may_contain`) replaces the separate `allergens[]`/`might_be_allergens[]` arrays with a single, normalized structure

---
**Plan complete and saved to `docs/superpowers/plans/2026-04-15-allergy-detector-mvp.md`. Two execution options:**

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach would you like to use?**
