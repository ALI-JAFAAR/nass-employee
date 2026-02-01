import 'package:flutter/foundation.dart';

import '../api/api_client.dart';

class EmployeeReportSummary {
  final int ordersCount;
  final double ordersTotal;
  final int salesCount;
  final double salesTotal;

  EmployeeReportSummary({
    required this.ordersCount,
    required this.ordersTotal,
    required this.salesCount,
    required this.salesTotal,
  });

  factory EmployeeReportSummary.fromJson(Map<String, dynamic> json) {
    final orders = (json['orders'] as Map?)?.cast<String, dynamic>() ?? const {};
    final sales = (json['sales'] as Map?)?.cast<String, dynamic>() ?? const {};
    return EmployeeReportSummary(
      ordersCount: (orders['count'] as num?)?.toInt() ?? 0,
      ordersTotal: (orders['total'] as num?)?.toDouble() ?? 0,
      salesCount: (sales['count'] as num?)?.toInt() ?? 0,
      salesTotal: (sales['total'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ReportsProvider extends ChangeNotifier {
  final ApiClient _api;
  ReportsProvider({ApiClient? api}) : _api = api ?? ApiClient.I;

  bool loading = false;
  String? error;
  EmployeeReportSummary? employee;

  Future<void> load({required String from, required String to}) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final res = await _api.getJson('/api/v1/cashier/reports/employee', query: {
        'from': from,
        'to': to,
      });
      employee = EmployeeReportSummary.fromJson(res);
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      employee = null;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}

