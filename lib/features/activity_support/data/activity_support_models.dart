import 'dart:convert';
import 'dart:typed_data';

class MissingAttendanceData {
  const MissingAttendanceData({required this.eligible, required this.requests});

  final List<MissingAttendanceEligible> eligible;
  final List<MissingAttendanceRequest> requests;

  factory MissingAttendanceData.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return MissingAttendanceData(
      eligible: (data['eligible'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(MissingAttendanceEligible.fromJson)
          .toList(),
      requests: (data['requests'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(MissingAttendanceRequest.fromJson)
          .toList(),
    );
  }
}

class MissingAttendanceEligible {
  const MissingAttendanceEligible({
    required this.id,
    required this.name,
    required this.location,
    required this.timeStart,
    required this.timeStop,
    required this.missingType,
    required this.missingTypeLabel,
  });

  final String id;
  final String name;
  final String location;
  final DateTime? timeStart;
  final DateTime? timeStop;
  final String missingType;
  final String missingTypeLabel;

  factory MissingAttendanceEligible.fromJson(Map<String, dynamic> json) {
    return MissingAttendanceEligible(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      timeStart: _parseDate(json['time_start']),
      timeStop: _parseDate(json['time_stop']),
      missingType: json['missing_type']?.toString() ?? '',
      missingTypeLabel: json['missing_type_label']?.toString() ?? '',
    );
  }
}

class MissingAttendanceRequest {
  const MissingAttendanceRequest({
    required this.id,
    required this.activityId,
    required this.activityName,
    required this.missingTypeLabel,
    required this.reason,
    required this.status,
    required this.statusLabel,
    required this.evidenceName,
    required this.createdAt,
  });

  final String id;
  final String activityId;
  final String activityName;
  final String missingTypeLabel;
  final String reason;
  final String status;
  final String statusLabel;
  final String evidenceName;
  final DateTime? createdAt;

  factory MissingAttendanceRequest.fromJson(Map<String, dynamic> json) {
    return MissingAttendanceRequest(
      id: json['id']?.toString() ?? '',
      activityId: json['activity_id']?.toString() ?? '',
      activityName: json['activity_name']?.toString() ?? '',
      missingTypeLabel: json['missing_type_label']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      statusLabel: json['status_label']?.toString() ?? '',
      evidenceName: json['evidence_name']?.toString() ?? '',
      createdAt: _parseDate(json['created_at']),
    );
  }
}

class SupportUpload {
  const SupportUpload({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;

  Map<String, dynamic> toJson() => {
    'name': name,
    'content': base64Encode(bytes),
  };
}

class ActivityCertificate {
  const ActivityCertificate({
    required this.fileName,
    required this.mimeType,
    required this.bytes,
  });

  final String fileName;
  final String mimeType;
  final Uint8List bytes;

  factory ActivityCertificate.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return ActivityCertificate(
      fileName: data['file_name']?.toString() ?? 'giay-chung-nhan.jpg',
      mimeType: data['mime_type']?.toString() ?? 'image/jpeg',
      bytes: base64Decode(data['base64']?.toString() ?? ''),
    );
  }
}

DateTime? _parseDate(Object? value) {
  final text = value?.toString();
  if (text == null || text.isEmpty) {
    return null;
  }
  return DateTime.tryParse(text)?.toLocal();
}
