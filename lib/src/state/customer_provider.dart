import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../models/customer.dart';

class CustomerProvider extends ChangeNotifier {
  final ApiClient _api;
  CustomerProvider({ApiClient? api}) : _api = api ?? ApiClient();

  bool loading = false;
  String query = '';
  List<CustomerLite> results = const [];
  CustomerLite? selected;
  String? error;

  Future<void> search(String q) async {
    query = q.trim();
    if (query.isEmpty) {
      results = const [];
      notifyListeners();
      return;
    }
    loading = true;
    error = null;
    notifyListeners();
    try {
      final res = await _api.getJson('/api/v1/cashier/customers', query: {
        'q': query,
        'limit': 25,
      });
      final list = (res['data'] as List?) ?? const [];
      results = list
          .whereType<Map>()
          .map((e) => CustomerLite.fromJson(e.cast<String, dynamic>()))
          .toList();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void select(CustomerLite c) {
    selected = c;
    results = const [];
    notifyListeners();
  }

  void clearSelected() {
    selected = null;
    notifyListeners();
  }
}

