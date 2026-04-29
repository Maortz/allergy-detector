# AGENTS.md - Allergy Detector

## Commands

```bash
# Flutter app
cd app
flutter test              # Run all tests
flutter run -d chrome     # Run web
flutter run -d android    # Run Android

# Supabase local
cd supabase
supabase start           # Start local DB (ports: 54321 API, 54322 DB, 54323 Studio)
```

## Env Setup

- Copy `.env.example` to `.env` at project root
- Add your Supabase URL and anon key
- The `.env` file is bundled as a Flutter asset (see pubspec.yaml line 68)
- Load in Dart: `await dotenv.load(fileName: '../.env')`

## Architecture

- **Frontend**: Flutter (Dart), Hebrew/RTL, Provider for state
- **Backend**: Supabase (Postgres + Storage)
- **Data flow**: Products come from Open Food Facts, imported via `scripts/import-openfoodfacts.dart`
- **No auth required** for MVP (onboarding saves allergen profile locally via SharedPreferences)

## Key Files

- `supabase/schema.sql` - Database tables (products, allergens, brands, product_allergens, feedback_reports)
- `app/lib/main.dart` - App entry, routing, Supabase init
- `scripts/admin-sync.dart` - Admin CLI for product sync
- `scripts/import-openfoodfacts.dart` - Import products from Open Food Facts API

## Data Sources Investigated

### Open Food Facts (Primary)
- **API**: `https://il.openfoodfacts.org/api/v2/product/{barcode}.json`
- **Allergens**: ✓ Has 45 allergens (gluten: 76 products, milk: 73, soy: 61, nuts: 30, sesame: 21, etc.)
- **Ingredients**: Partial - many Israeli products are incomplete
- **Brand**: ✓ Available
- **Pros**: Simple API, free, open data
- **Cons**: Some Israeli products missing ingredients/allergens

### OpenIsraeliSupermarkets
- Scrapes gov.il published data (prices, stores only)
- **Allergens**: ✗ Not available

### Shufersal Official API
- Endpoint: `shufersalb2capi.verifone.co.il`
- **Allergens**: ✗ Not available (only ordering/delivery)

### shufersal-automation (Backup)
- Node.js Puppeteer library for Shufersal online store
- Could extract allergens from product pages
- Status: Backup option if Open Food Facts insufficient

## Testing

- Tests live in `app/test/`
- Run `flutter test` in `app/` directory
- Widget tests use `tester.pumpWidget()`, unit tests import directly