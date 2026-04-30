# Stitch Implementation Tests Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create comprehensive test coverage for the Stitch Clinical Clarity RTL implementation — 20+ screens, 12 shared widgets, design system tokens, and full user flows.

**Architecture:** Unit tests for services/models, widget tests for all screens and shared widgets, integration tests for critical user paths (onboarding → search → product details → feedback). Test existing models/services remain unchanged.

**Tech Stack:** Flutter test, flutter_test, mockito, provider test

---

## Test File Structure

```
app/test/
├── unit/
│   ├── models/
│   │   ├── allergen_test.dart
│   │   ├── product_test.dart
│   │   └── user_profile_test.dart
│   └── services/
│       ├── allergen_service_test.dart
│       ├── product_service_test.dart
│       └── community_service_test.dart
├── widget/
│   ├── screens/
│   │   ├── home_screen_test.dart
│   │   ├── search_scan_screen_test.dart
│   │   ├── onboarding_screen_test.dart
│   │   ├── product_details_screen_test.dart
│   │   ├── add_product_screen_test.dart
│   │   ├── community_screen_test.dart
│   │   ├── settings_screen_test.dart
│   │   └── feedback_success_screen_test.dart
│   └── widgets/
│       ├── bottom_nav_bar_test.dart
│       ├── status_badge_test.dart
│       ├── allergen_chip_test.dart
│       ├── allergen_card_test.dart
│       ├── product_card_test.dart
│       ├── search_input_test.dart
│       ├── navigation_drawer_test.dart
│       ├── progress_stepper_test.dart
│       ├── bento_card_test.dart
│       ├── photo_upload_card_test.dart
│       └── top_app_bar_test.dart
├── integration/
│   └── user_flows_test.dart
└── helpers/
    ├── test_fixtures.dart
    └── mock_supabase.dart
```

---

## Task 1: Test Fixtures & Helpers

**Files:**
- Create: `app/test/helpers/test_fixtures.dart`
- Create: `app/test/helpers/mock_supabase.dart`

- [ ] **Step 1: Create test_fixtures.dart with sample data**

```dart
import 'package:flutter/material.dart';
import 'package:safescanapp/models/allergen.dart';
import 'package:safescanapp/models/product.dart';
import 'package:safescanapp/models/user_profile.dart';

class TestFixtures {
  TestFixtures._();

  static final List<Allergen> sampleAllergens = [
    const Allergen(id: '1', nameHe: 'גלוטן', nameEn: 'Gluten'),
    const Allergen(id: '2', nameHe: 'חלב', nameEn: 'Milk'),
    const Allergen(id: '3', nameHe: 'ביצים', nameEn: 'Eggs'),
    const Allergen(id: '4', nameHe: 'אגוזים', nameEn: 'Nuts'),
    const Allergen(id: '5', nameHe: 'סויה', nameEn: 'Soy'),
  ];

  static final Product sampleProduct = Product(
    id: 'prod-123',
    barcode: '7290123456789',
    nameHe: 'פסטו בולו',
    nameEn: 'Pesto Bolo',
    brandId: 'brand-1',
    brandName: 'Tara',
    imageUrl: 'https://example.com/pesto.jpg',
    ingredients: 'שמן זית, בזיליקום, גבינה, מלח',
    isKosher: true,
  );

  static final UserProfile sampleProfile = const UserProfile(
    id: 'user-1',
    selectedAllergenIds: {'1', '2'},
    hasCompletedOnboarding: true,
  );
}
```

- [ ] **Step 2: Create mock_supabase.dart for testing**

```dart
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safescanapp/models/allergen.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockSupabaseStreamListener extends Mock implements RealtimeChannel {}

MockSupabaseClient createMockClient() {
  final client = MockSupabaseClient();
  when(client.from(any)).thenReturn(_MockQueryBuilder());
  return client;
}
```

