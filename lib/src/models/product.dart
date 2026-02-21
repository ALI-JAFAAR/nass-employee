class ProductVariant {
  final int id;
  final double price;
  final int? stock;
  final String? sku;
  final String? color;
  final String? size;
  final String? label;

  ProductVariant({
    required this.id,
    required this.price,
    this.stock,
    this.sku,
    this.color,
    this.size,
    this.label,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: (json['id'] as num).toInt(),
      price: (json['price'] as num?)?.toDouble() ?? 0,
      stock: (json['stock'] as num?)?.toInt(),
      sku: json['sku'] as String?,
      color: json['color'] as String?,
      size: json['size'] as String?,
      label: json['label'] as String?,
    );
  }
}

class Product {
  final int id;
  final String name;
  final String? sku;
  final double price;
  final int stock;
  final String? image;
  final List<ProductVariant> variants;
  final bool isAgencyProduct;
  final double? agencyPrice;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    this.sku,
    this.image,
    this.variants = const [],
    this.isAgencyProduct = false,
    this.agencyPrice,
  });

  /// Agency products: add without variant picker, use single price.
  bool get addWithoutVariantSelection =>
      isAgencyProduct || variants.isEmpty || variants.length == 1;

  /// Display price: prefer agency_price when product is agency and price is 0.
  double get displayPrice =>
      (isAgencyProduct && (price == 0 || price.isNaN) && agencyPrice != null)
          ? agencyPrice!
          : price;

  factory Product.fromJson(Map<String, dynamic> json) {
    final vars = (json['variants'] as List?) ?? const [];
    return Product(
      id: (json['id'] as num).toInt(),
      name: (json['name'] as String?) ?? '',
      sku: json['sku'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      image: json['image'] as String?,
      variants: vars.whereType<Map<String, dynamic>>().map(ProductVariant.fromJson).toList(),
      isAgencyProduct: (json['is_agency_product'] as bool?) ?? false,
      agencyPrice: (json['agency_price'] as num?)?.toDouble(),
    );
  }
}

