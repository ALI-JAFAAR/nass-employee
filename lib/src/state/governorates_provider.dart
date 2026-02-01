import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../models/governorate.dart';

class GovernoratesProvider extends ChangeNotifier {
  final ApiClient _api;
  GovernoratesProvider({ApiClient? api}) : _api = api ?? ApiClient.I;

  bool loading = false;
  String? error;
  List<GovernorateLite> items = const [];

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final res = await _api.getAny('/api/v1/governorates');
      final list = res is List ? res : const [];
      items = list
          .whereType<Map>()
          .map((e) => GovernorateLite.fromJson(e.cast<String, dynamic>()))
          .toList();
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}

