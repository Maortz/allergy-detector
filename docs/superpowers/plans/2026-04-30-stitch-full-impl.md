# SafeScan Stitch Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the Flutter app to match the Stitch "Clinical Clarity RTL" design — complete 20 screens, full design system, proper typography, status badges, RTL layout, and community flows.

**Architecture:** A complete ground-up rewrite of the UI layer. Replace existing screens with Stitch-aligned screens. Add shared design system constants (colors, typography, spacing, components). Keep existing models, services, and Supabase integration intact.

**Tech Stack:** Flutter (Dart), Stitch MCP (design reference), Supabase (backend), SharedPreferences (local), google_fonts (Public Sans + Inter), flutter_animate (optional animations).

---

## File Structure

```
app/lib/
  main.dart                          # App entry, routing, theme
  theme/
    app_theme.dart                   # Clinical Clarity RTL design tokens
    app_colors.dart                # All color constants
    app_typography.dart          # Font styles
    app_spacing.dart              # Spacing constants (4px base grid)
  screens/
    home_screen.dart              # Task 1: Home Dashboard (בטוח לאכול)
    search_scan_screen.dart       # Task 2: Search & Scan + Barcode
    onboarding_screen.dart       # Task 3: Onboarding (Allergen Selection)
    product_details_screen.dart  # Task 4: Product Details
    add_product_screen.dart     # Task 5: Add Product Wizard (4 steps)
    community_screen.dart      # Task 6: Community Hub
    settings_screen.dart      # Task 7: Settings & Profile
    feedback_success_screen.dart # Task 8: Feedback Success
    review_next_screen.dart      # Task 9: Review Next Item
    contact_screen.dart         # Task 10: Contact Us
    admin_brands_screen.dart    # Task 11: Admin Manage Brands
    drawer_user_screen.dart     # Task 12: User Navigation Drawer
    drawer_admin_screen.dart   # Task 13: Admin Navigation Drawer
  widgets/
    bottom_nav_bar.dart        # Shared: 4-tab bottom nav (בית, סריקה, קהילה, מועדפים)
    top_app_bar.dart         # Shared: top app bar with menu + profile
    allergen_card.dart      # Shared: allergen selection card (grid)
    allergen_chip.dart      # Shared: allergen chip badge (pill)
    status_badge.dart      # Shared: safe/caution/avoid pill badge
    product_card.dart      # Shared: product list item card
    brand_card.dart       # Shared: brand admin list item
    photo_upload_card.dart  # Shared: photo upload dashed card
    progress_stepper.dart  # Shared: 4-step progress indicator
    search_input.dart     # Shared: RTL search input with icon on right
    navigation_drawer.dart # Shared: RTL right-side drawer
    bento_card.dart      # Shared: bento-style stat card
    all_clear_banner.dart # Shared: "הכל נבדק!" success banner
  models/
    (keep existing — already defined)
  services/
    (keep existing — already defined)
```

---

## Design System (from Stitch HTML)

### Colors

