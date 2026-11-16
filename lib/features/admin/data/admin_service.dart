import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'admin_models.dart';

class AdminService {
  AdminService({String? token, ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient() {
    if (token != null && token.isNotEmpty) {
      _apiClient.setToken(token);
    }
  }

  final ApiClient _apiClient;

  Future<AdminSession> login({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim();
    final data = await _apiClient.post(
      '/mobile/admin/login',
      body: {
        'email': cleanEmail,
        'username': cleanEmail,
        'identifier': cleanEmail,
        'password': password,
      },
    );

    if (data['success'] != true && data['token'] == null) {
      throw ApiException(
        data['message']?.toString() ?? 'Đăng nhập quản trị thất bại.',
      );
    }

    final token = data['token']?.toString() ??
        (data['data'] is Map<String, dynamic>
            ? data['data']['token']?.toString()
            : null) ??
        '';
    if (token.isEmpty) {
      throw const ApiException('API không trả về token quản trị.');
    }

    _apiClient.setToken(token);

    final rawAdmin = data['admin'] ??
        (data['data'] is Map<String, dynamic> ? data['data']['admin'] : null) ??
        data['user'] ??
        (data['data'] is Map<String, dynamic> ? data['data']['user'] : null);
    if (rawAdmin is! Map<String, dynamic>) {
      throw const ApiException('Dữ liệu quản trị viên không hợp lệ.');
    }

    return AdminSession(
      token: token,
      admin: AdminUser.fromJson(rawAdmin),
    );
  }

  Future<void> logout() async {
    try {
      await _apiClient.post('/mobile/admin/logout');
    } finally {
      _apiClient.clearToken();
    }
  }

  Future<void> requestPasswordOtp(String email) async {
    await _apiClient.post(
      '/mobile/admin/password/request-otp',
      body: {'email': email},
    );
  }

  Future<void> verifyPasswordOtp({
    required String email,
    required String otp,
  }) async {
    await _apiClient.post(
      '/mobile/admin/password/verify-otp',
      body: {'email': email, 'otp': otp},
    );
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String password,
    required String passwordConfirmation,
  }) async {
    await _apiClient.post(
      '/mobile/admin/password/reset',
      body: {
        'email': email,
        'otp': otp,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
  }

  Future<AdminDashboard> dashboard() async {
    final data = await _apiClient.get('/mobile/admin/dashboard');
    return AdminDashboard.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<List<AdminStudent>> students({String keyword = ''}) async {
    final suffix = keyword.trim().isEmpty
        ? ''
        : '?keyword=${Uri.encodeQueryComponent(keyword.trim())}';
    final data = await _apiClient.get('/mobile/admin/students$suffix');
    final items =
        ((data['data'] as Map<String, dynamic>)['items'] as List? ?? const []);
    return items
        .whereType<Map<String, dynamic>>()
        .map(AdminStudent.fromJson)
        .toList();
  }

  Future<List<AdminActivity>> activities({String keyword = ''}) async {
    final suffix = keyword.trim().isEmpty
        ? ''
        : '?keyword=${Uri.encodeQueryComponent(keyword.trim())}';
    final data = await _apiClient.get('/mobile/admin/activities$suffix');
    final items =
        ((data['data'] as Map<String, dynamic>)['items'] as List? ?? const []);
    return items
        .whereType<Map<String, dynamic>>()
        .map(AdminActivity.fromJson)
        .toList();
  }

  Future<List<AdminAppellationRegistration>> appellationRegistrations() async {
    final data = await _apiClient.get(
      '/mobile/admin/appellation-registrations',
    );
    final items =
        ((data['data'] as Map<String, dynamic>)['items'] as List? ?? const []);
    return items
        .whereType<Map<String, dynamic>>()
        .map(AdminAppellationRegistration.fromJson)
        .toList();
  }

  Future<List<AdminDrlAssessment>> drlAssessments() async {
    final data = await _apiClient.get('/mobile/admin/drl-assessments');
    final items =
        ((data['data'] as Map<String, dynamic>)['items'] as List? ?? const []);
    return items
        .whereType<Map<String, dynamic>>()
        .map(AdminDrlAssessment.fromJson)
        .toList();
  }

  Future<AdminDashboard> gvcnDashboard() async {
    final data = await _apiClient.get('/mobile/admin/gvcn/dashboard');
    return AdminDashboard.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<List<AdminDrlAssessment>> gvcnDrlAssessments({
    String status = '',
  }) async {
    final suffix = status.isEmpty ? '' : '?status=$status';
    final data = await _apiClient.get(
      '/mobile/admin/gvcn/drl-assessments$suffix',
    );
    final items =
        ((data['data'] as Map<String, dynamic>)['items'] as List? ?? const []);
    return items
        .whereType<Map<String, dynamic>>()
        .map(AdminDrlAssessment.fromJson)
        .toList();
  }

  Future<GvcnDrlDetail> gvcnDrlDetail(String id) async {
    final data = await _apiClient.get('/mobile/admin/gvcn/drl-assessments/$id');
    return GvcnDrlDetail.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<GvcnDrlDetail> saveGvcnDrl(
    String id, {
    required Map<String, double?> classScores,
    required Map<String, String> adminNotes,
    required String gvcnXepLoai,
  }) async {
    final data = await _apiClient.post(
      '/mobile/admin/gvcn/drl-assessments/$id/scores',
      body: {
        'class_scores': classScores,
        'admin_notes': adminNotes,
        'gvcn_xep_loai': gvcnXepLoai,
      },
    );
    return GvcnDrlDetail.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<AdminDrlAssessment> approveDrl(String id) async {
    final data = await _apiClient.post(
      '/mobile/admin/drl-assessments/$id/approve',
    );
    final item =
        ((data['data'] as Map<String, dynamic>)['item']
            as Map<String, dynamic>);
    return AdminDrlAssessment.fromJson(item);
  }

  Future<AdminDrlAssessment> disapproveDrl(String id) async {
    final data = await _apiClient.post(
      '/mobile/admin/drl-assessments/$id/disapprove',
    );
    final item =
        ((data['data'] as Map<String, dynamic>)['item']
            as Map<String, dynamic>);
    return AdminDrlAssessment.fromJson(item);
  }

  Future<List<AdminBusinessItem>> businessItems(String path) async {
    final data = await _apiClient.get(path);
    final payload = data['data'] as Map<String, dynamic>? ?? {};
    final items = payload['items'] as List? ?? const [];
    return items
        .whereType<Map>()
        .map(
          (item) => AdminBusinessItem.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<void> resolveComplaint({
    required String id,
    required String status,
    required String response,
  }) async {
    await _apiClient.post(
      '/mobile/admin/complaints/$id/resolve',
      body: {'status': status, 'response': response},
    );
  }

  Future<void> approvePermission(String id, {String note = ''}) async {
    await _apiClient.post(
      '/mobile/admin/permission-requests/$id/approve',
      body: {'admin_note': note},
    );
  }

  Future<void> rejectPermission(String id, {String note = ''}) async {
    await _apiClient.post(
      '/mobile/admin/permission-requests/$id/reject',
      body: {'admin_note': note},
    );
  }

  Future<void> approveDocument(String id, {String note = ''}) async {
    await _apiClient.post(
      '/mobile/admin/documents/$id/approve',
      body: {'admin_note': note},
    );
  }

  Future<void> rejectDocument(String id, {String note = ''}) async {
    await _apiClient.post(
      '/mobile/admin/documents/$id/reject',
      body: {'admin_note': note},
    );
  }

  Future<void> updateProfileStatus({
    required String userId,
    required String status,
    required String note,
  }) async {
    await _apiClient.post(
      '/mobile/admin/profile-statuses/$userId',
      body: {'status': status, 'note': note},
    );
  }

  Future<void> sendNotification({
    required String title,
    required String message,
  }) async {
    await _apiClient.post(
      '/mobile/admin/notifications',
      body: {
        'title': title,
        'message': message,
        'channels': ['app'],
        'target_type': 'all',
      },
    );
  }

  Future<void> createBackup() async {
    await _apiClient.post('/mobile/admin/backups');
  }

  Future<void> gvcnApprovePermission(String id, {String note = ''}) async {
    await _apiClient.post(
      '/mobile/admin/gvcn/permission-requests/$id/approve',
      body: {'admin_note': note},
    );
  }

  Future<void> gvcnRejectPermission(String id, {String note = ''}) async {
    await _apiClient.post(
      '/mobile/admin/gvcn/permission-requests/$id/reject',
      body: {'admin_note': note},
    );
  }
}

class AdminBusinessItem {
  const AdminBusinessItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.note,
    required this.studentName,
    required this.studentCode,
    required this.studentId,
    required this.createdAt,
    required this.raw,
  });

  final String id;
  final String title;
  final String subtitle;
  final String status;
  final String note;
  final String studentName;
  final String studentCode;
  final String studentId;
  final String createdAt;
  final Map<String, dynamic> raw;

  factory AdminBusinessItem.fromJson(Map<String, dynamic> json) {
    final student = json['student'] is Map
        ? Map<String, dynamic>.from(json['student'] as Map)
        : <String, dynamic>{};
    return AdminBusinessItem(
      id: _text(json['id']),
      title: _firstText(json, const ['title', 'filename', 'name', 'module']),
      subtitle: _firstText(json, const [
        'content',
        'reason',
        'message',
        'description',
        'type_label',
        'action',
      ]),
      status: _firstText(json, const ['status_label', 'status', 'type']),
      note: _firstText(json, const [
        'admin_note',
        'response',
        'error_message',
        'actor_name',
      ]),
      studentName: _text(student['name']),
      studentCode: _text(student['code']),
      studentId: _text(student['id']),
      createdAt: _text(json['created_at']),
      raw: json,
    );
  }
}

String _firstText(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = _text(json[key]);
    if (value.isNotEmpty) return value;
  }
  return '';
}

String _text(Object? value) => value?.toString() ?? '';