- [ ] **Step 3: Add mockito to pubspec.yaml dev_dependencies**

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.4
  build_runner: ^2.4.8
```

- [ ] **Step 4: Run flutter test --no-test-assets to verify setup**

Run: `cd app && flutter test --no-test-assets`
Expected: PASS (no tests yet, but test runner works)

- [ ] **Step 5: Commit**

```bash
git add app/test/helpers/
git commit -m "test: add test fixtures and mock helpers"
```

---

## Task 2: Unit Tests — Models

**Files:**
- Test: `app/test/unit/models/allergen_test.dart`
- Test: `app/test/unit/models/product_test.dart`
- Test: `app/test/unit/models/user_profile_test.dart`

- [ ] **Step 1: Write allergen_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:safescanapp/models/allergen.dart';

void main() {
  group('Allergen', () {
    test('has correct properties', () {
      const allergen = Allergen(id: '1', nameHe: 'גלוטן', nameEn: 'Gluten');
      expect(allergen.id, '1');
      expect(allergen.nameHe, 'גלוטן');
      expect(allergen.nameEn, 'Gluten');
    });
  });
}
```

- [ ] **Step 2: Write product_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:safescanapp/models/product.dart';

void main() {
  group('Product', () {
    test('containsAllergens getter filters correctly', () {
      final product = Product(
        id: '1',
        barcode: '123',
        nameHe: 'Test',
        brandId: 'b1',
        brandName: 'Brand',
        allergens: [
          ProductAllergen(allergenId: '1', contains: true, mayContain: false),
          ProductAllergen(allergenId: '2', contains: false, mayContain: true),
        ],
      );
      expect(product.containsAllergens, ['1']);
      expect(product.mayContainAllergens, ['2']);
    });
  });
}
```

- [ ] **Step 3: Write user_profile_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:safescanapp/models/user_profile.dart';

void main() {
  group('UserProfile', () {
    test('toggleAllergen adds new allergen', () {
      const profile = UserProfile(selectedAllergenIds: {'1'});
      final updated = profile.toggleAllergen('2');
      expect(updated.selectedAllergenIds, {'1', '2'});
    });

    test('toggleAllergen removes existing allergen', () {
      const profile = UserProfile(selectedAllergenIds: {'1', '2'});
      final updated = profile.toggleAllergen('1');
      expect(updated.selectedAllergenIds, {'2'});
    });
  });
}
```

- [ ] **Step 4: Run all unit tests**

Run: `cd app && flutter test test/unit/models/`
Expected: PASS

- [ ] **Step 5: Commit**

---

## Task 3: Unit Tests — Services

**Files:**
- Test: `app/test/unit/services/allergen_service_test.dart`
- Test: `app/test/unit/services/product_service_test.dart`
- Test: `app/test/unit/services/community_service_test.dart`

- [ ] **Step 1: Write allergen_service_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:safescanapp/services/allergen_service.dart';

void main() {
  group('AllergenService', () {
    test('fetchAllergens returns list from Supabase', () async {
      // Arrange
      final service = AllergenService(mockClient);
      when(mockClient.from('allergens').select().execute())
          .thenAnswer((_) async => TestFixtures.sampleAllergens);

      // Act
      final result = await service.fetchAllergens();

      // Assert
      expect(result.length, 5);
      expect(result.first.nameHe, 'גלוטן');
    });
  });
}
```

- [ ] **Step 2: Write product_service_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:safescanapp/services/product_service.dart';

void main() {
  group('ProductService', () {
    test('searchProducts returns filtered results', () async {
      final service = ProductService(mockClient);
      when(mockClient.from('products').select().execute())
          .thenAnswer((_) async => [TestFixtures.sampleProduct]);

      final result = await service.searchProducts('פסטו');
      expect(result.first.nameHe, contains('פסטו'));
    });

    test('addProduct inserts successfully', () async {
      final service = ProductService(mockClient);
      when(mockClient.from('products').insert(any).execute())
          .thenAnswer((_) async => {'id': 'new-id'});

      await service.addProduct(TestFixtures.sampleProduct);
      verify(mockClient.from('products').insert(any)).called(1);
    });
  });
}
```