```dart
// app/lib/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary: Medical Blue
  static const Color primary = Color(0xFF00478d);
  static const Color primaryContainer = Color(0xFF005eb8);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFFC8DAFF);
  static const Color primaryFixed = Color(0xFFD6E3FF);
  static const Color primaryFixedDim = Color(0xFFA9C7FF);
  static const Color onPrimaryFixed = Color(0xFF001B3D);
  static const Color onPrimaryFixedVariant = Color(0xFF00468C);

  // Secondary: Fresh Green
  static const Color secondary = Color(0xFF006B5B);
  static const Color secondaryContainer = Color(0xFF78F8DD);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF007261);
  static const Color secondaryFixed = Color(0xFF78F8DD);
  static const Color secondaryFixedDim = Color(0xFF59DBC1);
  static const Color onSecondaryFixed = Color(0xFF00201A);
  static const Color onSecondaryFixedVariant = Color(0xFF005144);

  // Tertiary
  static const Color tertiary = Color(0xFF404850);
  static const Color tertiaryContainer = Color(0xFF576068);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFFD1DAE4);
  static const Color tertiaryFixed = Color(0xFFDBE4ED);
  static const Color tertiaryFixedDim = Color(0xFFBFC8D0);
  static const Color onTertiaryFixed = Color(0xFF141D23);
  static const Color onTertiaryFixedVariant = Color(0xFF3F484F);

  // Surface layers
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFF8F9FA);
  static const Color surfaceBright = Color(0xFFF8F9FA);
  static const Color surfaceDim = Color(0xFFD9DADB);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF3F4F5);
  static const Color surfaceContainer = Color(0xFFEDEEEF);
  static const Color surfaceContainerHigh = Color(0xFFE7E8E9);
  static const Color surfaceContainerHighest = Color(0xFFE1E3E4);
  static const Color surfaceVariant = Color(0xFFE1E3E4);
  static const Color surfaceTint = Color(0xFF005DB6);
  static const Color onSurface = Color(0xFF191C1D);
  static const Color onSurfaceVariant = Color(0xFF424752);

  // Outline
  static const Color outline = Color(0xFF727783);
  static const Color outlineVariant = Color(0xFFC2C6D4);

  // Error
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF93000A);

  // Inverse
  static const Color inverseSurface = Color(0xFF2E3132);
  static const Color inverseOnSurface = Color(0xFFF0F1F2);
  static const Color inversePrimary = Color(0xFFA9C7FF);

  // Status badge colors (specific hex from designMd)
  static const Color safeBackground = Color(0xFFE6F4EA);
  static const Color safeText = Color(0xFF1E8E3E);
  static const Color cautionBackground = Color(0xFFFEF7E0);
  static const Color cautionText = Color(0xFFB05B00);
  static const Color avoidBackground = Color(0xFFFCE8E6);
  static const Color avoidText = Color(0xFFD93025);
}
```

### Typography

```dart
// app/lib/theme/app_typography.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static TextStyle get h1 => GoogleFonts.publicSans(
    fontSize: 30, fontWeight: FontWeight.w700, height: 38 / 30,
  );
  static TextStyle get h2 => GoogleFonts.publicSans(
    fontSize: 24, fontWeight: FontWeight.w600, height: 32 / 24,
  );
  static TextStyle get h3 => GoogleFonts.publicSans(
    fontSize: 20, fontWeight: FontWeight.w600, height: 28 / 20,
  );
  static TextStyle get bodyLg => GoogleFonts.inter(
    fontSize: 18, fontWeight: FontWeight.w400, height: 28 / 18,
  );
  static TextStyle get bodyMd => GoogleFonts.inter(
    fontSize: 16, fontWeight: FontWeight.w400, height: 24 / 16,
  );
  static TextStyle get labelBold => GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w600, height: 20 / 14,
  );
  static TextStyle get labelSm => GoogleFonts.inter(
    fontSize: 12, fontWeight: FontWeight.w500, height: 16 / 12,
  );
}
```

### Spacing

```dart
// app/lib/theme/app_spacing.dart
class AppSpacing {
  AppSpacing._();

  static const double unit = 4;
  static const double xs = 4;
  static const double sm = 8;
  static const double gutter = 16;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double margin = 20;
}
```

### Theme Data

```dart
// app/lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.onTertiary,
      tertiaryContainer: AppColors.tertiaryContainer,
      onTertiaryContainer: AppColors.onTertiaryContainer,
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      surfaceContainerHighest: AppColors.surfaceContainerHigh,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
      inverseSurface: AppColors.inverseSurface,
      onInverseSurface: AppColors.inverseOnSurface,
      inversePrimary: AppColors.inversePrimary,
    ),
    scaffoldBackgroundColor: AppColors.background,
    textTheme: TextTheme(
      displayLarge: AppTypography.h1.copyWith(color: AppColors.onSurface),
      displayMedium: AppTypography.h2.copyWith(color: AppColors.onSurface),
      displaySmall: AppTypography.h3.copyWith(color: AppColors.onSurface),
      bodyLarge: AppTypography.bodyLg.copyWith(color: AppColors.onSurface),
      bodyMedium: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
      labelLarge: AppTypography.labelBold.copyWith(color: AppColors.onSurface),
      labelSmall: AppTypography.labelSm.copyWith(color: AppColors.onSurfaceVariant),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surfaceContainerLowest,
      foregroundColor: AppColors.primary,
      elevation: 0,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: AppColors.onPrimary,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: AppTypography.h3,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: BorderSide(color: AppColors.outlineVariant),
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: AppTypography.labelBold,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceContainerLowest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
    ),
    cardTheme: CardTheme(
      color: AppColors.surfaceContainerLowest,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.outlineVariant),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.primaryFixed,
      labelStyle: AppTypography.labelSm.copyWith(color: AppColors.onPrimaryFixed),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
      side: BorderSide.none,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.surfaceContainerLowest,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.onSurfaceVariant,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );
}
```

