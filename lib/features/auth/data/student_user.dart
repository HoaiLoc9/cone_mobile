class StudentUser {
  const StudentUser({
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

  factory StudentUser.fromJson(Map<String, dynamic> json) {
    return StudentUser(
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
