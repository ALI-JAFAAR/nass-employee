class CategoryLite {
  final int id;
  final String name;
  final int? parentId;

  CategoryLite({required this.id, required this.name, this.parentId});

  factory CategoryLite.fromJson(Map<String, dynamic> json) {
    return CategoryLite(
      id: (json['id'] as num).toInt(),
      name: (json['name'] as String?) ?? '',
      parentId: (json['parent_id'] as num?)?.toInt(),
    );
  }
}

