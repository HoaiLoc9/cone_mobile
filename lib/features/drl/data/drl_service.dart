import 'dart:convert';
import 'dart:typed_data';

import '../../../core/network/api_client.dart';
import 'drl_models.dart';

class DrlService {
  DrlService({required String token, ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient() {
    _apiClient.setToken(token);
  }

  final ApiClient _apiClient;

  Future<DrlSummary> fetchSummary({String? semesterId}) async {
    final path = Uri(
      path: '/mobile/drl/summary',
      queryParameters: {
        if (semesterId != null && semesterId.isNotEmpty) 'semester_id': semesterId,
      },
    ).toString();
    final data = await _apiClient.get(path);
    return DrlSummary.fromJson(data);
  }

  Future<DrlDetail> fetchDetail(String semesterId) async {
    final data = await _apiClient.get('/mobile/drl/semesters/$semesterId');
    return DrlDetail.fromJson(data);
  }

  Future<DrlSelfAssessmentForm> fetchSelfAssessment(String semesterId) async {
    final data = await _apiClient.get('/mobile/drl/semesters/$semesterId/self-assessment');
    return DrlSelfAssessmentForm.fromJson(data);
  }

  Future<DrlSelfAssessmentForm> saveSelfAssessment({
    required String semesterId,
    required Map<String, String> scores,
    required Map<String, List<String>> removeEvidence,
    required Map<String, List<DrlEvidenceUpload>> uploads,
  }) async {
    final data = await _apiClient.post(
      '/mobile/drl/semesters/$semesterId/self-assessment',
      body: {
        'scores': scores,
        'remove_evidence': removeEvidence,
        'evidence_base64': uploads.map(
          (key, files) => MapEntry(
            key,
            files
                .map(
                  (file) => {
                    'name': file.name,
                    'content': base64Encode(file.bytes),
                  },
                )
                .toList(),
          ),
        ),
      },
    );

    return DrlSelfAssessmentForm.fromJson(data);
  }
}

class DrlEvidenceUpload {
  const DrlEvidenceUpload({
    required this.name,
    required this.bytes,
  });

  final String name;
  final Uint8List bytes;
}
