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

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    this.sku,
    this.image,
    this.variants = const [],
  });

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
    );
  }
}