---

## Prerequisites Audit

**Existing (usable as-is):**
- `app/pubspec.yaml` — already has: `supabase_flutter`, `shared_preferences`, `mobile_scanner`, `image_picker`, `provider`, `intl`, `flutter_localizations`
- `app/lib/models/product.dart` — Product + ProductAllergen with containsAllergens/mayContainAllergens getters ✅
- `app/lib/models/allergen.dart` — Allergen model ✅
- `app/lib/models/user_profile.dart` — UserProfile with toggleAllergen ✅
- `app/lib/services/product_service.dart` — searchProducts, addProduct, archiveProduct ✅
- `app/lib/services/allergen_service.dart` — fetchAllergens ✅
- `app/lib/services/feedback_service.dart` — submitFeedback ✅
- `app/lib/services/search_cache.dart` — offline cache ✅
- `app/lib/screens/add_product_screen.dart` — single-page form (exists, needs replacing)
- `app/lib/screens/crowdsourcing_screen.dart` — (exists, needs replacing)
- `app/lib/screens/feedback_screen.dart` — (exists, keep or replace)

**Missing (must add before Task 1):**
- `google_fonts` package — NOT in pubspec.yaml → need to add
- `Allergen` model: `allergen.dart` exists but path confirmed above ✅
- `app/lib/theme/` directory — does not exist → create in Task 1
- `app/lib/widgets/` directory — does not exist → create in Task 2
- `AppAllergenStatus` enum — defined in `product_details.dart`, needs moving to `app/lib/models/allergen.dart` or `app/lib/theme/app_colors.dart`
- `ProductService.archiveProduct` — already exists at line 153 ✅
- `ProductService.searchProduct(barcode)` — already exists at line 160 ✅
- `ProductService.updateProductAllergens` — already exists at line 191 ✅
- `Supabase Storage` bucket — must verify exists (bucket: `product-images`, public read)
- `.env` file — must exist at project root (bundled as asset)
- `Community service` — no dedicated service. `FeedbackService` exists but `FeedbackService.submitFeedback` at line 8 only inserts into `feedback_reports` — no separate community review/product-add flow. May need a new service.

**Schema gaps:**
- `products.is_kosher` — field referenced in `product_details.dart:57` but NOT in `supabase/schema.sql` → **Schema add required**
- `products.emoji` — referenced in `product_service.dart:171` but NOT in schema → check or remove
- `product_allergens` junction table — exists ✅
- `brands.trust_score` — exists ✅
- `feedback_reports` — exists ✅

---

## Task 0: Prerequisites (Schema + Deps + Model Fixes)

**Files:**
- Modify: `app/pubspec.yaml`
- Modify: `supabase/schema.sql`
- Modify: `app/lib/models/allergen.dart`

- [ ] **Step 1: Add google_fonts to pubspec.yaml**

```yaml
dependencies:
  google_fonts: ^6.2.1
```

Run: `cd app && flutter pub add google_fonts`

- [ ] **Step 2: Add missing schema columns to schema.sql**

```sql
-- Add if not already present:
alter table products add column if not exists is_kosher boolean not null default false;
alter table products add column if not exists ingredients text;
```

Run: apply via Supabase dashboard SQL editor or `supabase db push`

- [ ] **Step 3: Add AllergenStatus enum to allergen.dart**

```dart
// app/lib/models/allergen.dart
enum AllergenStatus { safe, caution, avoid }
```

```dart
// at bottom of product_details_screen.dart:
enum AllergenStatus { safe, caution, avoid }
// → move to allergen.dart so all screens can import it
```

- [ ] **Step 4: Create CommunityService if needed for community flows**

```dart
// app/lib/services/community_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class CommunityService {
  final SupabaseClient _client;
  CommunityService(this._client);

  Future<List<Map<String, dynamic>>> fetchPendingProducts() async {
    return await _client
        .from('products')
        .select('*, brands(name_he)')
        .eq('is_archived', false)
        .isNull('last_reviewed_at')
        .limit(20);
  }

  Future<void> markProductReviewed(String productId) async {
    await _client.from('products').update({
      'last_reviewed_at': DateTime.now().toIso8601String(),
    }).eq('id', productId);
  }
}
```

