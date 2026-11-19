class ActivityItem {
  const ActivityItem({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.semester,
    required this.department,
    required this.timeStart,
    required this.timeStop,
    required this.registrationStart,
    required this.registrationEnd,
    required this.points,
    required this.maxRegistrations,
    required this.registeredCount,
    required this.remainingSlots,
    required this.status,
    required this.statusLabel,
    required this.registrationStatus,
    required this.registrationStatusLabel,
    required this.isRegistered,
    required this.canRegister,
    required this.canCancel,
    this.collaborator = const CollaboratorRoleInfo(),
  });

  final String id;
  final String name;
  final String description;
  final String location;
  final String semester;
  final String department;
  final DateTime? timeStart;
  final DateTime? timeStop;
  final DateTime? registrationStart;
  final DateTime? registrationEnd;
  final double points;
  final int maxRegistrations;
  final int registeredCount;
  final int? remainingSlots;
  final String status;
  final String statusLabel;
  final String? registrationStatus;
  final String registrationStatusLabel;
  final bool isRegistered;
  final bool canRegister;
  final bool canCancel;
  final CollaboratorRoleInfo collaborator;

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    final collabRaw = json['collaborator'];
    return ActivityItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      semester: json['semester']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
      timeStart: _parseDate(json['time_start']),
      timeStop: _parseDate(json['time_stop']),
      registrationStart: _parseDate(json['registration_start']),
      registrationEnd: _parseDate(json['registration_end']),
      points: (json['points'] as num?)?.toDouble() ?? 0,
      maxRegistrations: (json['max_registrations'] as num?)?.toInt() ?? 0,
      registeredCount: (json['registered_count'] as num?)?.toInt() ?? 0,
      remainingSlots: (json['remaining_slots'] as num?)?.toInt(),
      status: json['status']?.toString() ?? '',
      statusLabel: json['status_label']?.toString() ?? '',
      registrationStatus: json['registration_status']?.toString(),
      registrationStatusLabel: json['registration_status_label']?.toString() ?? '',
      isRegistered: json['is_registered'] == true,
      canRegister: json['can_register'] == true,
      canCancel: json['can_cancel'] == true,
      collaborator: collabRaw is Map<String, dynamic>
          ? CollaboratorRoleInfo.fromJson(collabRaw)
          : const CollaboratorRoleInfo(),
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

class ActivityPage {
  const ActivityPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<ActivityItem> items;
  final int currentPage;
  final int lastPage;
  final int total;

  factory ActivityPage.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    final rawItems = json['data'] as List<dynamic>? ?? [];
    return ActivityPage(
      items: rawItems
          .map((item) => ActivityItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      currentPage: (meta['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (meta['last_page'] as num?)?.toInt() ?? 1,
      total: (meta['total'] as num?)?.toInt() ?? rawItems.length,
    );
  }
}

class CollaboratorRoleInfo {
  const CollaboratorRoleInfo({
    this.isCollaborator = false,
    this.isActive = false,
    this.isExpired = false,
    this.roleLabel = '',
    this.permissions = const [],
    this.expiresAtLabel = '',
  });

  final bool isCollaborator;
  final bool isActive;
  final bool isExpired;
  final String roleLabel;
  final List<String> permissions;
  final String expiresAtLabel;

  bool get canDisplayQr => isActive && permissions.contains('display_qr');
  bool get canManualCheckIn => isActive && permissions.contains('manual_checkin');
  bool get canViewAttendees => isActive && permissions.contains('view_attendees');

  factory CollaboratorRoleInfo.fromJson(Map<String, dynamic> json) {
    final permsRaw = json['permissions'];
    return CollaboratorRoleInfo(
      isCollaborator: json['is_collaborator'] == true,
      isActive: json['is_active'] == true,
      isExpired: json['is_expired'] == true,
      roleLabel: json['role_label']?.toString() ?? 'CTV Hỗ trợ Sự kiện',
      permissions: permsRaw is List
          ? permsRaw.map((e) => e.toString()).toList()
          : const [],
      expiresAtLabel: json['expires_at_label']?.toString() ?? '',
    );
  }
}

class CollaboratorOverviewData {
  const CollaboratorOverviewData({
    required this.registeredCount,
    required this.checkInCount,
    required this.checkOutCount,
    required this.qrVaoToken,
    required this.qrVaoUrl,
    required this.qrRaToken,
    required this.qrRaUrl,
    required this.attendees,
  });

  final int registeredCount;
  final int checkInCount;
  final int checkOutCount;
  final String qrVaoToken;
  final String qrVaoUrl;
  final String qrRaToken;
  final String qrRaUrl;
  final List<Map<String, dynamic>> attendees;

  factory CollaboratorOverviewData.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] is Map<String, dynamic>
        ? json['stats'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final qrVao = json['qr_vao'] is Map<String, dynamic>
        ? json['qr_vao'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final qrRa = json['qr_ra'] is Map<String, dynamic>
        ? json['qr_ra'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final rawAttendees = json['attendees'];

    return CollaboratorOverviewData(
      registeredCount: (stats['registered_count'] as num?)?.toInt() ?? 0,
      checkInCount: (stats['checkin_count'] as num?)?.toInt() ?? 0,
      checkOutCount: (stats['checkout_count'] as num?)?.toInt() ?? 0,
      qrVaoToken: qrVao['token']?.toString() ?? '',
      qrVaoUrl: qrVao['scan_url']?.toString() ?? '',
      qrRaToken: qrRa['token']?.toString() ?? '',
      qrRaUrl: qrRa['scan_url']?.toString() ?? '',
      attendees: rawAttendees is List
          ? rawAttendees
              .whereType<Map>()
              .map((m) => Map<String, dynamic>.from(m))
              .toList()
          : const [],
    );
  }
}
