# Gemini Project Context: Allergy Detector

This project is a cross-platform (Flutter) application designed to help users detect allergens in products. It features a Hebrew/RTL-first interface and integrates with Supabase for the backend.

## Project Overview

- **Purpose:** Provide real-time allergen detection and product information for users with food allergies.
- **Main Technologies:**
  - **Frontend:** Flutter (Dart), focusing on Android, iOS, and Web.
  - **Backend:** Supabase (Postgres for the database, Storage for images, and future Auth).
  - **Data Integration:** Imports data from Open Food Facts.
  - **State Management:** Uses the `Provider` package for state management.
  - **Localization:** Hebrew-first (RTL support) with localized error messages.

## Core Architecture

- **`app/lib/`**: Contains the main Flutter application logic.
  - **`models/`**: Data classes (Allergen, Product, UserProfile).
  - **`screens/`**: UI screens (Onboarding, Search, ProductDetails, etc.).
  - **`services/`**: Logic for interacting with Supabase and local storage (ProductService, AllergenService).
  - **`widgets/`**: Reusable UI components (ProductCard, AllergenChip).
  - **`theme/`**: App-wide styling, colors, and typography.
- **`supabase/`**: Database management files.
  - **`schema.sql`**: Defines the Postgres schema (brands, allergens, products, feedback).
  - **`seed.sql`**: Initial data for allergens and sample products.
- **`scripts/`**: Dart CLI tools for administrative tasks and data imports.
- **`docs/`**: Detailed design specifications, architecture diagrams, and moderation guides.

## Building and Running

### Prerequisites
- Flutter SDK
- Supabase CLI or a Supabase cloud project.
- Node.js (for potential root-level utility scripts).

### Commands
- **Install Dependencies:** `cd app && flutter pub get`
- **Run Application:** `cd app && flutter run` (Use `-d chrome` for web).
- **Run Tests:** `cd app && flutter test`
- **Database Setup:** Apply `supabase/schema.sql` followed by `supabase/seed.sql` in your Supabase SQL editor.

## Development Conventions

- **Operating System:** Windows.
- **Shell Interaction:** Use PowerShell for all shell commands.
- **RTL Support:** The application is Hebrew-first. Always ensure UI changes support Right-to-Left layouts.
- **Service Pattern:** Business logic and external API calls should reside in the `lib/services/` directory.
- **Theme Usage:** Use `AppTheme` and `AppColors` for consistent styling. Avoid hardcoded colors or font sizes.
- **Null Safety:** Strict null safety is required throughout the Dart codebase.
- **Documentation:** Maintain design specs in `docs/` and use comments for complex logic in `lib/`.
- **Environment Variables:** Use `.env` for Supabase credentials (refer to `.env.example`). Never commit sensitive keys.

## Testing Strategy
- **Unit Tests:** Located in `app/test/unit/` for logic and models.
- **Widget Tests:** Located in `app/test/widgets/` for UI component validation.
- **Integration Tests:** Located in `app/integration_test/` for full flow verification.
- **Mocks:** Use `mockito` for mocking services in tests.
