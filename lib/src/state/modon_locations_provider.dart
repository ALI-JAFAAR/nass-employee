import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../models/modon_location.dart';

class ModonLocationsProvider extends ChangeNotifier {
  final ApiClient _api;
  ModonLocationsProvider({ApiClient? api}) : _api = api ?? ApiClient.I;

  bool loadingCities = false;
  bool loadingRegions = false;
  String? error;

  List<ModonCity> cities = const [];
  final Map<int, List<ModonRegion>> _regionsByCity = {};

  Future<void> loadCities() async {
    if (loadingCities) return;
    loadingCities = true;
    error = null;
    notifyListeners();
    try {
      final res = await _api.getJson('/api/v1/cashier/delivery/cities');
      final list = (res['data'] as List?) ?? const [];
      cities = list.whereType<Map>().map((e) => ModonCity.fromJson(e.cast<String, dynamic>())).toList();
    } catch (e) {
      error = e.toString();
    } finally {
      loadingCities = false;
      notifyListeners();
    }
  }

  List<ModonRegion> regionsForCity(int cityId) => _regionsByCity[cityId] ?? const [];

  Future<void> loadRegions(int cityId) async {
    if (cityId <= 0) return;
    if (_regionsByCity.containsKey(cityId) && _regionsByCity[cityId]!.isNotEmpty) return;
    if (loadingRegions) return;

    loadingRegions = true;
    error = null;
    notifyListeners();
    try {
      final res = await _api.getJson('/api/v1/cashier/delivery/regions', query: {'city_id': cityId});
      final list = (res['data'] as List?) ?? const [];
      _regionsByCity[cityId] = list.whereType<Map>().map((e) => ModonRegion.fromJson(e.cast<String, dynamic>())).toList();
    } catch (e) {
      error = e.toString();
    } finally {
      loadingRegions = false;
      notifyListeners();
    }
  }
}

