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

## Testing

- Tests live in `app/test/`
- Run `flutter test` in `app/` directory
- Widget tests use `tester.pumpWidget()`, unit tests import directly