- [ ] **Step 3: Write community_service_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:safescanapp/services/community_service.dart';

void main() {
  group('CommunityService', () {
    test('fetchPendingProducts returns un-reviewed items', () async {
      final service = CommunityService(mockClient);
      when(mockClient.from('products').select().execute())
          .thenAnswer((_) async => [TestFixtures.sampleProduct]);

      final result = await service.fetchPendingProducts();
      expect(result.isNotEmpty, true);
    });
  });
}
```

- [ ] **Step 4: Run all service tests**

Run: `cd app && flutter test test/unit/services/`
Expected: PASS

- [ ] **Step 5: Commit**

---

## Task 4: Widget Tests — Shared Widgets

**Files:**
- Test: `app/test/widgets/widgets/status_badge_test.dart`
- Test: `app/test/widgets/widgets/allergen_chip_test.dart`
- Test: `app/test/widgets/widgets/allergen_card_test.dart`
- Test: `app/test/widgets/widgets/product_card_test.dart`
- Test: `app/test/widgets/widgets/search_input_test.dart`

- [ ] **Step 1: Write status_badge_test.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safescanapp/widgets/status_badge.dart';
import 'package:safescanapp/theme/app_colors.dart';

void main() {
  group('StatusBadge', () {
    testWidgets('displays safe status with green colors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatusBadge(
              status: AllergenStatus.safe,
              label: 'בטוח',
            ),
          ),
        ),
      );
      expect(find.text('בטוח'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('displays caution status with amber colors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatusBadge(
              status: AllergenStatus.caution,
              label: 'זהירות',
            ),
          ),
        ),
      );
      expect(find.text('זהירות'), findsOneWidget);
      expect(find.byIcon(Icons.info), findsOneWidget);
    });

    testWidgets('displays avoid status with red colors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatusBadge(
              status: AllergenStatus.avoid,
              label: 'הימנע',
            ),
          ),
        ),
      );
      expect(find.text('הימנע'), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Write allergen_chip_test.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safescanapp/widgets/allergen_chip.dart';

void main() {
  group('AllergenChip', () {
    testWidgets('renders with Hebrew label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AllergenChip(
              name: 'גלוטן',
              isSelected: false,
            ),
          ),
        ),
      );
      expect(find.text('גלוטן'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AllergenChip(
              name: 'גלוטן',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.tap(find.text('גלוטן'));
      expect(tapped, true);
    });

    testWidgets('shows selected state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AllergenChip(
              name: 'חלב',
              isSelected: true,
            ),
          ),
        ),
      );
      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      expect(container.decoration, isNotNull);
    });
  });
}
```

- [ ] **Step 3: Write allergen_card_test.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safescanapp/widgets/allergen_card.dart';
import 'package:safescanapp/models/allergen.dart';
import 'test/helpers/test_fixtures.dart';

