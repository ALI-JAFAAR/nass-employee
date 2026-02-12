import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../models/pos_order.dart';
import 'cart_provider.dart';

class OrderProvider extends ChangeNotifier {
  final ApiClient _api;
  OrderProvider({ApiClient? api}) : _api = api ?? ApiClient.I;

  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  bool submitting = false;
  String? error;
  int? lastOrderId;

  bool loadingPending = false;
  List<PosOrderLite> pendingPosOrders = const [];

  bool loadingMyOrders = false;
  List<PosOrderLite> myOrders = const [];

  bool loadingMonthSummary = false;
  int monthOrdersCount = 0;
  double monthEarned = 0;
  double walletBalance = 0;
  String? commissionType; // percent|fixed|null
  double? commissionValue;

  Future<Map<String, dynamic>> fetchPosOrder(int id) async {
    final res = await _api.getJson('/api/v1/cashier/pos-orders/$id');
    return res;
  }

  Future<void> loadMyPendingPosOrders() async {
    loadingPending = true;
    notifyListeners();
    try {
      final res = await _api.getJson('/api/v1/cashier/pos-orders/my-pending');
      final list = (res['data'] as List?) ?? const [];
      pendingPosOrders = list
          .whereType<Map>()
          .map((e) => PosOrderLite.fromJson(e.cast<String, dynamic>()))
          .toList();
    } finally {
      loadingPending = false;
      notifyListeners();
    }
  }

  Future<void> loadMyOrders({String? q}) async {
    loadingMyOrders = true;
    notifyListeners();
    try {
      final res = await _api.getJson('/api/v1/cashier/pos-orders/my', query: {
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        'limit': 100,
        'include_modon': true,
      });
      final list = (res['data'] as List?) ?? const [];
      myOrders = list
          .whereType<Map>()
          .map((e) => PosOrderLite.fromJson(e.cast<String, dynamic>()))
          .toList();
    } finally {
      loadingMyOrders = false;
      notifyListeners();
    }
  }

  Future<void> loadMyMonthSummary() async {
    loadingMonthSummary = true;
    notifyListeners();
    try {
      final res = await _api.getJson('/api/v1/cashier/employee/wallet-summary');
      monthOrdersCount = (res['orders_count'] as num?)?.toInt() ?? 0;
      monthEarned = _toDouble(res['earned_this_month']);
      walletBalance = _toDouble(res['wallet_balance']);
      commissionType = res['commission_type'] as String?;
      final cv = res['commission_value'];
      commissionValue = cv == null ? null : _toDouble(cv);
    } finally {
      loadingMonthSummary = false;
      notifyListeners();
    }
  }

  Future<int?> submitPosOrder({
    required CartProvider cart,
    required String customerName,
    required String customerPhone,
    required int deliveryCityId,
    required int deliveryRegionId,
    required String addressText,
    String? merchantNotes,
  }) async {
    if (cart.lines.isEmpty) {
      throw Exception('السلة فارغة');
    }

    submitting = true;
    error = null;
    lastOrderId = null;
    notifyListeners();

    try {
      final vendorId = await _api.getVendorId();

      final payload = <String, dynamic>{
        'vendor_id': vendorId,
        'customer_name': customerName.trim(),
        'customer_phone': customerPhone.trim(),
        'address_text': addressText.trim(),
        'delivery_provider': 'modon',
        'delivery_city_id': deliveryCityId,
        'delivery_region_id': deliveryRegionId,
        if (merchantNotes != null && merchantNotes.trim().isNotEmpty) 'merchant_notes': merchantNotes.trim(),
        'items': cart.lines
            .map(
              (l) => {
                'product_id': l.productId,
                if (l.variantId != null) 'variant_id': l.variantId,
                'quantity': l.quantity,
              },
            )
            .toList(),
      };

      final res = await _api.postJson('/api/v1/cashier/pos-orders', payload);
      lastOrderId = (res['id'] as num?)?.toInt();
      cart.clear();
      // refresh month summary after new order (commission credited)
      try {
        await loadMyMonthSummary();
      } catch (_) {}
      return lastOrderId;
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      submitting = false;
      notifyListeners();
    }
  }

  Future<void> updatePosOrder({
    required int orderId,
    required CartProvider cart,
    required String customerName,
    required String customerPhone,
    required int deliveryCityId,
    required int deliveryRegionId,
    required String addressText,
    String? merchantNotes,
  }) async {
    if (cart.lines.isEmpty) throw Exception('السلة فارغة');

    submitting = true;
    error = null;
    notifyListeners();
    try {
      final payload = <String, dynamic>{
        'customer_name': customerName.trim(),
        'customer_phone': customerPhone.trim(),
        'address_text': addressText.trim(),
        'delivery_provider': 'modon',
        'delivery_city_id': deliveryCityId,
        'delivery_region_id': deliveryRegionId,
        if (merchantNotes != null && merchantNotes.trim().isNotEmpty) 'merchant_notes': merchantNotes.trim(),
        'items': cart.lines
            .map(
              (l) => {
                'product_id': l.productId,
                if (l.variantId != null) 'variant_id': l.variantId,
                'quantity': l.quantity,
              },
            )
            .toList(),
      };
      await _api.postAny('/api/v1/cashier/pos-orders/$orderId?_method=PUT', payload);
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      submitting = false;
      notifyListeners();
    }
  }
}

