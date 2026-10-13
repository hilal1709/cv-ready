import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/env.dart';

/// An error with a message that is already fit to show the user.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

/// Talks to the CV Ready backend. Holds the sign-in token; nothing else on
/// the phone knows any credential for the database or the AI providers.
class ApiClient {
  ApiClient._();
  static final instance = ApiClient._();

  static const _tokenKey = 'cvready.token';
  final http.Client _http = http.Client();
  String? _token;

  /// Called when the server rejects the stored token (expired or revoked).
  void Function()? onUnauthorized;

  bool get hasToken => _token != null;

  Future<void> loadToken() async {
    try {
      _token = (await SharedPreferences.getInstance()).getString(_tokenKey);
    } catch (_) {
      _token = null;
    }
  }

  Future<void> setToken(String? token) async {
    _token = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (token == null) {
        await prefs.remove(_tokenKey);
      } else {
        await prefs.setString(_tokenKey, token);
      }
    } catch (_) {
      // The token still works for this run; the user just signs in again next launch.
    }
  }

  /// Sends a JSON request and returns the decoded JSON object (empty for 204).
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Object? body,
    Duration timeout = const Duration(seconds: 25),
  }) async {
    if (!Env.hasBackend) {
      throw ApiException('Server belum dikonfigurasi. Pasang versi app yang lengkap.');
    }
    final req = http.Request(method, Uri.parse('${Env.apiUrl}$path'))
      ..headers['accept'] = 'application/json'
      ..headers['content-type'] = 'application/json';
    final token = _token;
    if (token != null) req.headers['authorization'] = 'Bearer $token';
    if (body != null) req.body = jsonEncode(body);

    final http.Response res;
    try {
      res = await http.Response.fromStream(await _http.send(req).timeout(timeout));
    } on TimeoutException {
      throw ApiException('Server tidak merespons. Coba lagi sebentar lagi.');
    } catch (_) {
      throw ApiException('Tidak bisa terhubung ke server. Cek koneksi internet lalu coba lagi.');
    }

    Map<String, dynamic> json = const {};
    if (res.bodyBytes.isNotEmpty) {
      try {
        final v = jsonDecode(utf8.decode(res.bodyBytes));
        if (v is Map<String, dynamic>) json = v;
      } catch (_) {
        // Non-JSON body (e.g. a gateway error page); handled by the status below.
      }
    }
    if (res.statusCode >= 200 && res.statusCode < 300) return json;

    if (res.statusCode == 401 && token != null) {
      await setToken(null);
      onUnauthorized?.call();
    }
    final message = json['error'];
    throw ApiException(
      message is String && message.isNotEmpty ? message : 'Server bermasalah (${res.statusCode}). Coba lagi nanti.',
      statusCode: res.statusCode,
    );
  }
}
