import 'package:app/models/allergen.dart';
import 'package:app/models/product.dart';
import 'package:app/models/user_profile.dart';

class TestFixtures {
  TestFixtures._();

  static const List<Allergen> sampleAllergens = [
    Allergen(id: '1', nameHe: 'גלוטן', nameEn: 'Gluten'),
    Allergen(id: '2', nameHe: 'חלב', nameEn: 'Milk'),
    Allergen(id: '3', nameHe: 'ביצים', nameEn: 'Eggs'),
    Allergen(id: '4', nameHe: 'אגוזים', nameEn: 'Nuts'),
    Allergen(id: '5', nameHe: 'סויה', nameEn: 'Soy'),
  ];

  static final Product sampleProduct = Product(
    id: 'prod-123',
    nameHe: 'פסטו בולו',
    barcode: '7290123456789',
    brandId: 'brand-1',
    brandNameHe: 'טרה',
    brandTrustScore: 0.85,
    imageUrl: 'https://example.com/pesto.jpg',
    ingredients: 'שמן זית, בזיליקום, גבינה, מלח',
    isKosher: true,
    allergens: [
      ProductAllergen(allergenId: '1', allergenNameHe: 'גלוטן', severity: 'contains'),
      ProductAllergen(allergenId: '2', allergenNameHe: 'חלב', severity: 'may_contain'),
    ],
  );

  static const UserProfile sampleProfile = UserProfile(
    selectedAllergenIds: {'1', '2'},
    hasCompletedOnboarding: true,
  );

  static Product createProduct({
    String? id,
    String? nameHe,
    List<ProductAllergen>? allergens,
  }) {
    return Product(
      id: id ?? 'test-prod',
      nameHe: nameHe ?? 'מוצר בדיקה',
      allergens: allergens ?? [],
    );
  }

  static Allergen createAllergen({
    String? id,
    String? nameHe,
    String? nameEn,
  }) {
    return Allergen(
      id: id ?? 'test-allergen',
      nameHe: nameHe ?? 'אלרגן בדיקה',
      nameEn: nameEn,
    );
  }

  static UserProfile createUserProfile({
    Set<String>? selectedAllergenIds,
    bool? hasCompletedOnboarding,
  }) {
    return UserProfile(
      selectedAllergenIds: selectedAllergenIds ?? {},
      hasCompletedOnboarding: hasCompletedOnboarding ?? false,
    );
  }
}