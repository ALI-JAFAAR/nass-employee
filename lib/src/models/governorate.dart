class GovernorateLite {
  final int id;
  final String name;

  GovernorateLite({required this.id, required this.name});

  factory GovernorateLite.fromJson(Map<String, dynamic> json) {
    return GovernorateLite(
      id: (json['id'] as num).toInt(),
      name: (json['name'] as String?) ?? (json['title'] as String?) ?? '—',
    );
  }
}

