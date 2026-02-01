import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../models/employee_user.dart';

class EmployeeAuthProvider extends ChangeNotifier {
  final ApiClient _api;

  EmployeeAuthProvider({ApiClient? api}) : _api = api ?? ApiClient.I {
    _api.onUnauthorized = () {
      logout();
    };
  }

  bool loading = false;
  EmployeeUser? user;

  bool get authed => user != null;

  Future<void> bootstrap() async {
    loading = true;
    notifyListeners();
    try {
      final token = await _api.getToken();
      if (token == null || token.isEmpty) {
        user = null;
        return;
      }
      // Validate token + load profile (staff endpoint).
      final res = await _api.getJson('/api/v1/me');
      final uJson = (res['user'] as Map?)?.cast<String, dynamic>();
      if (uJson == null) {
        await _api.clearSession();
        user = null;
        return;
      }
      final u = EmployeeUser.fromJson(uJson);
      // Ensure vendor_id is saved so X-Vendor-Id header is sent.
      final existingVendor = await _api.getVendorId();
      if ((existingVendor ?? 0) == 0) {
        await _api.setSession(token: token, vendorId: u.vendorId);
      }
      user = u;
    } catch (_) {
      await _api.clearSession();
      user = null;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> login({required String username, required String password}) async {
    loading = true;
    notifyListeners();
    try {
      final res = await _api.postJson('/api/v1/employee/login', {
        'username': username,
        'password': password,
      });
      final token = (res['token'] as String?) ?? '';
      final userJson = (res['user'] as Map?)?.cast<String, dynamic>();
      if (token.isEmpty || userJson == null) {
        throw Exception('فشل تسجيل الدخول');
      }
      final u = EmployeeUser.fromJson(userJson);
      await _api.setSession(token: token, vendorId: u.vendorId);
      user = u;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _api.clearSession();
    user = null;
    notifyListeners();
  }

  Future<void> updateMe({
    String? name,
    String? username,
    String? email,
    String? password,
    String? passwordConfirmation,
  }) async {
    loading = true;
    notifyListeners();
    try {
      final payload = <String, dynamic>{
        if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
        if (username != null && username.trim().isNotEmpty) 'username': username.trim(),
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
        if (password != null && password.isNotEmpty) 'password': password,
        if (passwordConfirmation != null && passwordConfirmation.isNotEmpty)
          'password_confirmation': passwordConfirmation,
      };

      final res = await _api.putJson('/api/v1/me', payload);
      final uJson = (res['user'] as Map?)?.cast<String, dynamic>();
      if (uJson != null) {
        user = EmployeeUser.fromJson(uJson);
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}

