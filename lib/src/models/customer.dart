class CustomerLite {
  final int id;
  final String? name;
  final String? username;
  final String? phone;

  CustomerLite({
    required this.id,
    this.name,
    this.username,
    this.phone,
  });

  factory CustomerLite.fromJson(Map<String, dynamic> json) {
    return CustomerLite(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String?,
      username: json['username'] as String?,
      phone: json['phone'] as String?,
    );
  }
}

