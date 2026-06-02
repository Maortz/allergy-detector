import 'allergen.dart';

/// How strictly product results are filtered by their safety verdict.
/// Persisted to SharedPreferences key `product_filter_level`.
///
/// `showAll` is the loosest setting — nothing is hidden, including `avoid`
/// products. Storage value stays `'avoid_only'` for backwards compatibility
/// with profiles persisted before the identifier was renamed.
enum ProductFilterLevel {
  showAll('avoid_only'),
  cautionAndAbove('caution_and_above'),
  safeOnly('safe_only');

  const ProductFilterLevel(this.storageValue);

  final String storageValue;

  static ProductFilterLevel fromStorage(String? value) {
    return ProductFilterLevel.values.firstWhere(
      (level) => level.storageValue == value,
      orElse: () => ProductFilterLevel.cautionAndAbove,
    );
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
}
