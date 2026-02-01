class BrandLite {
  final int id;
  final String name;

  BrandLite({required this.id, required this.name});

  factory BrandLite.fromJson(Map<String, dynamic> json) {
    return BrandLite(
      id: (json['id'] as num).toInt(),
      name: (json['name'] as String?) ?? '',
    );
  }
}

