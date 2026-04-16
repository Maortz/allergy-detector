class Allergen {
  final String id;
  final String nameHe;
  final String? nameEn;
  final String? iconUrl;

  const Allergen({
    required this.id,
    required this.nameHe,
    this.nameEn,
    this.iconUrl,
  });

  factory Allergen.fromJson(Map<String, dynamic> json) {
    return Allergen(
      id: json['id'] as String,
      nameHe: json['name_he'] as String,
      nameEn: json['name_en'] as String?,
      iconUrl: json['icon_url'] as String?,
    );
  }
}
