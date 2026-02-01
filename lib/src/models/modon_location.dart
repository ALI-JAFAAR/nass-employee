int _asInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v.trim()) ?? 0;
  return 0;
}

class ModonCity {
  final int id;
  final String name;

  ModonCity({required this.id, required this.name});

  factory ModonCity.fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['id']) != 0 ? _asInt(json['id']) : _asInt(json['city_id']);
    final name = (json['city_name'] as String?) ?? (json['name'] as String?) ?? '${id == 0 ? '' : id}';
    return ModonCity(id: id, name: name);
  }
}

class ModonRegion {
  final int id;
  final int? cityId;
  final String name;

  ModonRegion({required this.id, required this.name, this.cityId});

  factory ModonRegion.fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['id']) != 0 ? _asInt(json['id']) : _asInt(json['region_id']);
    final name = (json['region_name'] as String?) ?? (json['name'] as String?) ?? '${id == 0 ? '' : id}';
    final cityId = _asInt(json['city_id']);
    return ModonRegion(id: id, name: name, cityId: cityId == 0 ? null : cityId);
  }
}

