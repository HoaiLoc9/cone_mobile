class QrScanResult {
  const QrScanResult({
    required this.token,
    required this.type,
    required this.typeLabel,
    required this.expiresAt,
    required this.activityId,
    required this.activityName,
    required this.location,
    required this.timeStart,
    required this.timeStop,
    required this.points,
    required this.hasRegistered,
    required this.checkInAt,
    required this.checkOutAt,
    required this.scannedAt,
  });

  final String token;
  final int type;
  final String typeLabel;
  final DateTime? expiresAt;
  final String activityId;
  final String activityName;
  final String location;
  final DateTime? timeStart;
  final DateTime? timeStop;
  final double points;
  final bool hasRegistered;
  final DateTime? checkInAt;
  final DateTime? checkOutAt;
  final DateTime? scannedAt;

  factory QrScanResult.fromJson(Map<String, dynamic> json) {
    final activity = json['activity'] as Map<String, dynamic>? ?? {};
    return QrScanResult(
      token: json['token']?.toString() ?? '',
      type: (json['type'] as num?)?.toInt() ?? 0,
      typeLabel: json['type_label']?.toString() ?? '',
      expiresAt: _parseDate(json['expires_at']),
      activityId: activity['id']?.toString() ?? '',
      activityName: activity['name']?.toString() ?? '',
      location: activity['location']?.toString() ?? '',
      timeStart: _parseDate(activity['time_start']),
      timeStop: _parseDate(activity['time_stop']),
      points: (activity['points'] as num?)?.toDouble() ?? 0,
      hasRegistered: json['has_registered'] == true,
      checkInAt: _parseDate(json['check_in_at']),
      checkOutAt: _parseDate(json['check_out_at']),
      scannedAt: _parseDate(json['scanned_at']),
    );
  }

  static DateTime? _parseDate(Object? value) {
    final text = value?.toString();
    if (text == null || text.isEmpty) {
      return null;
    }
    return DateTime.tryParse(text)?.toLocal();
  }
}
