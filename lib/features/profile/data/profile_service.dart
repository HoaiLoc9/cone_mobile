import 'dart:convert';
import 'dart:typed_data';

import '../../../core/network/api_client.dart';
import 'profile_models.dart';

class ProfileService {
  ProfileService({required String token, ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient() {
    _apiClient.setToken(token);
  }

  final ApiClient _apiClient;

  Future<ProfileData> fetchProfile() async {
    final data = await _apiClient.get('/mobile/profile');
    return ProfileData.fromJson(data);
  }

  Future<ProfileData> updateProfile({
    required String email,
    required String phone,
    required String address,
    ProfileUpload? avatar,
  }) async {
    final data = await _apiClient.post(
      '/mobile/profile',
      body: {
        'email': email,
        'phone': phone,
        'address': address,
        if (avatar != null)
          'avatar_base64': {
            'name': avatar.name,
            'content': base64Encode(avatar.bytes),
          },
      },
    );
    return ProfileData.fromJson(data);
  }

  Future<void> changePassword({
    required String password,
    required String passwordConfirmation,
  }) async {
    await _apiClient.post(
      '/mobile/profile/password',
      body: {
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
  }
}

class ProfileUpload {
  const ProfileUpload({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}
