import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  @override
  String toString() => message;
}

class ApiClient {
  static const _tokenKey = 'employee_auth_token';
  static const _vendorIdKey = 'employee_vendor_id';

  static final ApiClient I = ApiClient._();

  final http.Client _client;

  /// Called when the backend returns 401 (invalid/expired token).
  VoidCallback? onUnauthorized;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();
  ApiClient._({http.Client? client}) : _client = client ?? http.Client();

  Future<String?> getToken() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_tokenKey);
  }

  Future<int?> getVendorId() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_vendorIdKey);
  }

  Future<void> setSession({required String token, int? vendorId}) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_tokenKey, token);
    if (vendorId != null) {
      await sp.setInt(_vendorIdKey, vendorId);
    } else {
      await sp.remove(_vendorIdKey);
    }
  }

  Future<void> clearSession() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_tokenKey);
    await sp.remove(_vendorIdKey);
  }

  Uri _u(String path, [Map<String, dynamic>? query]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final base = '${AppConfig.baseUrl}$cleanPath';
    return Uri.parse(base).replace(
      queryParameters: query?.map((k, v) => MapEntry(k, '$v')),
    );
  }

  Future<Map<String, String>> _headers({Map<String, String>? extra}) async {
    final token = await getToken();
    final vendorId = await getVendorId();
    return <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json; charset=utf-8',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      // Helps vendor.context middleware and cashier endpoints.
      if (vendorId != null && vendorId > 0) 'X-Vendor-Id': '$vendorId',
      ...?extra,
    };
  }

  Future<Map<String, dynamic>> postJson(String path, Map<String, dynamic> body) async {
    final res = await _client.post(
      _u(path),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return await _decodeOrThrow(res);
  }

  Future<Map<String, dynamic>> getJson(String path, {Map<String, dynamic>? query}) async {
    final res = await _client.get(
      _u(path, query),
      headers: await _headers(),
    );
    return await _decodeOrThrow(res);
  }

  Future<Map<String, dynamic>> putJson(String path, Map<String, dynamic> body) async {
    final res = await _client.put(
      _u(path),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return await _decodeOrThrow(res);
  }

  Future<dynamic> getAny(String path, {Map<String, dynamic>? query}) async {
    final res = await _client.get(
      _u(path, query),
      headers: await _headers(),
    );
    return await _decodeAnyOrThrow(res);
  }

  Future<dynamic> postAny(String path, Map<String, dynamic> body) async {
    final res = await _client.post(
      _u(path),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return await _decodeAnyOrThrow(res);
  }

  Future<Map<String, dynamic>> _decodeOrThrow(http.Response res) async {
    final decoded = await _decodeAnyOrThrow(res);
    if (decoded is Map<String, dynamic>) return decoded;
    return <String, dynamic>{};
  }

  Future<dynamic> _decodeAnyOrThrow(http.Response res) async {
    dynamic payload;
    try {
      payload = jsonDecode(res.body);
    } catch (_) {}

    if (res.statusCode >= 400) {
      final message = payload is Map ? (payload['message'] as String?)?.trim() : null;
      final msg = (message?.isNotEmpty == true) ? message! : 'تعذر إتمام الطلب (${res.statusCode})';
      if (res.statusCode == 401) {
        await clearSession();
        onUnauthorized?.call();
      }
      throw ApiException(res.statusCode, msg);
    }
    return payload;
  }
}

