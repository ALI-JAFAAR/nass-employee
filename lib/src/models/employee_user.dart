class EmployeeUser {
  final int id;
  final String? name;
  final String username;
  final String? email;
  final int? vendorId;
  final String? role;

  EmployeeUser({
    required this.id,
    required this.username,
    this.name,
    this.email,
    this.vendorId,
    this.role,
  });

  factory EmployeeUser.fromJson(Map<String, dynamic> json) {
    return EmployeeUser(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String?,
      username: (json['username'] as String?) ?? '',
      email: json['email'] as String?,
      vendorId: (json['vendor_id'] as num?)?.toInt(),
      role: json['role'] as String?,
    );
  }
}

