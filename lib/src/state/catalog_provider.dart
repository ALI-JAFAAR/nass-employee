import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../models/brand.dart';
import '../models/category.dart';
import '../models/product.dart';

class CatalogProvider extends ChangeNotifier {
  final ApiClient _api;
  CatalogProvider({ApiClient? api}) : _api = api ?? ApiClient();

  bool loading = false;
  bool loadingMore = false;
  bool loadingFilters = false;
  String query = '';
  String sort = 'newest'; // newest|name|brand
  int perPage = 20;
  int _page = 1;
  bool hasMore = true;

  int? brandId;
  int? categoryId;
  List<BrandLite> brands = const [];
  List<CategoryLite> categories = const [];

  List<Product> products = const [];
  String? error;

  Future<void> loadFilters() async {
    if (loadingFilters) return;
    loadingFilters = true;
    notifyListeners();
    try {
      final b = await _api.getJson('/api/v1/cashier/brands');
      final c = await _api.getJson('/api/v1/cashier/categories');
      final bl = (b['data'] as List?) ?? const [];
      final cl = (c['data'] as List?) ?? const [];
      brands = bl.whereType<Map>().map((e) => BrandLite.fromJson(e.cast<String, dynamic>())).toList();
      categories = cl.whereType<Map>().map((e) => CategoryLite.fromJson(e.cast<String, dynamic>())).toList();
    } catch (_) {
      // ignore (filters are optional)
    } finally {
      loadingFilters = false;
      notifyListeners();
    }
  }

  void setBrand(int? id) {
    brandId = (id != null && id > 0) ? id : null;
    refresh();
  }

  void setCategory(int? id) {
    categoryId = (id != null && id > 0) ? id : null;
    refresh();
  }

  void setSort(String v) {
    sort = v;
    refresh();
  }

  Future<void> refresh({String? q}) async {
    query = (q ?? query).trim();
    _page = 1;
    hasMore = true;
    products = const [];
    await _fetch(page: 1, append: false);
  }

  Future<void> search({String? q}) async {
    await refresh(q: q);
  }

  Future<void> loadMore() async {
    if (loading || loadingMore || !hasMore) return;
    loadingMore = true;
    notifyListeners();
    try {
      await _fetch(page: _page + 1, append: true);
    } finally {
      loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> _fetch({required int page, required bool append}) async {
    if (!append) {
      loading = true;
      error = null;
      notifyListeners();
    }
    try {
      final res = await _api.getJson('/api/v1/cashier/products', query: {
        if (query.isNotEmpty) 'q': query,
        if (brandId != null) 'brand_id': '$brandId',
        if (categoryId != null) 'category_id': '$categoryId',
        'page': '$page',
        'per_page': '$perPage',
        'sort': sort,
      });

      final list = (res['data'] as List?) ?? const [];
      final items = list
          .whereType<Map>()
          .map((e) => Product.fromJson(e.cast<String, dynamic>()))
          .toList();

      final current = (res['current_page'] as num?)?.toInt();
      final last = (res['last_page'] as num?)?.toInt();
      if (current != null && last != null) {
        _page = current;
        hasMore = current < last;
      } else {
        // Non-paginated fallback
        _page = page;
        hasMore = false;
      }

      products = append ? [...products, ...items] : items;
    } catch (e) {
      error = e.toString();
      if (!append) products = const [];
    } finally {
      if (!append) {
        loading = false;
        notifyListeners();
      }
    }
  }
}

