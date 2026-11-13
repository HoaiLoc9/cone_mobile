import 'dart:convert';
import 'dart:typed_data';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';

class StudentServicesService {
  StudentServicesService({required String token, ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient() {
    _apiClient.setToken(token);
  }

  final ApiClient _apiClient;

  Future<List<StudentComplaint>> complaints() async {
    final data = await _apiClient.get('/mobile/complaints');
    return _items(data).map(StudentComplaint.fromJson).toList();
  }

  Future<StudentComplaint> createComplaint({
    required String title,
    required String content,
  }) async {
    final data = await _apiClient.post(
      '/mobile/complaints',
      body: {'title': title, 'content': content},
    );
    return StudentComplaint.fromJson(_object(data['data']));
  }

  Future<List<PermissionRequestItem>> permissionRequests() async {
    final data = await _apiClient.get('/mobile/permission-requests');
    return _items(data).map(PermissionRequestItem.fromJson).toList();
  }

  Future<PermissionRequestItem> createPermissionRequest({
    required String type,
    required String title,
    required String reason,
    FilePayload? evidence,
  }) async {
    final data = await _apiClient.post(
      '/mobile/permission-requests',
      body: {
        'type': type,
        'title': title,
        'reason': reason,
        if (evidence != null) 'evidence_base64': evidence.toJson(),
      },
    );
    return PermissionRequestItem.fromJson(_object(data['data']));
  }

  Future<List<StudentDocument>> documents() async {
    final data = await _apiClient.get('/mobile/documents');
    return _items(data).map(StudentDocument.fromJson).toList();
  }

  Future<StudentDocument> uploadDocument({
    required String title,
    required String type,
    required FilePayload file,
  }) async {
    final data = await _apiClient.post(
      '/mobile/documents',
      body: {'title': title, 'type': type, 'file_base64': file.toJson()},
    );
    return StudentDocument.fromJson(_object(data['data']));
  }

  Future<ProfileStatus> profileStatus() async {
    final data = await _apiClient.get('/mobile/profile-status');
    return ProfileStatus.fromJson(_object(data['data']));
  }

  Future<List<CvDocument>> cvs() async {
    final data = await _apiClient.get('/mobile/cvs');
    return _items(data).map(CvDocument.fromJson).toList();
  }

  Future<List<CvTemplate>> cvTemplates() async {
    final data = await _apiClient.get('/mobile/cvs/templates');
    return _items(data).map(CvTemplate.fromJson).toList();
  }

  Future<CvDocument> createCv({
    required String name,
    required String templateId,
  }) async {
    final data = await _apiClient.post(
      '/mobile/cvs',
      body: {'name': name, 'template_id': templateId},
    );
    return CvDocument.fromJson(_object(data['data']));
  }

  Future<CvDocument> updateCv(CvDocument cv) async {
    final data = await _apiClient.patch(
      '/mobile/cvs/${cv.id}',
      body: {'name': cv.name, 'personal': cv.personal, 'sections': cv.sections},
    );
    final payload = _object(data['data']);
    return CvDocument.fromJson(_object(payload['document'] ?? payload));
  }

  Future<CvDocument> setDefaultCv(String id) async {
    final data = await _apiClient.post('/mobile/cvs/$id/default');
    return CvDocument.fromJson(_object(data['data']));
  }

  Future<List<ActivitySuggestion>> activitySuggestions() async {
    final data = await _apiClient.get('/mobile/activity-suggestions');
    return _items(data).map(ActivitySuggestion.fromJson).toList();
  }

  Future<List<SignatureRequestItem>> signatureRequests({
    String status = '',
  }) async {
    final suffix = status.trim().isEmpty
        ? ''
        : '?status=${Uri.encodeQueryComponent(status.trim())}';
    final data = await _apiClient.get('/mobile/signature-requests$suffix');
    return _items(data).map(SignatureRequestItem.fromJson).toList();
  }

  Future<SignatureRequestItem> signatureRequest(String id) async {
    final data = await _apiClient.get('/mobile/signature-requests/$id');
    return SignatureRequestItem.fromJson(_object(data['data']));
  }

  Future<SignatureRequestItem> signSignatureRequest({
    required String id,
    required String signatureData,
    required bool acknowledgement,
  }) async {
    final data = await _apiClient.post(
      '/mobile/signature-requests/$id/sign',
      body: {
        'signature_data': signatureData,
        'acknowledgement': acknowledgement,
      },
    );
    return SignatureRequestItem.fromJson(_object(data['data']));
  }
}

class FilePayload {
  const FilePayload({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;

  Map<String, dynamic> toJson() => {
    'name': name,
    'content': base64Encode(bytes),
  };
}

class StudentComplaint {
  const StudentComplaint({
    required this.id,
    required this.title,
    required this.content,
    required this.status,
    required this.statusLabel,
    required this.response,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String content;
  final String status;
  final String statusLabel;
  final String response;
  final String createdAt;

  factory StudentComplaint.fromJson(Map<String, dynamic> json) {
    return StudentComplaint(
      id: _text(json['id']),
      title: _text(json['title']),
      content: _text(json['content']),
      status: _text(json['status']),
      statusLabel: _text(json['status_label']),
      response: _text(json['response']),
      createdAt: _text(json['created_at']),
    );
  }
}

class PermissionRequestItem {
  const PermissionRequestItem({
    required this.id,
    required this.type,
    required this.typeLabel,
    required this.title,
    required this.reason,
    required this.status,
    required this.statusLabel,
    required this.adminNote,
    required this.evidenceUrl,
  });

  final String id;
  final String type;
  final String typeLabel;
  final String title;
  final String reason;
  final String status;
  final String statusLabel;
  final String adminNote;
  final String evidenceUrl;

  factory PermissionRequestItem.fromJson(Map<String, dynamic> json) {
    return PermissionRequestItem(
      id: _text(json['id']),
      type: _text(json['type']),
      typeLabel: _text(json['type_label']),
      title: _text(json['title']),
      reason: _text(json['reason']),
      status: _text(json['status']),
      statusLabel: _text(json['status_label']),
      adminNote: _text(json['admin_note']),
      evidenceUrl: ApiConfig.storageUrl(_text(json['evidence_url'])),
    );
  }
}

class StudentDocument {
  const StudentDocument({
    required this.id,
    required this.title,
    required this.type,
    required this.status,
    required this.statusLabel,
    required this.adminNote,
    required this.fileUrl,
  });

  final String id;
  final String title;
  final String type;
  final String status;
  final String statusLabel;
  final String adminNote;
  final String fileUrl;

  factory StudentDocument.fromJson(Map<String, dynamic> json) {
    return StudentDocument(
      id: _text(json['id']),
      title: _text(json['title']),
      type: _text(json['type']),
      status: _text(json['status']),
      statusLabel: _text(json['status_label']),
      adminNote: _text(json['admin_note']),
      fileUrl: ApiConfig.storageUrl(_text(json['file_url'])),
    );
  }
}

class ProfileStatus {
  const ProfileStatus({
    required this.status,
    required this.statusLabel,
    required this.note,
  });

  final String status;
  final String statusLabel;
  final String note;

  factory ProfileStatus.fromJson(Map<String, dynamic> json) {
    return ProfileStatus(
      status: _text(json['status']),
      statusLabel: _text(json['status_label']),
      note: _text(json['note']),
    );
  }
}

class CvTemplate {
  const CvTemplate({required this.id, required this.name});

  final String id;
  final String name;

  factory CvTemplate.fromJson(Map<String, dynamic> json) {
    return CvTemplate(id: _text(json['id']), name: _text(json['name']));
  }
}

class CvDocument {
  const CvDocument({
    required this.id,
    required this.name,
    required this.templateId,
    required this.isDefault,
    required this.personal,
    required this.sections,
  });

  final String id;
  final String name;
  final String templateId;
  final bool isDefault;
  final Map<String, dynamic> personal;
  final List<dynamic> sections;

  factory CvDocument.fromJson(Map<String, dynamic> json) {
    return CvDocument(
      id: _text(json['id']),
      name: _text(json['name']).isEmpty ? 'CV sinh viên' : _text(json['name']),
      templateId: _text(json['template_id']),
      isDefault: json['is_default'] == true || json['is_default'] == 1,
      personal: _object(json['personal']),
      sections: json['sections'] is List
          ? json['sections'] as List<dynamic>
          : const [],
    );
  }

  CvDocument copyWith({
    String? name,
    Map<String, dynamic>? personal,
    List<dynamic>? sections,
  }) {
    return CvDocument(
      id: id,
      name: name ?? this.name,
      templateId: templateId,
      isDefault: isDefault,
      personal: personal ?? this.personal,
      sections: sections ?? this.sections,
    );
  }
}

class ActivitySuggestion {
  const ActivitySuggestion({
    required this.id,
    required this.name,
    required this.score,
    required this.reasons,
  });

  final String id;
  final String name;
  final num score;
  final List<String> reasons;

  factory ActivitySuggestion.fromJson(Map<String, dynamic> json) {
    return ActivitySuggestion(
      id: _text(json['id']),
      name: _text(json['name']),
      score: json['score'] is num ? json['score'] as num : 0,
      reasons: (json['reasons'] is List ? json['reasons'] as List : const [])
          .map((item) => _text(item))
          .where((item) => item.isNotEmpty)
          .toList(),
    );
  }
}

class SignatureRequestItem {
  const SignatureRequestItem({
    required this.id,
    required this.title,
    required this.description,
    required this.acknowledgementText,
    required this.status,
    required this.statusLabel,
    required this.mayBeSigned,
    required this.requestedByName,
    required this.requestedAt,
    required this.expiresAt,
    required this.signedAt,
    required this.hasDocument,
    required this.hasSignature,
    required this.documentOriginalName,
    required this.documentUrl,
    required this.signatureUrl,
  });

  final String id;
  final String title;
  final String description;
  final String acknowledgementText;
  final String status;
  final String statusLabel;
  final bool mayBeSigned;
  final String requestedByName;
  final String requestedAt;
  final String expiresAt;
  final String signedAt;
  final bool hasDocument;
  final bool hasSignature;
  final String documentOriginalName;
  final String documentUrl;
  final String signatureUrl;

  factory SignatureRequestItem.fromJson(Map<String, dynamic> json) {
    return SignatureRequestItem(
      id: _text(json['id']),
      title: _text(json['title']),
      description: _text(json['description']),
      acknowledgementText: _text(json['acknowledgement_text']),
      status: _text(json['status']),
      statusLabel: _text(json['status_label']),
      mayBeSigned: json['may_be_signed'] == true,
      requestedByName: _text(json['requested_by_name']),
      requestedAt: _text(json['requested_at']),
      expiresAt: _text(json['expires_at']),
      signedAt: _text(json['signed_at']),
      hasDocument: json['has_document'] == true,
      hasSignature: json['has_signature'] == true,
      documentOriginalName: _text(json['document_original_name']),
      documentUrl: ApiConfig.storageUrl(_text(json['document_url'])),
      signatureUrl: ApiConfig.storageUrl(_text(json['signature_url'])),
    );
  }
}

List<Map<String, dynamic>> _items(Map<String, dynamic> response) {
  final data = response['data'];
  if (data is List) {
    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
  if (data is Map && data['data'] is List) {
    return (data['data'] as List)
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
  return const [];
}

Map<String, dynamic> _object(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

String _text(Object? value) => value?.toString() ?? '';
