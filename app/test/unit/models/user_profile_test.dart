import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/allergen.dart';
import 'package:app/models/user_profile.dart';

void main() {
  group('UserProfile', () {
    test('default values are empty', () {
      const profile = UserProfile();
      expect(profile.selectedAllergenIds, isEmpty);
      expect(profile.hasCompletedOnboarding, false);
    });

    test('constructor accepts parameters', () {
      final profile = UserProfile(
        selectedAllergenIds: {'1', '2'},
        hasCompletedOnboarding: true,
      );
      expect(profile.selectedAllergenIds, {'1', '2'});
      expect(profile.hasCompletedOnboarding, true);
    });

    test('isAllergenSelected returns correct value', () {
      const profile = UserProfile(selectedAllergenIds: {'1', '2'});
      expect(profile.isAllergenSelected('1'), true);
      expect(profile.isAllergenSelected('3'), false);
    });

    test('toggleAllergen adds new allergen', () {
      const profile = UserProfile(selectedAllergenIds: {'1'});
      const allergen = Allergen(id: '2', nameHe: 'חלב');
      final updated = profile.toggleAllergen(allergen);
      expect(updated.selectedAllergenIds, {'1', '2'});
    });

    test('toggleAllergen removes existing allergen', () {
      const profile = UserProfile(selectedAllergenIds: {'1', '2'});
      const allergen = Allergen(id: '1', nameHe: 'גלוטן');
      final updated = profile.toggleAllergen(allergen);
      expect(updated.selectedAllergenIds, {'2'});
    });

    test('toggleAllergen returns new instance', () {
      const profile = UserProfile(selectedAllergenIds: {'1'});
      const allergen = Allergen(id: '2', nameHe: 'חלב');
      final updated = profile.toggleAllergen(allergen);
      expect(identical(profile, updated), false);
    });

    test('copyWith creates new instance', () {
      const profile = UserProfile(selectedAllergenIds: {'1'}, hasCompletedOnboarding: false);
      final updated = profile.copyWith(hasCompletedOnboarding: true);
      expect(updated.hasCompletedOnboarding, true);
      expect(updated.selectedAllergenIds, {'1'});
    });

    test('copyWith preserves unchanged values', () {
      const profile = UserProfile(selectedAllergenIds: {'1', '2'}, hasCompletedOnboarding: true);
      final updated = profile.copyWith(selectedAllergenIds: {'3'});
      expect(updated.selectedAllergenIds, {'3'});
      expect(updated.hasCompletedOnboarding, true);
    });

    test('copyWith returns new instance', () {
      const profile = UserProfile();
      final updated = profile.copyWith(hasCompletedOnboarding: true);
      expect(identical(profile, updated), false);
    });
  });
}