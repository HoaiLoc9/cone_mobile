import 'dart:convert';

import '../config/api_config.dart';
import '../storage/app_storage.dart';
import 'api_exception.dart';
import 'api_response.dart';
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

    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }

    final cacheKey = 'cone_offline_cache_${_normalizePath(path)}';

    ApiResponse response;
    try {
      response = await _transport.request(
        method,
        uri,
        headers: headers,
        body: body == null ? null : jsonEncode(body),
      );
    } catch (error) {
      // Khi mất mạng hoặc host offline/nghỉ ngơi: Thử lấy dữ liệu từ Offline Cache đối với yêu cầu GET
      if (method == 'GET') {
        final cached = await AppStorage.instance.getString(cacheKey);
        if (cached != null && cached.isNotEmpty) {
          try {
            final parsed = jsonDecode(cached);
            if (parsed is Map<String, dynamic>) {
              return parsed;
            }
          } catch (_) {}
        }
      }
      if (error is ApiException) rethrow;
      throw ApiException(
        'Không thể gửi yêu cầu đến máy chủ: $error',
      );
    }

    Map<String, dynamic> decoded = {};
    if (response.body.isNotEmpty) {
      try {
        final parsed = jsonDecode(response.body);
        if (parsed is Map<String, dynamic>) {
          decoded = parsed;
        }
      } catch (_) {
        // Not a JSON object (e.g. HTML response or empty)
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (method == 'GET') {
        final cached = await AppStorage.instance.getString(cacheKey);
        if (cached != null && cached.isNotEmpty) {
          try {
            final parsed = jsonDecode(cached);
            if (parsed is Map<String, dynamic>) {
              return parsed;
            }
          } catch (_) {}
        }
      }
      String? message = decoded['message']?.toString();
      if (message == null || message.isEmpty) {
        if (decoded['error'] != null) {
          message = decoded['error'].toString();
        } else if (response.statusCode == 401) {
          message = 'Thông tin đăng nhập không chính xác hoặc phiên đã hết hạn.';
        } else if (response.statusCode == 403) {
          message = 'Bạn không có quyền truy cập chức năng này.';
        } else if (response.statusCode == 404) {
          message = 'Không tìm thấy chức năng này trên máy chủ (404).';
        } else if (response.statusCode == 422) {
          final errors = decoded['errors'];
          if (errors is Map && errors.isNotEmpty) {
            final firstErrList = errors.values.first;
            if (firstErrList is List && firstErrList.isNotEmpty) {
              message = firstErrList.first.toString();
            }
          }
          message ??= 'Dữ liệu gửi lên không hợp lệ.';
        } else if (response.statusCode >= 500) {
          message = 'Máy chủ đang gặp sự cố nội bộ (${response.statusCode}).';
        } else {
          message = 'Yêu cầu không thành công (${response.statusCode}).';
        }
      }

      throw ApiException(
        message,
        statusCode: response.statusCode,
      );
    }

    if (method == 'GET' && response.body.isNotEmpty) {
      AppStorage.instance.setString(cacheKey, response.body).catchError((_) {});
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
