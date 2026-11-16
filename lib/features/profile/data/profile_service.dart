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

  Future<Map<String, dynamic>?> fetchPendingRequest() async {
    try {
      final res = await _apiClient.get('/mobile/profile/request-update');
      final data = res['data'];
      if (data != null && data is Map<String, dynamic>) {
        final request = data['request'];
        if (request != null && request is Map<String, dynamic>) {
          return request;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> submitProfileChangeRequest({
    required String email,
    required String phone,
    required String address,
    ProfileUpload? avatar,
  }) async {
    await _apiClient.post(
      '/mobile/profile/request-update',
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
  }

  Future<void> cancelProfileRequest() async {
    try {
      await _apiClient.delete('/mobile/profile/request-update');
    } catch (_) {}
  }

  Future<void> sendPasswordOtp(String email) async {
    try {
      await _apiClient.post(
        '/mobile/password/request-otp',
        body: {'email': email},
      );
    } catch (_) {
      // Fallback: If backend uses admin OTP or custom route
      try {
        await _apiClient.post(
          '/mobile/admin/password/request-otp',
          body: {'email': email},
        );
      } catch (_) {
        // If simulated or demo mode, proceed without blocking user
      }
    }
  }

  Future<void> changePassword({
    required String password,
    required String passwordConfirmation,
    String? otp,
  }) async {
    await _apiClient.post(
      '/mobile/profile/password',
      body: {
        'password': password,
        'password_confirmation': passwordConfirmation,
        if (otp != null && otp.isNotEmpty) 'otp': otp,
      },
    );
  }
}

class ProfileUpload {
  const ProfileUpload({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}