- [ ] **Step 5: Verify Supabase Storage bucket exists**

```bash
# In Supabase dashboard > Storage, verify bucket "product-images" exists with public read.
# If not, create it:
```

- [ ] **Step 6: Run flutter pub get and flutter analyze**

Run: `cd app && flutter pub get && flutter analyze`
Expected: no errors (warnings acceptable)

- [ ] **Step 7: Commit**

```bash
git add app/pubspec.yaml supabase/schema.sql app/lib/services/community_service.dart
git commit -m "chore: prerequisites — google_fonts, schema cols, CommunityService"
```

---

## Task 1: Design System Foundation

**Files:**
- Create: `app/lib/theme/app_colors.dart`
- Create: `app/lib/theme/app_typography.dart`
- Create: `app/lib/theme/app_spacing.dart`
- Create: `app/lib/theme/app_theme.dart`
- Modify: `app/lib/main.dart` (apply theme, RTL, Hebrew locale, pubspec deps)

- [ ] **Step 1: Add dependencies to pubspec.yaml**

```yaml
dependencies:
  flutter:
    sdk: flutter
  google_fonts: ^6.2.1
  supabase_flutter: ^2.5.0
  shared_preferences: ^2.2.0
  mobile_scanner: ^5.1.1
  image_picker: ^1.1.0
  cached_network_image: ^3.3.1
  flutter_animate: ^4.5.0
```

- [ ] **Step 2: Create app_colors.dart** (see code above)

- [ ] **Step 3: Create app_typography.dart** (see code above)

- [ ] **Step 4: Create app_spacing.dart** (see code above)

- [ ] **Step 5: Create app_theme.dart** (see code above)

- [ ] **Step 6: Rewrite main.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/search_scan_screen.dart';
import 'screens/onboarding_screen.dart';
import 'models/allergen.dart';
import 'models/user_profile.dart';
import 'services/allergen_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_KEY'),
  );
  runApp(const SafeScanApp());
}

class SafeScanApp extends StatelessWidget {
  const SafeScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'בטוח לאכול',
      debugShowCheckedModeBanner: false,
      locale: const Locale('he'),
      supportedLocales: const [Locale('he')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: buildAppTheme(),
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  UserProfile _profile = const UserProfile();
  List<Allergen> _allergens = [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadProfileAndAllergens();
  }

  Future<void> _loadProfileAndAllergens() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIds = prefs.getStringList('selected_allergen_ids') ?? [];
    final completed = prefs.getBool('has_completed_onboarding') ?? false;
    List<Allergen> allergens = [];
    String? err;
    try {
      allergens = await AllergenService(Supabase.instance.client).fetchAllergens();
    } catch (e) {
      err = e.toString();
    }
    if (mounted) {
      setState(() {
        _allergens = allergens;
        _loadError = err;
        _profile = UserProfile(
          selectedAllergenIds: savedIds.toSet(),
          hasCompletedOnboarding: completed,
        );
        _isLoading = false;
      });
    }
  }

