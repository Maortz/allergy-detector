import 'allergen.dart';

/// A recently-scanned product summary shown on the search/scan screen.
class RecentScan {
  final String name;
  final String brand;
  final String time;
  final AllergenStatus status;

  const RecentScan({
    required this.name,
    required this.brand,
    required this.time,
    required this.status,
  });
}
