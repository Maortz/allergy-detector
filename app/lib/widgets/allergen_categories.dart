// Hard-coded allergen → sub-section category mapping used by the add-product
// wizard (step 3 and step 4). Per spec resolution `add-product-step-3-contains
// §7.2` / `add-product-step-4-may-contain §7.2` the catalog has no `category`
// column; the wizard groups by allergen `nameEn` here.
//
// See `docs/superpowers/specs/2026-05-19-stitch-screens/add-product-step-4-may-contain.md`
// §7.2.

import '../models/allergen.dart';

enum AllergenCategory {
  dairyEggs, // "חלב וביצים"
  glutenLegumes, // "גלוטן וקטניות"
  nutsSeeds, // "אגוזים וזרעים"
  other, // catch-all (e.g. fish), rendered at end if non-empty
}

/// Hebrew display title for a category, used as the sub-section header.
String allergenCategoryTitle(AllergenCategory category) {
  switch (category) {
    case AllergenCategory.dairyEggs:
      return 'חלב וביצים';
    case AllergenCategory.glutenLegumes:
      return 'גלוטן וקטניות';
    case AllergenCategory.nutsSeeds:
      return 'אגוזים וזרעים';
    case AllergenCategory.other:
      return 'אחר';
  }
}

/// Stable display order for the sub-sections.
const List<AllergenCategory> kAllergenCategoryOrder = [
  AllergenCategory.dairyEggs,
  AllergenCategory.glutenLegumes,
  AllergenCategory.nutsSeeds,
  AllergenCategory.other,
];

/// Classify a catalog allergen into a wizard sub-section category. Matches on
/// `nameEn` first (canonical, seeded for every catalog entry), then falls back
/// to `nameHe` for resilience.
AllergenCategory categoryFor(Allergen allergen) {
  final key = '${allergen.nameEn ?? ''} ${allergen.nameHe}'.toLowerCase();
  if (key.contains('dairy') ||
      key.contains('milk') ||
      key.contains('egg') ||
      key.contains('חלב') ||
      key.contains('ביצים')) {
    return AllergenCategory.dairyEggs;
  }
  if (key.contains('gluten') ||
      key.contains('wheat') ||
      key.contains('soy') ||
      key.contains('legume') ||
      key.contains('peanut') ||
      key.contains('גלוטן') ||
      key.contains('סויה') ||
      key.contains('בוטנים')) {
    return AllergenCategory.glutenLegumes;
  }
  if (key.contains('nut') ||
      key.contains('almond') ||
      key.contains('cashew') ||
      key.contains('pistachio') ||
      key.contains('pecan') ||
      key.contains('hazelnut') ||
      key.contains('pine') ||
      key.contains('sesame') ||
      key.contains('אגוז') ||
      key.contains('שקד') ||
      key.contains('קשיו') ||
      key.contains('פיסטוק') ||
      key.contains('פקאן') ||
      key.contains('שומשום') ||
      key.contains('צנובר')) {
    return AllergenCategory.nutsSeeds;
  }
  return AllergenCategory.other;
}

/// Group a flat catalog into ordered sub-sections.
Map<AllergenCategory, List<Allergen>> groupAllergensByCategory(
  Iterable<Allergen> allergens,
) {
  final groups = <AllergenCategory, List<Allergen>>{
    for (final c in kAllergenCategoryOrder) c: <Allergen>[],
  };
  for (final a in allergens) {
    groups[categoryFor(a)]!.add(a);
  }
  return groups;
}
