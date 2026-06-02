import 'allergen.dart';
import 'product.dart';

/// How strictly product results are filtered by their safety verdict.
/// Persisted to SharedPreferences key `product_filter_level`.
enum ProductFilterLevel {
  /// Show everything — including products tagged "avoid".
  avoidOnly('avoid_only'),

  /// Show safe + caution; hide "avoid" products. Default.
  cautionAndAbove('caution_and_above'),

  /// Show only fully-safe products; hide both "caution" and "avoid".
  safeOnly('safe_only');

  const ProductFilterLevel(this.storageValue);

  final String storageValue;

  static ProductFilterLevel fromStorage(String? value) {
    return ProductFilterLevel.values.firstWhere(
      (level) => level.storageValue == value,
      orElse: () => ProductFilterLevel.cautionAndAbove,
    );
  }

  /// Whether a product with this [status] should be visible at this level.
  bool allows(AllergenStatus status) {
    switch (this) {
      case ProductFilterLevel.avoidOnly:
        return true;
      case ProductFilterLevel.cautionAndAbove:
        return status != AllergenStatus.avoid;
      case ProductFilterLevel.safeOnly:
        return status == AllergenStatus.safe;
    }
  }
}

class UserProfile {
  final Set<String> selectedAllergenIds;
  final bool hasCompletedOnboarding;
  final String? displayName;
  final String? email;
  final String? avatarData;
  final ProductFilterLevel productFilterLevel;

  const UserProfile({
    this.selectedAllergenIds = const {},
    this.hasCompletedOnboarding = false,
    this.displayName,
    this.email,
    this.avatarData,
    this.productFilterLevel = ProductFilterLevel.cautionAndAbove,
  });

  UserProfile copyWith({
    Set<String>? selectedAllergenIds,
    bool? hasCompletedOnboarding,
    String? displayName,
    String? email,
    String? avatarData,
    ProductFilterLevel? productFilterLevel,
  }) {
    return UserProfile(
      selectedAllergenIds: selectedAllergenIds ?? this.selectedAllergenIds,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      avatarData: avatarData ?? this.avatarData,
      productFilterLevel: productFilterLevel ?? this.productFilterLevel,
    );
  }

  bool isAllergenSelected(String allergenId) =>
      selectedAllergenIds.contains(allergenId);

  UserProfile toggleAllergen(Allergen allergen) {
    final updated = Set<String>.from(selectedAllergenIds);
    if (updated.contains(allergen.id)) {
      updated.remove(allergen.id);
    } else {
      updated.add(allergen.id);
    }
    return copyWith(selectedAllergenIds: updated);
  }

  /// Computes the safety verdict for [product] against this profile's selected
  /// allergens. Drives both the product-card badge and screen-level filtering
  /// against [productFilterLevel].
  AllergenStatus statusFor(Product product) {
    for (final a in product.containsAllergens) {
      if (selectedAllergenIds.contains(a.allergenId)) {
        return AllergenStatus.avoid;
      }
    }
    for (final a in product.mayContainAllergens) {
      if (selectedAllergenIds.contains(a.allergenId)) {
        return AllergenStatus.caution;
      }
    }
    return AllergenStatus.safe;
  }
}
