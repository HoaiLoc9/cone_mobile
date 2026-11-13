import 'dart:convert';

import '../config/api_config.dart';
import 'api_exception.dart';
import 'api_transport.dart';

class ApiClient {
  ApiClient({ApiTransport? transport})
    : _transport = transport ?? createApiTransport();

  final ApiTransport _transport;
  String? _token;

  void setToken(String token) => _token = token;

  void clearToken() => _token = null;

  Future<Map<String, dynamic>> get(String path) {
    return _send('GET', path);
  }

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body}) {
    return _send('POST', path, body: body);
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
  }) {
    return _send('PATCH', path, body: body);
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? body,
  }) {
    return _send('DELETE', path, body: body);
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${_normalizePath(path)}');
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }

    final response = await _transport.request(
      method,
      uri,
      headers: headers,
      body: body == null ? null : jsonEncode(body),
    );

    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        decoded['message']?.toString() ?? 'Không thể kết nối hệ thống.',
        statusCode: response.statusCode,
      );
    }

    return decoded;
  }

  String _normalizePath(String path) {
    final value = path.trim().isEmpty ? '/' : path.trim();
    final withSlash = value.startsWith('/') ? value : '/$value';
    if (withSlash == '/mobile') {
      return '';
    }
    if (withSlash.startsWith('/mobile/')) {
      return withSlash.substring('/mobile'.length);
    }
    return withSlash;
  }
}
