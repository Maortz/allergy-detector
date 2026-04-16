import 'allergen.dart';

class UserProfile {
  final Set<String> selectedAllergenIds;
  final bool hasCompletedOnboarding;

  const UserProfile({
    this.selectedAllergenIds = const {},
    this.hasCompletedOnboarding = false,
  });

  UserProfile copyWith({
    Set<String>? selectedAllergenIds,
    bool? hasCompletedOnboarding,
  }) {
    return UserProfile(
      selectedAllergenIds: selectedAllergenIds ?? this.selectedAllergenIds,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
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
