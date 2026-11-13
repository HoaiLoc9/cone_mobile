import '../../../core/config/api_config.dart';

class DrlSemester {
  const DrlSemester({
    required this.id,
    required this.name,
    required this.start,
    required this.stop,
    required this.status,
  });

  final String id;
  final String name;
  final DateTime? start;
  final DateTime? stop;
  final String? status;

  factory DrlSemester.fromJson(Map<String, dynamic> json) {
    return DrlSemester(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      start: _parseDate(json['start']),
      stop: _parseDate(json['stop']),
      status: json['status']?.toString(),
    );
  }
}

class DrlSemesterSummary {
  const DrlSemesterSummary({
    required this.semesterId,
    required this.semesterName,
    required this.totalPoints,
    required this.activityCount,
  });

  final String semesterId;
  final String semesterName;
  final double totalPoints;
  final int activityCount;

  factory DrlSemesterSummary.fromJson(Map<String, dynamic> json) {
    return DrlSemesterSummary(
      semesterId: json['semester_id']?.toString() ?? '',
      semesterName: json['semester_name']?.toString() ?? '',
      totalPoints: (json['total_points'] as num?)?.toDouble() ?? 0,
      activityCount: (json['activity_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class DrlSummary {
  const DrlSummary({
    required this.totalPoints,
    required this.semesterSummaries,
    required this.semesters,
  });

  final double totalPoints;
  final List<DrlSemesterSummary> semesterSummaries;
  final List<DrlSemester> semesters;

  factory DrlSummary.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final summaries = data['semester_summaries'] as List<dynamic>? ?? [];
    final semesters = data['semesters'] as List<dynamic>? ?? [];

    return DrlSummary(
      totalPoints: (data['total_points'] as num?)?.toDouble() ?? 0,
      semesterSummaries: summaries
          .map(
            (item) => DrlSemesterSummary.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      semesters: semesters
          .map((item) => DrlSemester.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DrlDetail {
  const DrlDetail({
    required this.semester,
    required this.activityScore,
    required this.criteriaScore,
  });

  final DrlSemester semester;
  final DrlActivityScore activityScore;
  final DrlCriteriaScore criteriaScore;

  factory DrlDetail.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return DrlDetail(
      semester: DrlSemester.fromJson(
        data['semester'] as Map<String, dynamic>? ?? {},
      ),
      activityScore: DrlActivityScore.fromJson(
        data['activity_score'] as Map<String, dynamic>? ?? {},
      ),
      criteriaScore: DrlCriteriaScore.fromJson(
        data['criteria_score'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class DrlActivityScore {
  const DrlActivityScore({required this.totalPoints, required this.rows});

  final double totalPoints;
  final List<DrlActivityRow> rows;

  factory DrlActivityScore.fromJson(Map<String, dynamic> json) {
    final rows = json['rows'] as List<dynamic>? ?? [];
    return DrlActivityScore(
      totalPoints: (json['total_points'] as num?)?.toDouble() ?? 0,
      rows: rows
          .map((item) => DrlActivityRow.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DrlActivityRow {
  const DrlActivityRow({
    required this.activityId,
    required this.activityName,
    required this.pointsPlus,
    required this.pointsMinus,
    required this.netPoints,
    required this.timeStart,
    required this.timeStop,
    required this.attendanceNote,
  });

  final String activityId;
  final String activityName;
  final double pointsPlus;
  final double pointsMinus;
  final double netPoints;
  final DateTime? timeStart;
  final DateTime? timeStop;
  final String attendanceNote;

  factory DrlActivityRow.fromJson(Map<String, dynamic> json) {
    return DrlActivityRow(
      activityId: json['activity_id']?.toString() ?? '',
      activityName: json['activity_name']?.toString() ?? '',
      pointsPlus: (json['points_plus'] as num?)?.toDouble() ?? 0,
      pointsMinus: (json['points_minus'] as num?)?.toDouble() ?? 0,
      netPoints: (json['net_points'] as num?)?.toDouble() ?? 0,
      timeStart: _parseDate(json['time_start']),
      timeStop: _parseDate(json['time_stop']),
      attendanceNote: json['attendance_note']?.toString() ?? '',
    );
  }
}

class DrlCriteriaScore {
  const DrlCriteriaScore({
    required this.hasAssessment,
    required this.studentTotal,
    required this.studentTotalRaw,
    required this.studentClassification,
    required this.classTotal,
    required this.classClassification,
    required this.advisorTotal,
    required this.advisorClassification,
    required this.activityHint,
    required this.sections,
  });

  final bool hasAssessment;
  final double studentTotal;
  final double studentTotalRaw;
  final String studentClassification;
  final double classTotal;
  final String classClassification;
  final double advisorTotal;
  final String advisorClassification;
  final double? activityHint;
  final List<DrlCriteriaSection> sections;

  factory DrlCriteriaScore.fromJson(Map<String, dynamic> json) {
    final sections = json['sections'] as List<dynamic>? ?? [];
    return DrlCriteriaScore(
      hasAssessment: json['has_assessment'] == true,
      studentTotal: (json['student_total'] as num?)?.toDouble() ?? 0,
      studentTotalRaw: (json['student_total_raw'] as num?)?.toDouble() ?? 0,
      studentClassification: json['student_classification']?.toString() ?? '',
      classTotal: (json['class_total'] as num?)?.toDouble() ?? 0,
      classClassification: json['class_classification']?.toString() ?? '',
      advisorTotal: (json['advisor_total'] as num?)?.toDouble() ?? 0,
      advisorClassification: json['advisor_classification']?.toString() ?? '',
      activityHint: (json['activity_hint'] as num?)?.toDouble(),
      sections: sections
          .map(
            (item) => DrlCriteriaSection.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

class DrlCriteriaSection {
  const DrlCriteriaSection({
    required this.section,
    required this.sum,
    required this.capped,
    required this.classCapped,
    required this.advisorCapped,
    required this.criteria,
  });

  final String section;
  final double sum;
  final double capped;
  final double classCapped;
  final double advisorCapped;
  final List<DrlCriterion> criteria;

  factory DrlCriteriaSection.fromJson(Map<String, dynamic> json) {
    final criteria = json['criteria'] as List<dynamic>? ?? [];
    return DrlCriteriaSection(
      section: json['section']?.toString() ?? '',
      sum: (json['sum'] as num?)?.toDouble() ?? 0,
      capped: (json['capped'] as num?)?.toDouble() ?? 0,
      classCapped: (json['class_capped'] as num?)?.toDouble() ?? 0,
      advisorCapped: (json['advisor_capped'] as num?)?.toDouble() ?? 0,
      criteria: criteria
          .map((item) => DrlCriterion.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DrlCriterion {
  const DrlCriterion({
    required this.key,
    required this.label,
    required this.note,
    required this.maxDisplay,
    required this.minScore,
    required this.maxScore,
    required this.score,
    required this.effectiveScore,
    required this.classScore,
    required this.advisorScore,
    required this.sourceNote,
    required this.isEditable,
    required this.studentMayFill,
    required this.requiresEvidence,
    required this.showEvidence,
    required this.hasEvidence,
    required this.evidenceStored,
  });

  final String key;
  final String label;
  final String note;
  final double maxDisplay;
  final double minScore;
  final double maxScore;
  final double? score;
  final double? effectiveScore;
  final double? classScore;
  final double? advisorScore;
  final String? sourceNote;
  final bool isEditable;
  final bool studentMayFill;
  final bool requiresEvidence;
  final bool showEvidence;
  final bool hasEvidence;
  final List<DrlEvidenceFile> evidenceStored;

  factory DrlCriterion.fromJson(Map<String, dynamic> json) {
    final evidence = json['evidence_stored'] as List<dynamic>? ?? [];
    return DrlCriterion(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
      maxDisplay: (json['max_display'] as num?)?.toDouble() ?? 0,
      minScore: (json['min_score'] as num?)?.toDouble() ?? 0,
      maxScore: (json['max_score'] as num?)?.toDouble() ?? 0,
      score: (json['score'] as num?)?.toDouble(),
      effectiveScore: (json['effective_score'] as num?)?.toDouble(),
      classScore: (json['class_score'] as num?)?.toDouble(),
      advisorScore: (json['advisor_score'] as num?)?.toDouble(),
      sourceNote: json['source_note']?.toString(),
      isEditable: json['is_editable'] == true,
      studentMayFill: json['student_may_fill'] == true,
      requiresEvidence: json['requires_evidence'] == true,
      showEvidence: json['show_evidence'] == true,
      hasEvidence: json['has_evidence'] == true,
      evidenceStored: evidence
          .map((item) => DrlEvidenceFile.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DrlEvidenceFile {
  const DrlEvidenceFile({
    required this.path,
    required this.name,
    required this.url,
  });

  final String path;
  final String name;
  final String url;

  factory DrlEvidenceFile.fromJson(Map<String, dynamic> json) {
    return DrlEvidenceFile(
      path: json['path']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      url: ApiConfig.storageUrl(json['url']?.toString() ?? ''),
    );
  }
}

class DrlSelfAssessmentForm {
  const DrlSelfAssessmentForm({
    required this.semester,
    required this.mayEdit,
    required this.deadlineLabel,
    required this.isApproved,
    required this.criteriaScore,
  });

  final DrlSemester semester;
  final bool mayEdit;
  final String deadlineLabel;
  final bool isApproved;
  final DrlCriteriaScore criteriaScore;

  factory DrlSelfAssessmentForm.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return DrlSelfAssessmentForm(
      semester: DrlSemester.fromJson(
        data['semester'] as Map<String, dynamic>? ?? {},
      ),
      mayEdit: data['may_edit'] == true,
      deadlineLabel: data['deadline_label']?.toString() ?? '',
      isApproved: data['is_approved'] == true,
      criteriaScore: DrlCriteriaScore.fromJson(
        data['criteria_score'] as Map<String, dynamic>? ?? {},
      ),
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
