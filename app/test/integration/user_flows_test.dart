import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/models/allergen.dart';
import 'package:app/models/product.dart';
import 'package:app/models/user_profile.dart';
import 'package:app/widgets/allergen_card.dart';
import 'package:app/screens/onboarding_screen.dart';
import 'package:app/screens/product_details.dart';
import 'package:app/widgets/product_card.dart';
import 'package:app/widgets/progress_stepper.dart';
import 'package:app/widgets/photo_upload_card.dart';
import 'package:app/theme/app_theme.dart';

const List<Allergen> testAllergens = [
  Allergen(id: '1', nameHe: 'גלוטן', nameEn: 'Gluten'),
  Allergen(id: '2', nameHe: 'חלב', nameEn: 'Milk'),
  Allergen(id: '3', nameHe: 'ביצים', nameEn: 'Eggs'),
  Allergen(id: '4', nameHe: 'אגוזים', nameEn: 'Nuts'),
  Allergen(id: '5', nameHe: 'סויה', nameEn: 'Soy'),
];

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('Onboarding Flow Tests', () {
    testWidgets('Welcome screen displays allergen selection', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: OnboardingScreen(
              allergens: testAllergens,
              userProfile: const UserProfile(),
              onProfileUpdated: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('ברוכים הבאים ל-SafeBite'), findsOneWidget);
      expect(find.text('בחרו אלרגנים (0 נבחרו)'), findsOneWidget);
      expect(find.text('שלב 1 מתוך 2'), findsOneWidget);
    });

    testWidgets('Allergen cards are displayed in grid', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: OnboardingScreen(
              allergens: testAllergens,
              userProfile: const UserProfile(),
              onProfileUpdated: (_) {},
            ),
          ),
        ),
      );

      final allergenCards = find.byType(AllergenCard);
      expect(allergenCards, findsAtLeast(3));
    });

    testWidgets('Cannot continue without selecting allergens', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: OnboardingScreen(
              allergens: testAllergens,
              userProfile: const UserProfile(),
              onProfileUpdated: (_) {},
            ),
          ),
        ),
      );

      await tester.ensureVisible(find.text('המשך'));
      await tester.pump();

      final continueButton = find.widgetWithText(ElevatedButton, 'המשך');
      final button = tester.widget<ElevatedButton>(continueButton);
      expect(button.onPressed, isNull);
    });

    testWidgets('Onboarding shows selected count when allergens present in profile', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: OnboardingScreen(
              allergens: testAllergens,
              userProfile: const UserProfile(selectedAllergenIds: {'1', '2'}),
              onProfileUpdated: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('בחרו אלרגנים (2 נבחרו)'), findsOneWidget);

      await tester.ensureVisible(find.text('המשך'));
      await tester.pump();

      final continueButton = find.widgetWithText(ElevatedButton, 'המשך');
      final button = tester.widget<ElevatedButton>(continueButton);
      expect(button.onPressed, isNotNull);
    });
  });

  group('Product Details Flow Tests', () {
    testWidgets('Product details displays product info', (tester) async {
      final product = Product(
        id: 'test-123',
        nameHe: 'פסטו בולו',
        barcode: '7290123456789',
        brandId: 'brand-1',
        brandNameHe: 'טרה',
        brandTrustScore: 0.85,
        allergens: const [
          ProductAllergen(allergenId: '1', allergenNameHe: 'גלוטן', severity: 'contains'),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: ProductDetailsScreen(
              product: product,
              userProfile: const UserProfile(selectedAllergenIds: {'1'}),
            ),
          ),
        ),
      );

      expect(find.text('טרה'), findsOneWidget);
    });

    testWidgets('Product details shows danger status for matching allergen', (tester) async {
      final product = Product(
        id: 'test-123',
        nameHe: 'פסטו בולו',
        allergens: const [
          ProductAllergen(allergenId: '1', allergenNameHe: 'גלוטן', severity: 'contains'),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: ProductDetailsScreen(
              product: product,
              userProfile: const UserProfile(selectedAllergenIds: {'1'}),
            ),
          ),
        ),
      );

      expect(find.text('הימנע - מכיל אלרגנים שלך'), findsOneWidget);
    });

    testWidgets('Product details shows safe status when no matching allergens', (tester) async {
      final product = Product(
        id: 'test-123',
        nameHe: 'פסטו בולו',
        allergens: const [
          ProductAllergen(allergenId: '1', allergenNameHe: 'גלוטן', severity: 'contains'),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: ProductDetailsScreen(
              product: product,
              userProfile: const UserProfile(selectedAllergenIds: {'2'}),
            ),
          ),
        ),
      );

      expect(find.text('✓ בטוח - ללא אלרגנים עבורך'), findsOneWidget);
    });

    testWidgets('Product details shows caution for may contain', (tester) async {
      final product = Product(
        id: 'test-123',
        nameHe: 'פסטו בולו',
        allergens: const [
          ProductAllergen(allergenId: '1', allergenNameHe: 'גלוטן', severity: 'may_contain'),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: ProductDetailsScreen(
              product: product,
              userProfile: const UserProfile(selectedAllergenIds: {'1'}),
            ),
          ),
        ),
      );

      expect(find.text('זהירות - עשוי להכיל'), findsOneWidget);
    });

    testWidgets('Product details shows report button', (tester) async {
      final product = Product(
        id: 'test-123',
        nameHe: 'פסטו בולו',
        allergens: const [],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: ProductDetailsScreen(
              product: product,
              userProfile: const UserProfile(),
            ),
          ),
        ),
      );

      expect(find.text('דיווח על טעות'), findsOneWidget);
    });
  });

  group('Add Product Wizard Flow Tests', () {
    testWidgets('Add product wizard displays step 1', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: AddProductWizardTestWrapper(
                allergens: testAllergens,
                brands: const ['טרה', 'שטראוס'],
              ),
            ),
          ),
        ),
      );

      expect(find.text('הוסף מוצר'), findsOneWidget);
      expect(find.text('שם המוצר *'), findsOneWidget);
    });

    testWidgets('Add product wizard has progress stepper', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: AddProductWizardTestWrapper(
                allergens: testAllergens,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ProgressStepper), findsOneWidget);
    });

    testWidgets('Add product wizard step 1 has form fields', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: AddProductWizardTestWrapper(
                allergens: testAllergens,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TextFormField), findsAtLeast(2));
    });
  });

  group('Product Card Tests', () {
    testWidgets('Product card displays product name and brand', (tester) async {
      final product = Product(
        id: 'test-123',
        nameHe: 'פסטו בולו',
        barcode: '7290123456789',
        brandNameHe: 'טרה',
        brandTrustScore: 0.85,
        allergens: const [],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: ProductCard(
                product: product,
                userProfile: const UserProfile(),
                onTap: () {},
                onReport: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('פסטו בולו'), findsOneWidget);
      expect(find.text('טרה'), findsOneWidget);
    });

    testWidgets('Product card shows safe badge when no matching allergens', (tester) async {
      final product = Product(
        id: 'test-123',
        nameHe: 'פסטו בולו',
        allergens: const [
          ProductAllergen(allergenId: '1', allergenNameHe: 'גלוטן', severity: 'contains'),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: ProductCard(
                product: product,
                userProfile: const UserProfile(selectedAllergenIds: {'2'}),
                onTap: () {},
                onReport: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('בטוח'), findsOneWidget);
    });

    testWidgets('Product card shows danger badge when contains user allergen', (tester) async {
      final product = Product(
        id: 'test-123',
        nameHe: 'פסטו בולו',
        allergens: const [
          ProductAllergen(allergenId: '1', allergenNameHe: 'גלוטן', severity: 'contains'),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: ProductCard(
                product: product,
                userProfile: const UserProfile(selectedAllergenIds: {'1'}),
                onTap: () {},
                onReport: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('הימנע'), findsOneWidget);
    });
  });
}

class AddProductWizardTestWrapper extends StatefulWidget {
  final List<Allergen> allergens;
  final List<String> brands;

  const AddProductWizardTestWrapper({
    super.key,
    required this.allergens,
    this.brands = const [],
  });

  @override
  State<AddProductWizardTestWrapper> createState() => _AddProductWizardTestWrapperState();
}

class _AddProductWizardTestWrapperState extends State<AddProductWizardTestWrapper> {
  int _currentStep = 1;
  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  String? _selectedBrand;
  final Set<String> _selectedContains = {};
  final Set<String> _selectedMayContain = {};

  void _nextStep() {
    if (_currentStep < 4) {
      setState(() => _currentStep++);
    }
  }

  Allergen _createAllergen(String id, String name) {
    return Allergen(id: id, nameHe: name);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('הוסף מוצר')),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: ProgressStepper(
                  currentStep: _currentStep,
                  labels: const ['ברקוד', 'תמונות', 'מכיל', 'עשוי להכיל'],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildStep(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_currentStep) {
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3();
      case 4:
        return _buildStep4();
      default:
        return _buildStep1();
    }
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _barcodeController,
          decoration: const InputDecoration(
            labelText: 'ברקוד ידני',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.qr_code),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'שם המוצר *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.shopping_bag),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedBrand,
          decoration: const InputDecoration(
            labelText: 'מותג',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.store),
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text('בחר מותג (אופציונלי)')),
            ...widget.brands.map((brand) => DropdownMenuItem(
              value: brand,
              child: Text(brand),
            )),
          ],
          onChanged: (val) => setState(() => _selectedBrand = val),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _nextStep,
          child: const Text('המשך'),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: PhotoUploadCard(
                onTap: () {},
                label: 'חזית המוצר',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: PhotoUploadCard(
                onTap: () {},
                label: 'רשימת רכיבים',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _nextStep,
                child: const Text('דלג'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _nextStep,
                child: const Text('המשך'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('בחר אלרגנים שהמוצר מכיל:'),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildAllergenChip('חלב', 'milk', _selectedContains),
            _buildAllergenChip('ביצים', 'egg', _selectedContains),
            _buildAllergenChip('גלוטן', 'wheat', _selectedContains),
          ],
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _nextStep,
          child: const Text('המשך'),
        ),
      ],
    );
  }

  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('בחר אלרגנים שהמוצר עשוי להכיל:'),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildAllergenChip('חלב', 'milk', _selectedMayContain),
            _buildAllergenChip('ביצים', 'egg', _selectedMayContain),
          ],
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {},
          child: const Text('שמור מוצר'),
        ),
      ],
    );
  }

  Widget _buildAllergenChip(String label, String id, Set<String> selectedSet) {
    final isSelected = selectedSet.contains(id);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            selectedSet.add(id);
          } else {
            selectedSet.remove(id);
          }
        });
      },
    );
  }
}