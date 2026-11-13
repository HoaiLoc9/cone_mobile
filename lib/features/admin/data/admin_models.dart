class AdminSession {
  const AdminSession({required this.token, required this.admin});

  final String token;
  final AdminUser admin;
}

class AdminUser {
  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.level,
    required this.roleCode,
    required this.roleName,
    required this.rules,
    required this.classId,
    required this.departmentId,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final int level;
  final String roleCode;
  final String roleName;
  final List<String> rules;
  final String classId;
  final String departmentId;

  bool get isGvcn => roleCode == 'gvcn' || level == 2;

  bool get isCtsv => roleCode == 'ctsv' || level == 1;

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      level: int.tryParse(json['level']?.toString() ?? '') ?? 1,
      roleCode: json['role_code']?.toString() ?? '',
      roleName: json['role_name']?.toString() ?? 'Quản trị',
      rules: (json['rules'] as List? ?? const [])
          .map((item) => item.toString())
          .toList(),
      classId: json['class_id']?.toString() ?? '',
      departmentId: json['department_id']?.toString() ?? '',
    );
  }
}

class AdminDashboard {
  const AdminDashboard({
    required this.totalStudents,
    required this.totalActivities,
    required this.pendingAppellations,
    required this.pendingDrlAssessments,
    this.approvedDrlAssessments = 0,
  });

  final int totalStudents;
  final int totalActivities;
  final int pendingAppellations;
  final int pendingDrlAssessments;
  final int approvedDrlAssessments;

  factory AdminDashboard.fromJson(Map<String, dynamic> json) {
    return AdminDashboard(
      totalStudents:
          int.tryParse(json['total_students']?.toString() ?? '') ?? 0,
      totalActivities:
          int.tryParse(json['total_activities']?.toString() ?? '') ?? 0,
      pendingAppellations:
          int.tryParse(json['pending_appellations']?.toString() ?? '') ?? 0,
      pendingDrlAssessments:
          int.tryParse(json['pending_drl_assessments']?.toString() ?? '') ?? 0,
      approvedDrlAssessments:
          int.tryParse(json['approved_drl_assessments']?.toString() ?? '') ?? 0,
    );
  }
}

class AdminAppellationRegistration {
  const AdminAppellationRegistration({
    required this.id,
    required this.studentCode,
    required this.studentName,
    required this.appellationName,
    required this.statusLabel,
    required this.createdAt,
  });

  final String id;
  final String studentCode;
  final String studentName;
  final String appellationName;
  final String statusLabel;
  final String createdAt;

