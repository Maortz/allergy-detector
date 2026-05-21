class Brand {
  final String? id;
  final String name;
  final String? logoUrl;
  final bool isVerified;
  final DateTime? lastUpdated;
  final String? notes;

  const Brand({
    this.id,
    required this.name,
    this.logoUrl,
    this.isVerified = false,
    this.lastUpdated,
    this.notes,
  });

  Brand copyWith({
    String? id,
    String? name,
    String? logoUrl,
    bool? isVerified,
    DateTime? lastUpdated,
    String? notes,
  }) {
    return Brand(
      id: id ?? this.id,
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      isVerified: isVerified ?? this.isVerified,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      notes: notes ?? this.notes,
    );
  }

  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(
      id: json['id'] as String?,
      name: json['name'] as String,
      logoUrl: json['logo_url'] as String?,
      isVerified: (json['is_verified'] as bool?) ?? false,
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'] as String)
          : null,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name': name,
      'logo_url': logoUrl,
      'is_verified': isVerified,
      'notes': notes,
    };
    if (id != null) map['id'] = id;
    return map;
  }
}
