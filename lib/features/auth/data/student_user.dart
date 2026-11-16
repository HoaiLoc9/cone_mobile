import '../../../core/config/api_config.dart';

class StudentUser {
  const StudentUser({
    required this.id,
    required this.code,
    required this.name,
    required this.email,
    required this.phone,
    required this.studentClass,
    required this.department,
    this.avatarUrl = '',
  });

  final String id;
  final String code;
  final String name;
  final String email;
  final String phone;
  final String studentClass;
  final String department;
  final String avatarUrl;

  factory StudentUser.fromJson(Map<String, dynamic> json) {
    return StudentUser(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      studentClass: json['class']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
      avatarUrl: ApiConfig.storageUrl(json['avatar_url']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'email': email,
      'phone': phone,
      'class': studentClass,
      'department': department,
      'avatar_url': avatarUrl,
    };
  }
}