  Future<void> _onProfileUpdated(UserProfile p) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('selected_allergen_ids', p.selectedAllergenIds.toList());
    await prefs.setBool('has_completed_onboarding', p.hasCompletedOnboarding);
    if (mounted) setState(() => _profile = p);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (!_profile.hasCompletedOnboarding) {
      return OnboardingScreen(
        allergens: _allergens,
        userProfile: _profile,
        onProfileUpdated: _onProfileUpdated,
      );
    }
    return HomeScreen(
      userProfile: _profile,
      allergens: _allergens,
      onProfileUpdated: _onProfileUpdated,
    );
  }
}
```

- [ ] **Step 7: Add google_fonts to pubspec, run flutter pub get**

- [ ] **Step 8: Run flutter analyze and flutter test**

- [ ] **Step 9: Commit**

```bash
git add app/lib/theme/ app/lib/main.dart app/pubspec.yaml
git commit -m "feat: design system foundation (Clinical Clarity RTL)"
```

---

## Task 2: Shared Widgets

**Files:**
- Create: `app/lib/widgets/bottom_nav_bar.dart`
- Create: `app/lib/widgets/top_app_bar.dart`
- Create: `app/lib/widgets/status_badge.dart`
- Create: `app/lib/widgets/allergen_chip.dart`
- Create: `app/lib/widgets/allergen_card.dart`
- Create: `app/lib/widgets/product_card.dart`
- Create: `app/lib/widgets/search_input.dart`
- Create: `app/lib/widgets/navigation_drawer.dart`
- Create: `app/lib/widgets/progress_stepper.dart`
- Create: `app/lib/widgets/bento_card.dart`
- Create: `app/lib/widgets/photo_upload_card.dart`

- [ ] **Step 1: Create bottom_nav_bar.dart** (see design — 4 tabs: בית/סריקה/קהילה/מועדפים, RTL icons, active state with bg-primary-fixed)

```dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(top: BorderSide(color: AppColors.outlineVariant)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), offset: Offset(0, -2), blurRadius: 10)),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home, label: 'בית', index: 0, current: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.qr_code_scanner, label: 'סריקה', index: 1, current: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.groups, label: 'קהילה', index: 2, current: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.favorite, label: 'מועדפים', index: 3, current: currentIndex, onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final ValueChanged<int> onTap;

  const _NavItem({required this.icon, required this.label, required this.index, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = index == current;
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: active ? 16 : 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primaryFixed : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? AppColors.primary : AppColors.onSurfaceVariant, size: 24),
            SizedBox(height: 2),
            Text(label, style: AppTypography.labelSm.copyWith(
              color: active ? AppColors.primary : AppColors.onSurfaceVariant,
            )),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Create status_badge.dart** (see design — safe (green + check_circle), caution (amber + info), avoid (red + warning))

```dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum AllergenStatus { safe, caution, avoid }

class StatusBadge extends StatelessWidget {
  final AllergenStatus status;
  final String label;

  const StatusBadge({super.key, required this.status, required this.label});

  @override
  Widget build(BuildContext context) {
    final (bg, color, icon) = switch (status) {
      AllergenStatus.safe => (AppColors.safeBackground, AppColors.safeText, Icons.check_circle),
      AllergenStatus.caution => (AppColors.cautionBackground, AppColors.cautionText, Icons.info),
      AllergenStatus.avoid => (AppColors.avoidBackground, AppColors.avoidText, Icons.warning),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          SizedBox(width: 4),
          Text(label, style: AppTypography.labelSm.copyWith(color: color)),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Create allergen_chip.dart**

```dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class AllergenChip extends StatelessWidget {
  final String name;
  final bool isSelected;
  final VoidCallback? onTap;

  const AllergenChip({super.key, required this.name, this.isSelected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryContainer : AppColors.primaryFixed,
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Text(name, style: AppTypography.labelSm.copyWith(
          color: isSelected ? AppColors.onPrimary : AppColors.onPrimaryFixed,
        )),
      ),
    );
  }
}
```

- [ ] **Step 4: Create allergen_card.dart** (grid card with icon circle, allergen name, selection border/highlight)

```dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../models/allergen.dart';

class AllergenCard extends StatelessWidget {
  final Allergen allergen;
  final bool isSelected;
  final VoidCallback onTap;

