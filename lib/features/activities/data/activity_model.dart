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

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
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
