# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

All Flutter commands run from the `app/` directory. Use PowerShell on Windows.

```powershell
cd app
flutter pub get          # install dependencies
flutter analyze          # lint (Dart analyzer covers type checking too)
flutter test             # run all tests
flutter test test/allergen_card_test.dart  # run single test file
flutter run -d chrome    # web
flutter run -d android   # Android
```

Pass Supabase credentials via `--dart-define` (they are read with `String.fromEnvironment`):
```powershell
flutter run --dart-define=SUPABASE_URL=<url> --dart-define=SUPABASE_KEY=<anon_key> -d chrome
```

Database: apply `supabase/schema.sql` then `supabase/seed.sql` in the Supabase SQL Editor, or run `supabase start` locally via the Supabase CLI from the `supabase/` directory.

## Architecture

The app is a **Hebrew/RTL-first Flutter app** (Android, iOS, Web) backed by Supabase. No authentication in MVP — allergen profiles are stored locally via SharedPreferences.

**Startup flow** (`main.dart → AppShell`):
1. Supabase is initialized from `--dart-define` env vars.
2. `AppShell` loads `UserProfile` from SharedPreferences and fetches the allergen catalog from Supabase.
3. If `has_completed_onboarding` is false → shows `OnboardingScreen`; otherwise → shows `MainContainer`.
4. Profile updates bubble up via `ValueChanged<UserProfile>` callbacks from any screen back to `AppShell`, which persists them to SharedPreferences.

**Navigation** (`MainContainer`): `IndexedStack` with a `NavigationBar` — four tabs: Home, Search/Scan, Community, Settings. The FAB on Home navigates to Search/Scan.

**Search/Scan flow**:
- `SearchScanScreen` hosts a search input and barcode scanner (via `ScannerService` wrapping `mobile_scanner`, platform-aware/web-safe).
- Typing opens `ActiveSearchScreen` as an overlay.
- `ProductService.searchProducts()` queries Supabase `products` joined with `brands`, then does a second query on `product_allergens` for the returned product IDs.
- Results are cached in `SearchCache` (30-min TTL, SharedPreferences-backed).

**Allergen status computation** (`ProductCard.status`):
- Compares `product.containsAllergens` / `product.mayContainAllergens` against `userProfile.selectedAllergenIds`.
- Any `contains` match → **Avoid** (red); any `may_contain` match → **Caution** (orange); otherwise → **Safe** (green).

**State management**: hybrid — `StatefulWidget` for UI state, SharedPreferences for persistence, `ValueChanged` callbacks to propagate profile changes up to `AppShell`. No Provider/Bloc usage for the main profile flow (Provider is a listed dep but not the primary pattern).

**Services** (`app/lib/services/`) receive a `SupabaseClient` in their constructor — they are not singletons and are instantiated inline in screens.

## Stitch MCP

The Stitch MCP server is connected and provides UI design tools. The active project is **"Duplicate of SafeScan Allergy Guard"** (project ID `16588854804615693446`). The design system is **"Clinical Clarity RTL"** — Medical Blue primary (`#00478D`), Public Sans headings, Inter body, 4px spacing grid, RTL-first.

Key tools:
- `mcp__stitch__list_screens` — list all screens in a project
- `mcp__stitch__get_screen` — fetch a screen's design (use for reference before implementing UI)
- `mcp__stitch__generate_screen_from_text` — generate a new screen from a text prompt
- `mcp__stitch__edit_screens` — edit existing screens with a text prompt

Always pass `projectId: "16588854804615693446"` unless working in the older duplicate (`7851463773306565726`).

## Key conventions

- All UI text is hard-coded Hebrew. RTL is enforced via `Directionality(textDirection: TextDirection.rtl)` wrapping the app and key sub-trees.
- Use `AppColors`, `AppTypography`, and `AppSpacing` from `app/lib/theme/` — no hardcoded colors or font sizes.
- Windows platform support was intentionally removed (see `pubspec.yaml` comment and deleted `windows/` files in git status).
- Tests use `mockito` — run `dart run build_runner build` if mocks need regenerating after model changes.
- Admin/data tools live in `scripts/` (Dart CLI): `admin-sync.dart` and `import-openfoodfacts.dart`.

## Operational notes (learned the hard way)

- **Never `pumpAndSettle` in `search_scan_screen_test.dart`.** `SearchScanScreen` creates `_laserController = AnimationController(...)..repeat(reverse: true)` in `initState` (`app/lib/screens/search_scan_screen.dart`). `pumpAndSettle` waits for all animations to finish and will time out. Section headers render on the first frame, so `await tester.pumpWidget(...)` alone is sufficient — every passing test in that file follows this pattern.
- **Don't redirect native-exe stderr with `2>&1` in the PowerShell tool.** Windows PowerShell 5.1 wraps each stderr line in a `NativeCommandError` `ErrorRecord` and sets the call's exit code to 1 even when the exe returned 0 (e.g. `flutter analyze` printing its summary to stderr). stderr is already captured for you. Use `flutter analyze | Select-Object -Last 5`, not `flutter analyze 2>&1 | Select-Object -Last 5`.
- **`flutter`/`dart`/`gradlew` run from `app/`, not the repo root.** When a tool call's working directory is already `app/`, prefixing `cd app` makes it fail with `app\app does not exist`. Check CWD first, or use absolute paths. Database/schema work runs from `supabase/`; admin scripts run from `scripts/`.