  const AllergenCard({
    super.key,
    required this.allergen,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryFixed.withOpacity(0.1) : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryContainer : AppColors.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryFixed : AppColors.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _allergenIcon(allergen.nameHe),
                color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
                size: 28,
              ),
            ),
            SizedBox(height: 8),
            Text(
              allergen.nameHe,
              style: AppTypography.labelBold.copyWith(
                color: isSelected ? AppColors.primary : AppColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _allergenIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('בוטנ')) return Icons.nat;
    if (n.contains('חלב')) return Icons.water_drop;
    if (n.contains('ביצ')) return Icons.egg;
    if (n.contains('גלוטן')) return Icons.grass;
    if (n.contains('סויה')) return Icons.eco;
    if (n.contains('שומש')) return Icons.spa;
    if (n.contains('דג')) return Icons.set_meal;
    if (n.contains('אגוז')) return Icons.psychiatry;
    if (n.contains('שקד')) return Icons.nature;
    if (n.contains('קשיו')) return Icons.emoji_nature;
    if (n.contains('פיס��ו')) return Icons.nutrition;
    if (n.contains('פקאן')) return Icons.forest;
    if (n.contains('לוז')) return Icons.yard;
    return Icons.alert;
  }
}
```

- [ ] **Step 5: Create search_input.dart** (RTL — search icon on RIGHT side)

```dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class SearchInput extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final String hint;

  const SearchInput({
    super.key,
    required this.controller,
    this.onChanged,
    this.onSubmitted,
    this.hint = 'חפש מוצר או מרכיב...',
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: (_) => onSubmitted?.call(),
      textDirection: TextDirection.rtl,
      style: AppTypography.bodyMd,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.outline),
        prefixIcon: Padding(
          padding: EdgeInsets.only(right: 12),
          child: Icon(Icons.search, color: AppColors.outline),
        ),
        prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Create navigation_drawer.dart** (RTL right-side drawer, profile header, nav items, logout footer)

- [ ] **Step 7: Create progress_stepper.dart** (4-step with circles, labels, active/completed states)

- [ ] **Step 8: Create product_card.dart** (matches Stitch — image, brand, name, time, status badge, safe/caution/avoid colors)

- [ ] **Step 9: Create bento_card.dart** (stats card for home screen grid)

- [ ] **Step 10: Create photo_upload_card.dart** (dashed border, icon, label, hint, camera/receipt icons)

- [ ] **Step 11: Create top_app_bar.dart** (shared with menu + profile avatar)

- [ ] **Step 12: Run tests, commit**

---

## Task 3: Home Dashboard Screen

**Files:**
- Create: `app/lib/screens/home_screen.dart`
- Modify: `app/lib/main.dart` (route)

- [ ] **Step 1: Create home_screen.dart** (matches Stitch דש הבית screen — greeting, safety status card with allergen chips, quick scan prompt, recent activity list, bento cards, bottom nav, FAB scanner)

- [ ] **Step 2: Wire into main.dart routing**

- [ ] **Step 3: Write widget test**

- [ ] **Step 4: Run flutter analyze + flutter test**

- [ ] **Step 5: Commit**

---

## Task 4: Search & Scan Screen

**Files:**
- Create: `app/lib/screens/search_scan_screen.dart`
- Modify: `app/lib/main.dart` (route)

- [ ] **Step 1: Create search_scan_screen.dart** (matches Stitch חיפוש וסריקה — search input, barcode scanner viewport with corner accents, recent scans, safety tips, bottom nav)

- [ ] **Step 2: Wire into navigation (replace SearchScreenContent)**

- [ ] **Step 3: Write widget test**

- [ ] **Step 4: Run tests, commit**

---

## Task 5: Onboarding Screen

**Files:**
- Modify: `app/lib/screens/onboarding_screen.dart`

- [ ] **Step 1: Rewrite onboarding_screen.dart** (matches Stitch בחירת אלרגנים — 2-step flow, allergen grid with icons in circles, progress bar, decorative image, medical disclaimer, RTL)

- [ ] **Step 2: Write widget test**

- [ ] **Step 3: Run tests, commit**

---

## Task 6: Product Details Screen

**Files:**
- Modify: `app/lib/screens/product_details.dart` → rename to `product_details_screen.dart`

- [ ] **Step 1: Rewrite product_details_screen.dart** (matches Stitch פרטי מוצר - בטוח — safe/caution/avoid banner, product image, allergen list with icons, ingredients accordion, share/report buttons, RTL)

- [ ] **Step 2: Write widget test**

- [ ] **Step 3: Run tests, commit**

---

## Task 7: Add Product Wizard

**Files:**
- Modify: `app/lib/screens/add_product_screen.dart`

- [ ] **Step 1: Rewrite add_product_screen.dart** (4-step wizard matching Stitch: Step 1=barcode/scanner, Step 2=photos, Step 3=contains, Step 4=may contain + submit)

- [ ] **Step 2: Write widget test**

- [ ] **Step 3: Run tests, commit**

---

## Task 8: Community Screen

**Files:**
- Modify: `app/lib/screens/crowdsourcing_screen.dart` → rename/rewrite as `community_screen.dart`

- [ ] **Step 1: Rewrite community_screen.dart** (matches Stitch קהילה — impact stats bento grid, add product CTA card, peer review prompt, weekly tip, active discussion, bottom nav)

- [ ] **Step 2: Write widget test**

- [ ] **Step 3: Run tests, commit**

---

## Task 9: Settings Screen

**Files:**
- Create: `app/lib/screens/settings_screen.dart`

- [ ] **Step 1: Create settings_screen.dart** (matches Stitch הגדרות ופרופיל — profile avatar, edit button, stats row, toggle switches, nav menu list tiles, logout button, bottom nav)

- [ ] **Step 2: Write widget test**

- [ ] **Step 3: Run tests, commit**

---

## Task 10: Feedback Success Screen

**Files:**
- Create: `app/lib/screens/feedback_success_screen.dart`

- [ ] **Step 1: Create feedback_success_screen.dart** (matches Stitch הוספה הצליחה — check circle, thank you message, community points + ranking bento cards, next product card with skip/check CTA, home button)

- [ ] **Step 2: Write widget test**

- [ ] **Step 3: Run tests, commit**

---

## Task 11: Review Next Item Screen

**Files:**
- Create: `app/lib/screens/review_next_screen.dart`

- [ ] **Step 1: Create review_next_screen.dart** (matches Stitch המשך סקירה — review all clear banner, next product card, check now/skip, community stats)

- [ ] **Step 2: Write widget test**

- [ ] **Step 3: Run tests, commit**

---

## Task 12: Admin Manage Brands Screen

**Files:**
- Create: `app/lib/screens/admin_brands_screen.dart`

- [ ] **Step 1: Create admin_brands_screen.dart** (matches Stitch ניהול מותגים מאושרים — brand search, count stat, brand list with verified toggles, add brand button, navigation drawer)

- [ ] **Step 2: Write widget test**

- [ ] **Step 3: Run tests, commit**

---

## Task 13: Navigation Drawers

**Files:**
- Create: `app/lib/screens/drawer_user_screen.dart`
- Create: `app/lib/screens/drawer_admin_screen.dart`

- [ ] **Step 1: Create drawer_user_screen.dart** (RTL right-side drawer, profile header, nav items (פרופיל, היסטוריה, מוצרים שמורים, ביקורת קהילה, מרכז עזרה, אודות), logout footer)

- [ ] **Step 2: Create drawer_admin_screen.dart** (same structure with admin items + branding watermark)

- [ ] **Step 3: Run tests, commit**

---

## Task 14: Contact Us Screen

**Files:**
- Modify: existing contact/about screen

- [ ] **Step 1: Rewrite contact_screen.dart** (matches Stitch צור קשר — contact form with name/email/message/submit, bottom nav)

- [ ] **Step 2: Run tests, commit**

---

## Self-Review Checklist

- [ ] All 20 Stitch screens have a corresponding task (or are combined where appropriate)
- [ ] Design system colors match exactly (hex values from designMd)
- [ ] Typography uses Public Sans (headings) + Inter (body/labels)
- [ ] All text is RTL aligned
- [ ] Status badges use exact safe/caution/avoid colors
- [ ] Bottom nav has 4 tabs with active state
- [ ] All screens have bottom nav except wizard flows (add product steps)
- [ ] Navigation drawer is right-side in RTL
- [ ] No placeholders in task steps
- [ ] Existing models/services remain unchanged
- [ ] flutter analyze passes with no errors
- [ ] flutter test passes

---

## Summary

| Priority | Task | Description |
|----------|------|--------|
| 1 | Task 1 | Design System Foundation |
| 2 | Task 2 | Shared Widgets |
| 3 | Task 3 | Home Dashboard |
| 4 | Task 4 | Search & Scan |
| 5 | Task 5 | Onboarding |
| 6 | Task 6 | Product Details |
| 7 | Task 7 | Add Product Wizard (4 steps) |
| 8 | Task 8 | Community Hub |
| 9 | Task 9 | Settings & Profile |
| 10 | Task 10 | Feedback Success |
| 11 | Task 11 | Review Next Item |
| 12 | Task 12 | Admin Manage Brands |
| 13 | Task 13 | Navigation Drawers |
| 14 | Task 14 | Contact Us |

---

**Plan complete and saved to `docs/superpowers/plans/2026-04-30-stitch-full-impl.md`.**

**Two execution options:**

**1. Subagent-Driven (recommended)** - Dispatch a subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?**