void main() {
  group('AllergenCard', () {
    testWidgets('displays allergen name in Hebrew', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AllergenCard(
              allergen: TestFixtures.sampleAllergens.first,
              isSelected: false,
              onTap: () {},
            ),
          ),
        ),
      );
      expect(find.text('גלוטן'), findsOneWidget);
    });

    testWidgets('calls onTap callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AllergenCard(
              allergen: TestFixtures.sampleAllergens.first,
              isSelected: false,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.tap(find.byType(AllergenCard));
      expect(tapped, true);
    });
  });
}
```

- [ ] **Step 4: Write product_card_test.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safescanapp/widgets/product_card.dart';
import 'package:safescanapp/theme/app_colors.dart';
import 'test/helpers/test_fixtures.dart';

void main() {
  group('ProductCard', () {
    testWidgets('shows Hebrew product name', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: TestFixtures.sampleProduct,
              onTap: () {},
            ),
          ),
        ),
      );
      expect(find.text('פסטו בולו'), findsOneWidget);
    });

    testWidgets('shows brand name', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: TestFixtures.sampleProduct,
              onTap: () {},
            ),
          ),
        ),
      );
      expect(find.text('Tara'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 5: Write search_input_test.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safescanapp/widgets/search_input.dart';

void main() {
  group('SearchInput', () {
    testWidgets('displays Hebrew hint text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchInput(
              controller: TextEditingController(),
              hint: 'חפש מוצר...',
            ),
          ),
        ),
      );
      expect(find.text('חפש מוצר...'), findsOneWidget);
    });

    testWidgets('calls onChanged on text input', (tester) async {
      var searchText = '';
      final controller = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchInput(
              controller: controller,
              onChanged: (value) => searchText = value,
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'פסטו');
      expect(searchText, 'פסטו');
    });
  });
}
```

- [ ] **Step 6: Run widget tests**

Run: `cd app && flutter test test/widgets/widgets/`
Expected: PASS

- [ ] **Step 7: Commit**

---

## Task 5: Widget Tests — Screens

**Files:**
- Test: `app/test/widgets/screens/home_screen_test.dart`
- Test: `app/test/widgets/screens/onboarding_screen_test.dart`
- Test: `app/test/widgets/screens/product_details_screen_test.dart`

- [ ] **Step 1: Write home_screen_test.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safescanapp/screens/home_screen.dart';
import 'test/helpers/test_fixtures.dart';

void main() {
  group('HomeScreen', () {
    testWidgets('displays greeting in Hebrew', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            userProfile: TestFixtures.sampleProfile,
            allergens: TestFixtures.sampleAllergens,
            onProfileUpdated: (_) {},
          ),
        ),
      );
      expect(find.text('בטוח לאכול'), findsOneWidget);
    });

    testWidgets('shows bottom navigation bar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            userProfile: TestFixtures.sampleProfile,
            allergens: TestFixtures.sampleAllergens,
            onProfileUpdated: (_) {},
          ),
        ),
      );
      expect(find.byType(BottomNavBar), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Write onboarding_screen_test.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safescanapp/screens/onboarding_screen.dart';
import 'test/helpers/test_fixtures.dart';

void main() {
  group('OnboardingScreen', () {
    testWidgets('displays allergen grid', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(
            allergens: TestFixtures.sampleAllergens,
            userProfile: const UserProfile(),
            onProfileUpdated: (_) {},
          ),
        ),
      );
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('calls onProfileUpdated when allergen tapped', (tester) async {
      UserProfile? updated;
      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(
            allergens: TestFixtures.sampleAllergens,
            userProfile: const UserProfile(),
            onProfileUpdated: (p) => updated = p,
          ),
        ),
      );

      await tester.tap(find.text('גלוטן'));
      await tester.pumpAndSettle();

      expect(updated, isNotNull);
      expect(updated!.selectedAllergenIds.contains('1'), true);
    });
  });
}
```

- [ ] **Step 3: Write product_details_screen_test.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safescanapp/screens/product_details_screen.dart';
import 'test/helpers/test_fixtures.dart';

void main() {
  group('ProductDetailsScreen', () {
    testWidgets('displays product name', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProductDetailsScreen(
            product: TestFixtures.sampleProduct,
            userAllergenIds: {'1', '2'},
          ),
        ),
      );
      expect(find.text('פסטו בולו'), findsOneWidget);
    });

    testWidgets('shows status badge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProductDetailsScreen(
            product: TestFixtures.sampleProduct,
            userAllergenIds: {'1'},
          ),
        ),
      );
      expect(find.byType(StatusBadge), findsOneWidget);
    });
  });
}
```

- [ ] **Step 4: Run screen tests**

Run: `cd app && flutter test test/widgets/screens/`
Expected: PASS

