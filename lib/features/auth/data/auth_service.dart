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

  Future<AuthSession> login({
    required String identifier,
    required String password,
  }) async {
    final data = await _apiClient.post(
      '/mobile/login',
      body: {'identifier': identifier, 'password': password},
    );

    if (data['success'] != true) {
      throw ApiException(data['message']?.toString() ?? 'Đăng nhập thất bại.');
    }

    final token = data['token']?.toString() ?? '';
    if (token.isEmpty) {
      throw const ApiException('API không trả về token đăng nhập.');
    }

    _apiClient.setToken(token);

    return AuthSession(
      token: token,
      user: StudentUser.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  Future<StudentUser> me() async {
    final data = await _apiClient.get('/mobile/me');
    return StudentUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    try {
      await _apiClient.post('/mobile/logout');
    } finally {
      _apiClient.clearToken();
    }
  }
}
