import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'student_user.dart';

class AuthSession {
  const AuthSession({required this.token, required this.user});

  final String token;
  final StudentUser user;
}

class AuthService {
  AuthService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  static const _tokenKey = 'cone_auth_token';
  static const _userKey = 'cone_auth_user';

  Future<void> saveSession(AuthSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, session.token);
    await prefs.setString(_userKey, jsonEncode(session.user.toJson()));
  }

  Future<AuthSession?> getSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final userRaw = prefs.getString(_userKey);
    if (token == null || token.isEmpty || userRaw == null || userRaw.isEmpty) {
      return null;
    }
    try {
      final userJson = jsonDecode(userRaw) as Map<String, dynamic>;
      final user = StudentUser.fromJson(userJson);
      _apiClient.setToken(token);
      return AuthSession(token: token, user: user);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  Future<AuthSession> login({
    required String identifier,
    required String password,
  }) async {
    final cleanId = identifier.trim();
    final data = await _apiClient.post(
      '/mobile/login',
      body: {
        'identifier': cleanId,
        'code': cleanId,
        'email': cleanId,
        'password': password,
      },
    );

    if (data['success'] != true && data['token'] == null) {
      throw ApiException(data['message']?.toString() ?? 'Đăng nhập thất bại.');
    }

    final token = data['token']?.toString() ??
        (data['data'] is Map<String, dynamic>
            ? data['data']['token']?.toString()
            : null) ??
        '';
    if (token.isEmpty) {
      throw const ApiException('API không trả về token đăng nhập.');
    }

    _apiClient.setToken(token);

    final rawUser = data['user'] ??
        (data['data'] is Map<String, dynamic> ? data['data']['user'] : null);
    if (rawUser is! Map<String, dynamic>) {
      throw const ApiException('Dữ liệu tài khoản trả về không hợp lệ.');
    }

    final session = AuthSession(
      token: token,
      user: StudentUser.fromJson(rawUser),
    );

    await saveSession(session);

    return session;
  }

  Future<StudentUser> me() async {
    final data = await _apiClient.get('/mobile/me');
    return StudentUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    try {
      await _apiClient.post('/mobile/logout');
    } finally {
      await clearSavedSession();
      _apiClient.clearToken();
    }
  }
}
