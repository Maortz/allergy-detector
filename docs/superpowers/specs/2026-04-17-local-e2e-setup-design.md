# Local E2E Setup Design

## Goal
Enable running the Allergy Detector app end-to-end locally with:
- A working demo you can click through (onboard → search → view product → report)
- Automated integration tests against a real database

## Approach

### 1. Local Supabase via Docker

**What:** Run Supabase locally using Docker instead of the cloud instance.

**Setup:**
1. Run `supabase init` to generate config files
2. Run `supabase start` to launch local Docker containers (Postgres, GoTrue, PostgREST, Storage)
3. Apply schema and seed data

**Environment handling:**
- Add `.env.local` for local development:
  ```
  SUPABASE_URL=http://127.0.0.1:54321
  SUPABASE_PUBLIC_API_KEY=<local-anon-key>
  ```
- App's `main.dart` loads `.env.local` first, falls back to `.env`

This allows cloud and local to coexist without conflicts.

**Commands:**
```bash
supabase start      # Start local Supabase
supabase stop       # Stop when done
```

---

### 2. Data Scraper (foodsdictionary.co.il)

**What:** A Python script to scrape ~30 real Israeli products with their allergens and barcodes.

**Script:** `scripts/scraper-foodsdictionary.py`

**Why Python:**
- `requests` + `BeautifulSoup` for HTML parsing
- Good Hebrew encoding handling
- Can output CSV or direct to Supabase REST API

**Scraping strategy:**
- Search by Hebrew food categories (snacks, dairy, bakery, etc.)
- Parse product names, allergen info, barcodes from HTML
- Cap at ~30 products
- Map Hebrew allergen names to our `allergens` table IDs

**Error handling:**
- Skip products with missing data
- Log warnings for unmapped allergens
- Support `--dry-run` flag (like OFF import script)

**Output:**
- Direct to Supabase via REST API
- Or CSV with `--csv` flag for manual review

---

### 3. Navigation Wiring

**What:** Connect the isolated screens into a working flow.

**Changes:**

1. **SearchScreen → ProductDetailsScreen**
   - Wrap `ProductCard` in `InkWell`
   - On tap: `Navigator.push` to `ProductDetailsScreen`
   - Pass `userProfile` and `allergens` for status computation

2. **ProductCard → FeedbackScreen**
   - Connect `onReport` callback to navigation
   - Pass `productId` and `productName`

3. **ProductDetails → FeedbackScreen**
   - Already has `onReport` param, wire up navigation

4. **State persistence:** Filter toggle state persists across navigation (handled by existing `userProfile`)

---

### 4. Integration Tests

**What:** Flutter integration tests that exercise the full app against local Supabase.

**Test files:**
- `test_integration/full_flow_test.dart` — complete user journey
- `test_integration/offline_test.dart` — offline fallback behavior
- `test_integration/search_filter_test.dart` — filter toggle works

**Setup script:** `scripts/setup_test_db.py` (Python, cross-platform)
- Checks Supabase is running
- Applies `schema.sql` + `seed.sql` via REST API
- Works on Windows, macOS, Linux

**Running:**
```bash
python scripts/setup_test_db.py --apply-schema --apply-seed
flutter test test_integration/
```

**Framework:** Flutter's built-in `integration_test` package (runs against real app, not mocked).

---

## Deliverables

| File | Description |
|------|-------------|
| `supabase/config.toml` | Supabase local config (auto-generated) |
| `.env.local` | Local Supabase environment vars |
| `scripts/scraper-foodsdictionary.py` | Hebrew product scraper (30 products) |
| `scripts/setup_test_db.py` | Cross-platform test DB setup |
| `app/test_integration/` | Integration test files |
| `app/lib/screens/search_screen.dart` | Navigation wiring |
| `app/lib/widgets/product_card.dart` | Navigation wiring |

---

## Dependencies

- Docker (for Supabase)
- Python 3.x (for scraper + setup script)
- Flutter SDK (for running app + tests)
- `requests`, `beautifulsoup4` Python packages

---

## Spec Self-Review

- ✓ No placeholders (TBD, TODO)
- ✓ Internal consistency (all sections align)
- ✓ Scope focused on single implementation goal
- ✓ Ambiguity resolved (clear deliverables)

---

## Timeline Estimate

1. Local Supabase setup: 15 min
2. Schema + seed to local: 10 min
3. Scraper (30 products): 45 min
4. Navigation wiring: 30 min
5. Integration tests: 45 min

Total: ~2.5 hours