import 'package:flutter/foundation.dart';

import '../models/product.dart';

class CartLine {
  final Product product;
  final ProductVariant? variant;
  int quantity;

  CartLine({required this.product, this.variant, this.quantity = 1});

  int get productId => product.id;
  int? get variantId => variant?.id;
  /// Use displayPrice as product price; prefer variant price only when it's valid (> 0)
  double get unitPrice {
    final vp = variant?.price;
    if (vp != null && vp > 0) return vp;
    return product.displayPrice;
  }
  double get lineTotal => unitPrice * quantity;

  String get key => '${product.id}:${variant?.id ?? 0}';
}

class CartProvider extends ChangeNotifier {
  final Map<String, CartLine> _lines = {};

  List<CartLine> get lines => _lines.values.toList();

  double get total => _lines.values.fold(0, (s, l) => s + l.lineTotal);

  void clear() {
    _lines.clear();
    notifyListeners();
  }

  void setLines(List<CartLine> lines) {
    _lines.clear();
    for (final l in lines) {
      _lines[l.key] = l;
    }
    notifyListeners();
  }

  void add(Product product, {ProductVariant? variant}) {
    final k = '${product.id}:${variant?.id ?? 0}';
    final existing = _lines[k];
    if (existing != null) {
      existing.quantity += 1;
    } else {
      _lines[k] = CartLine(product: product, variant: variant, quantity: 1);
    }
    notifyListeners();
  }

  void setQty(CartLine line, int qty) {
    if (qty <= 0) {
      _lines.remove(line.key);
    } else {
      _lines[line.key]?.quantity = qty;
    }
    notifyListeners();
  }
}

