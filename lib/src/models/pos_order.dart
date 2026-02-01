class PosOrderLite {
  final int id;
  final String status;
  final double total;
  final String? createdAt;
  final String? customerName;
  final String? customerPhone;
  final int? governorateId;
  final String? governorateName;
  final String? addressText;
  final int? deliveryCityId;
  final String? deliveryCityName;
  final int? deliveryRegionId;
  final String? deliveryRegionName;
  final String? deliveryExternalId;
  final String? modonStatus;
  final String? merchantNotes;
  final String? suspendedNote;

  PosOrderLite({
    required this.id,
    required this.status,
    required this.total,
    this.createdAt,
    this.customerName,
    this.customerPhone,
    this.governorateId,
    this.governorateName,
    this.addressText,
    this.deliveryCityId,
    this.deliveryCityName,
    this.deliveryRegionId,
    this.deliveryRegionName,
    this.deliveryExternalId,
    this.modonStatus,
    this.merchantNotes,
    this.suspendedNote,
  });

  factory PosOrderLite.fromJson(Map<String, dynamic> json) {
    return PosOrderLite(
      id: (json['id'] as num).toInt(),
      status: (json['status'] as String?) ?? 'pending',
      total: (json['total'] as num?)?.toDouble() ?? 0,
      createdAt: json['created_at'] as String?,
      customerName: json['customer_name'] as String?,
      customerPhone: json['customer_phone'] as String?,
      governorateId: (json['governorate_id'] as num?)?.toInt(),
      governorateName: json['governorate_name'] as String?,
      addressText: json['address_text'] as String?,
      deliveryCityId: (json['delivery_city_id'] as num?)?.toInt(),
      deliveryCityName: json['delivery_city_name'] as String?,
      deliveryRegionId: (json['delivery_region_id'] as num?)?.toInt(),
      deliveryRegionName: json['delivery_region_name'] as String?,
      deliveryExternalId: json['delivery_external_id'] as String?,
      modonStatus: json['modon_status'] as String?,
      merchantNotes: json['merchant_notes'] as String?,
      suspendedNote: json['suspended_note'] as String?,
    );
  }
}

