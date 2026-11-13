import '../../../core/config/api_config.dart';
import '../../auth/data/student_user.dart';

class ProfileData {
  const ProfileData({required this.user});

  final ProfileUser user;

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return ProfileData(
      user: ProfileUser.fromJson(data['user'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class ProfileUser {
  const ProfileUser({
    required this.id,
    required this.code,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.avatarUrl,
    required this.studentClass,
    required this.department,
    required this.type,
  });

  final String id;
  final String code;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String avatarUrl;
  final String studentClass;
  final String department;
  final String type;

  factory ProfileUser.fromJson(Map<String, dynamic> json) {
    return ProfileUser(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      avatarUrl: ApiConfig.storageUrl(json['avatar_url']?.toString() ?? ''),
      studentClass: json['class']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
    );
  }

  StudentUser toStudentUser() {
    return StudentUser(
      id: id,
      code: code,
      name: name,
      email: email,
      phone: phone,
      studentClass: studentClass,
      department: department,
    );
  }
}