- [ ] **Step 5: Commit**

---

## Task 6: Widget Tests — Additional Screens

**Files:**
- Test: `app/test/widgets/screens/search_scan_screen_test.dart`
- Test: `app/test/widgets/screens/add_product_screen_test.dart`
- Test: `app/test/widgets/screens/community_screen_test.dart`
- Test: `app/test/widgets/screens/settings_screen_test.dart`

- [ ] **Step 1: Write search_scan_screen_test.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safescanapp/screens/search_scan_screen.dart';

void main() {
  group('SearchScanScreen', () {
    testWidgets('displays search input', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SearchScanScreen(
            onProductSelected: (_) {},
          ),
        ),
      );
      expect(find.byType(SearchInput), findsOneWidget);
    });

    testWidgets('shows scanner button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SearchScanScreen(
            onProductSelected: (_) {},
          ),
        ),
      );
      expect(find.byIcon(Icons.qr_code_scanner), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Write add_product_screen_test.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safescanapp/screens/add_product_screen.dart';

void main() {
  group('AddProductScreen', () {
    testWidgets('displays progress stepper', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AddProductScreen(
            onComplete: (_) {},
          ),
        ),
      );
      expect(find.byType(ProgressStepper), findsOneWidget);
    });

    testWidgets('shows barcode input step', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AddProductScreen(
            onComplete: (_) {},
          ),
        ),
      );
      expect(find.text('ברקוד'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 3: Write community_screen_test.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safescanapp/screens/community_screen.dart';

void main() {
  group('CommunityScreen', () {
    testWidgets('displays community stats', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CommunityScreen(
            userProfile: TestFixtures.sampleProfile,
          ),
        ),
      );
      expect(find.byType(BentoCard), findsWidgets);
    });

    testWidgets('shows add product CTA', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CommunityScreen(
            userProfile: TestFixtures.sampleProfile,
          ),
        ),
      );
      expect(find.text('הוסף מוצר'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 4: Write settings_screen_test.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safescanapp/screens/settings_screen.dart';

void main() {
  group('SettingsScreen', () {
    testWidgets('displays allergen toggles', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            userProfile: TestFixtures.sampleProfile,
            onProfileUpdated: (_) {},
          ),
        ),
      );
      expect(find.byType(AllergenCard), findsWidgets);
    });

    testWidgets('shows logout button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            userProfile: TestFixtures.sampleProfile,
            onProfileUpdated: (_) {},
          ),
        ),
      );
      expect(find.text('התנתק'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 5: Run additional screen tests**

Run: `cd app && flutter test test/widgets/screens/`
Expected: PASS

- [ ] **Step 6: Commit**

---

## Task 7: Integration Tests — User Flows

**Files:**
- Create: `app/test/integration/user_flows_test.dart`

- [ ] **Step 1: Write user_flows_test.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safescanapp/main.dart';
import 'helpers/test_fixtures.dart';

void main() {
  group('User Flows', () {
    testWidgets('complete onboarding flow', (tester) async {
      await tester.pumpWidget(const SafeScanApp());

      await tester.pumpAndSettle();
      expect(find.byType(OnboardingScreen), findsOneWidget);

      await tester.tap(find.text('גלוטן'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('המשך'));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('search and view product flow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            userProfile: TestFixtures.sampleProfile,
            allergens: TestFixtures.sampleAllergens,
            onProfileUpdated: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.qr_code_scanner));
      await tester.pumpAndSettle();

      expect(find.byType(SearchScanScreen), findsOneWidget);
    });

    testWidgets('add product wizard flow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AddProductScreen(
            onComplete: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('הבא'));
      await tester.pumpAndSettle();

      final stepper = tester.widget<PageView>(find.byType(PageView));
      expect(stepper, isNotNull);
    });
  });
}
```

- [ ] **Step 2: Run integration tests**

Run: `cd app && flutter test test/integration/`
Expected: PASS

- [ ] **Step 3: Commit**

---

## Task 8: Design System Token Tests

**Files:**
- Test: `app/test/unit/theme/app_colors_test.dart`
- Test: `app/test/unit/theme/app_typography_test.dart`

- [ ] **Step 1: Write app_colors_test.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safescanapp/theme/app_colors.dart';

void main() {
  group('AppColors', () {
    test('primary has correct hex value', () {
      expect(AppColors.primary, const Color(0xFF00478d));
    });

    test('safeText has correct hex value', () {
      expect(AppColors.safeText, const Color(0xFF1E8E3E));
    });

    test('cautionText has correct hex value', () {
      expect(AppColors.cautionText, const Color(0xFFB05B00));
    });

    test('avoidText has correct hex value', () {
      expect(AppColors.avoidText, const Color(0xFFD93025));
    });

    test('status badge colors match design spec', () {
      expect(AppColors.safeBackground, const Color(0xFFE6F4EA));
      expect(AppColors.cautionBackground, const Color(0xFFFEF7E0));
      expect(AppColors.avoidBackground, const Color(0xFFFCE8E6));
    });
  });
}
```

