import '../../../core/network/api_client.dart';
import 'activity_support_models.dart';

class ActivitySupportService {
  ActivitySupportService({required String token, ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient() {
    _apiClient.setToken(token);
  }

  final ApiClient _apiClient;

  Future<MissingAttendanceData> fetchMissingAttendance() async {
    final data = await _apiClient.get(
      '/mobile/activity-support/missing-attendance',
    );
    return MissingAttendanceData.fromJson(data);
  }

  Future<MissingAttendanceRequest> submitMissingAttendance({
    required String activityId,
    required String reason,
    SupportUpload? evidence,
  }) async {
    final data = await _apiClient.post(
      '/mobile/activity-support/missing-attendance',
      body: {
        'activity_id': activityId,
        'reason': reason,
        if (evidence != null) 'evidence_base64': evidence.toJson(),
      },
    );
    final request =
        (data['data'] as Map<String, dynamic>? ?? {})['request']
            as Map<String, dynamic>? ??
        {};
    return MissingAttendanceRequest.fromJson(request);
  }

  Future<ActivityCertificate> fetchCertificate(String activityId) async {
    final data = await _apiClient.get(
      '/mobile/activities/$activityId/certificate',
    );
    return ActivityCertificate.fromJson(data);
  }
}
