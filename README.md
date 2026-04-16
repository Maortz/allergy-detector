# Allergy Detector App

A cross-platform (Flutter) allergy detector app — Hebrew/RTL first — that lets users select allergens, search products in real time, and get clear safe/avoid/caution cues.

## Features (MVP)
- No-login onboarding: select your allergens
- Live product search with typeahead (Supabase-backed)
- Product cards: image, brand/trust badge, contains/may-contain allergens, color-coded status
- Product detail view with full allergen breakdown
- Community feedback/reporting with anti-spam rate-limiting
- Offline support: cached search results with stale-data banner
- Hebrew error messages with retry buttons
- Admin moderation via Supabase Dashboard + Dart CLI scripts

## Getting Started

### 1. Prerequisites
- Flutter SDK: [Install Flutter](https://docs.flflutter.dev/get-started/install)
- Supabase Account: [Supabase Signup](https://app.supabase.com/)
- Git: [Install Git](https://git-scm.com/)

### 2. Clone & Environment Setup
```
git clone <repo-url>
cd allergy-detector
cp .env.example .env
```
Edit `.env` with your Supabase URL and public API key. Never commit `.env`!

### 3. Flutter
```
cd app
flutter pub get
flutter doctor
```

### 4. Supabase Backend
- Go to the [Supabase dashboard](https://app.supabase.com/)
- Create a new project
- Apply the schema from `supabase/schema.sql` via the SQL Editor
- Apply the seed data from `supabase/seed.sql`
- Enable Row-Level Security on all tables (open for MVP, restrict later)
- Create a Storage bucket named `product-images` (public read, authenticated write)

### 5. Running the App
```
cd app
flutter run -d chrome      # For web
flutter run -d android     # For Android
flutter run -d ios         # For iOS (Mac only)
```

### 6. Running Tests
```
cd app
flutter test
```

## Project Structure
```
allergy-detector/
├── app/                        # Flutter app
│   ├── lib/
│   │   ├── main.dart           # App entry, routing, Supabase init
│   │   ├── models/             # Allergen, Product, UserProfile
│   │   ├── screens/            # Onboarding, Search, ProductDetails, Feedback
│   │   ├── services/           # AllergenService, ProductService, FeedbackService, SearchCache
│   │   └── widgets/            # ProductCard
│   └── test/                   # Unit & widget tests
├── supabase/
│   ├── schema.sql              # Database schema (junction table, enums, indexes)
│   └── seed.sql                # Allergen catalog + sample data
├── scripts/
│   ├── admin-sync.dart         # Admin CLI tool
│   └── import-openfoodfacts.dart  # OFF import pipeline
├── docs/
│   ├── admin/moderation-guide.md
│   └── superpowers/specs/      # Design specs, ER diagram, architecture
├── .env.example                # Template for environment variables
└── .gitignore
```

## Tech Stack
- **Frontend:** Flutter (Dart, Android/iOS/Web, RTL/Hebrew)
- **Backend:** Supabase (Postgres, Storage, Auth)
- **Data Source:** Open Food Facts (import/sync)
- **Testing:** Flutter test framework (widget + unit tests)

## Documentation
- Design spec: `docs/superpowers/specs/2026-04-15-allergy-detector-design.md`
- ER diagram: `docs/superpowers/specs/2026-04-15-allergy-detector-design-assets/er-diagram.md`
- Architecture: `docs/superpowers/specs/2026-04-15-allergy-detector-design-assets/architecture-diagram.md`
- Infra setup: `docs/superpowers/specs/2026-04-15-allergy-detector-infra-setup.md`
- Admin guide: `docs/admin/moderation-guide.md`
- Implementation plan: `docs/superpowers/plans/2026-04-15-allergy-detector-mvp.md`
