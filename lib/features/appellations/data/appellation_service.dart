import 'dart:convert';
import 'dart:typed_data';

import '../../../core/network/api_client.dart';
import 'appellation_models.dart';

class AppellationService {
  AppellationService({required String token, ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient() {
    _apiClient.setToken(token);
  }

  final ApiClient _apiClient;

  Future<AppellationList> fetchAppellations({String? keyword}) async {
    final path = Uri(
      path: '/mobile/appellations',
      queryParameters: {
        if (keyword != null && keyword.trim().isNotEmpty) 'keyword': keyword.trim(),
      },
    ).toString();
    final data = await _apiClient.get(path);
    return AppellationList.fromJson(data);
  }

  Future<AppellationDetail> fetchDetail(String id) async {
    final data = await _apiClient.get('/mobile/appellations/$id');
    return AppellationDetail.fromJson(data);
  }

  Future<AppellationRegistration> register({
    required String appellationId,
    required AppellationSubmitPayload payload,
  }) async {
    final data = await _apiClient.post(
      '/mobile/appellations/$appellationId/register',
      body: payload.toJson(),
    );
    return AppellationRegistration.fromJson(
      (data['data'] as Map<String, dynamic>? ?? {})['registration'] as Map<String, dynamic>? ?? {},
    );
  }

  Future<AppellationRegistration> updateRegistration({
    required String registrationId,
    required AppellationSubmitPayload payload,
  }) async {
    final data = await _apiClient.post(
      '/mobile/appellation-registrations/$registrationId',
      body: payload.toJson(),
    );
    return AppellationRegistration.fromJson(
      (data['data'] as Map<String, dynamic>? ?? {})['registration'] as Map<String, dynamic>? ?? {},
    );
  }
}

class AppellationSubmitPayload {
  const AppellationSubmitPayload({
    required this.form,
    required this.formFiles,
    required this.removeFormFiles,
    required this.legacyFiles,
  });

  final Map<String, String> form;
  final Map<String, List<AppellationUpload>> formFiles;
  final Map<String, List<String>> removeFormFiles;
  final Map<String, AppellationUpload> legacyFiles;

  Map<String, dynamic> toJson() {
    return {
      'form': form,
      'remove_form_files': removeFormFiles,
      'form_files_base64': formFiles.map(
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
      'legacy_files': legacyFiles.map(
        (key, file) => MapEntry(
          key,
          {
            'name': file.name,
            'content': base64Encode(file.bytes),
          },
        ),
      ),
    };
  }
}

class AppellationUpload {
  const AppellationUpload({
    required this.name,
    required this.bytes,
  });

  final String name;
  final Uint8List bytes;
}