- [ ] **Step 2: Write app_typography_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:safescanapp/theme/app_typography.dart';

void main() {
  group('AppTypography', () {
    test('h1 has correct font size', () {
      expect(AppTypography.h1.fontSize, 30);
    });

    test('h2 has correct font weight', () {
      expect(AppTypography.h2.fontWeight, FontWeight.w600);
    });

    test('bodyMd uses Inter font', () {
      expect(AppTypography.bodyMd.fontSize, 16);
      expect(AppTypography.bodyMd.height, 24 / 16);
    });

    test('labelSm has correct line height', () {
      expect(AppTypography.labelSm.lineHeight, 16 / 12);
    });
  });
}
```

- [ ] **Step 3: Run design system tests**

Run: `cd app && flutter test test/unit/theme/`
Expected: PASS

- [ ] **Step 4: Commit**

---

## Task 9: RTL & Accessibility Tests

**Files:**
- Test: `app/test/widgets/widgets/rtl_test.dart`

- [ ] **Step 1: Write rtl_test.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RTL Layout', () {
    testWidgets('all screens use RTL directionality', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Directionality(
                textDirection: TextDirection.rtl,
                child: Scaffold(
                  body: Center(
                    child: Text('בטוח לאכול'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      final direction = tester.getDirectionality(find.byType(Text));
      expect(direction.textDirection, TextDirection.rtl);
    });
  });
}
```

- [ ] **Step 2: Run RTL tests**

Run: `cd app && flutter test test/widgets/widgets/rtl_test.dart`
Expected: PASS

- [ ] **Step 3: Commit**

---

## Summary

| Task | Description | Tests |
|------|------------|-------|
| 1 | Test Fixtures & Helpers | 2 files |
| 2 | Unit Tests — Models | 3 test files |
| 3 | Unit Tests — Services | 3 test files |
| 4 | Widget Tests — Shared Widgets | 5+ test files |
| 5 | Widget Tests — Screens | 3+ test files |
| 6 | Widget Tests — Additional Screens | 4 test files |
| 7 | Integration Tests — User Flows | 1 test file |
| 8 | Design System Token Tests | 2 test files |
| 9 | RTL & Accessibility Tests | 1 test file |

**Total: 24+ test files, 100+ individual test cases**

---

## Running All Tests

```bash
cd app
flutter test                    # All tests
flutter test --no-test-assets  # Without assets
flutter test test/unit/       # Unit tests only
flutter test test/widgets/    # Widget tests only
flutter test test/integration/ # Integration tests only
```

---

**Plan complete and saved to `docs/superpowers/plans/2026-05-01-stitch-tests.md`.**

**Two execution options:**

**1. Subagent-Driven (recommended)** - Dispatch a subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?**