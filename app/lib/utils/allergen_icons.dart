import 'package:flutter/material.dart';
import '../models/allergen.dart';

/// Maps an [Allergen] to its canonical Material icon per `_components-glossary.md`
/// `#allergen-chip`. Falls back to [Icons.label_outline] when the id doesn't
/// match any known allergen — so the icon language stays Material across the
/// app, even when [Allergen.emoji] is absent.
IconData allergenIconFor(Allergen allergen) {
  final id = allergen.id.toLowerCase();
  if (id.contains('milk') || id.contains('dairy')) return Icons.water_drop;
  if (id.contains('egg')) return Icons.egg;
  if (id.contains('wheat') || id.contains('gluten')) {
    return Icons.bakery_dining;
  }
  if (id.contains('soy')) return Icons.eco;
  if (id.contains('peanut')) return Icons.scatter_plot;
  if (id.contains('nut')) return Icons.park;
  if (id.contains('shellfish') || id.contains('crustacean')) return Icons.pool;
  if (id.contains('fish')) return Icons.set_meal;
  if (id.contains('sesame')) return Icons.grain;
  return Icons.label_outline;
}