  factory AdminAppellationRegistration.fromJson(Map<String, dynamic> json) {
    return AdminAppellationRegistration(
      id: json['id']?.toString() ?? '',
      studentCode: json['student_code']?.toString() ?? '',
      studentName: json['student_name']?.toString() ?? '',
      appellationName: json['appellation_name']?.toString() ?? '',
      statusLabel: json['status_label']?.toString() ?? 'Chờ xử lý',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

class AdminDrlAssessment {
  const AdminDrlAssessment({
    required this.id,
    required this.studentCode,
    required this.studentName,
    required this.semesterName,
    required this.studentTotal,
    required this.classTotal,
    required this.advisorTotal,
    required this.approvedAt,
    required this.updatedAt,
  });

  final String id;
  final String studentCode;
  final String studentName;
  final String semesterName;
  final double? studentTotal;
  final double? classTotal;
  final double? advisorTotal;
  final String approvedAt;
  final String updatedAt;

  bool get isApproved => approvedAt.isNotEmpty;

  factory AdminDrlAssessment.fromJson(Map<String, dynamic> json) {
    return AdminDrlAssessment(
      id: json['id']?.toString() ?? '',
      studentCode: json['student_code']?.toString() ?? '',
      studentName: json['student_name']?.toString() ?? '',
      semesterName: json['semester_name']?.toString() ?? '',
      studentTotal: _doubleOrNull(json['student_total']),
      classTotal: _doubleOrNull(json['class_total']),
      advisorTotal: _doubleOrNull(json['advisor_total']),
      approvedAt: json['approved_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }
}

class AdminStudent {
  const AdminStudent({
    required this.id,
    required this.code,
    required this.name,
    required this.email,
    required this.phone,
    required this.studentClass,
    required this.department,
  });

  final String id;
  final String code;
  final String name;
  final String email;
  final String phone;
  final String studentClass;
  final String department;

  factory AdminStudent.fromJson(Map<String, dynamic> json) {
    return AdminStudent(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      studentClass: json['class']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
    );
  }
}

class AdminActivity {
  const AdminActivity({
    required this.id,
    required this.name,
    required this.semester,
    required this.department,
    required this.timeStart,
    required this.timeStop,
    required this.points,
    required this.maxRegistrations,
    required this.status,
  });

  final String id;
  final String name;
  final String semester;
  final String department;
  final String timeStart;
  final String timeStop;
  final double? points;
  final int maxRegistrations;
  final String status;

  factory AdminActivity.fromJson(Map<String, dynamic> json) {
    return AdminActivity(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      semester: json['semester']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
      timeStart: json['time_start']?.toString() ?? '',
      timeStop: json['time_stop']?.toString() ?? '',
      points: _doubleOrNull(json['points']),
      maxRegistrations:
          int.tryParse(json['max_registrations']?.toString() ?? '') ?? 0,
      status: json['status']?.toString() ?? '',
    );
  }
}

class GvcnDrlDetail {
  const GvcnDrlDetail({
    required this.item,
    required this.student,
    required this.semester,
    required this.rows,
    required this.studentTotal,
    required this.classTotal,
    required this.gvcnXepLoai,
    required this.adminNotes,
  });

  final AdminDrlAssessment item;
  final Map<String, String> student;
  final Map<String, String> semester;
  final List<GvcnDrlCriterion> rows;
  final double? studentTotal;
  final double? classTotal;
  final String gvcnXepLoai;
  final Map<String, String> adminNotes;

  factory GvcnDrlDetail.fromJson(Map<String, dynamic> json) {
    return GvcnDrlDetail(
      item: AdminDrlAssessment.fromJson(
        json['item'] as Map<String, dynamic>? ?? const {},
      ),
      student: _stringMap(json['student']),
      semester: _stringMap(json['semester']),
      rows: (json['rows'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(GvcnDrlCriterion.fromJson)
          .toList(),
      studentTotal: _doubleOrNull(json['student_total']),
      classTotal: _doubleOrNull(json['class_total']),
      gvcnXepLoai: json['gvcn_xep_loai']?.toString() ?? '',
      adminNotes: _stringMap(json['admin_notes']),
    );
  }
}

class GvcnDrlCriterion {
  const GvcnDrlCriterion({
    required this.key,
    required this.section,
    required this.title,
    required this.maxScore,
    required this.studentScore,
    required this.classScore,
    required this.advisorScore,
    required this.sourceNote,
  });

  final String key;
  final String section;
  final String title;
  final double? maxScore;
  final double? studentScore;
  final double? classScore;
  final double? advisorScore;
  final String sourceNote;

  factory GvcnDrlCriterion.fromJson(Map<String, dynamic> json) {
    return GvcnDrlCriterion(
      key: json['key']?.toString() ?? '',
      section: json['section']?.toString() ?? '',
      title:
          json['label']?.toString() ??
          json['title']?.toString() ??
          json['name']?.toString() ??
          json['key']?.toString() ??
          '',
      maxScore: _doubleOrNull(json['max'] ?? json['max_score']),
      studentScore: _doubleOrNull(json['effective_score'] ?? json['score']),
      classScore: _doubleOrNull(json['class_score']),
      advisorScore: _doubleOrNull(json['advisor_score']),
      sourceNote: json['source_note']?.toString() ?? '',
    );
  }
}

Map<String, String> _stringMap(dynamic value) {
  return (value as Map? ?? const {}).map(
    (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
  );
}

double? _doubleOrNull(dynamic value) {
  if (value == null || value.toString().isEmpty) return null;
  return double.tryParse(value.toString());
}
