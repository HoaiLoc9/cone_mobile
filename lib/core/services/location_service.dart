import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationCheckResult {
  final bool isAllowed;
  final double distanceMeters;
  final String? message;
  final Position? position;

  const LocationCheckResult({
    required this.isAllowed,
    required this.distanceMeters,
    this.message,
    this.position,
  });
}

class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  // Tọa độ mặc định của Trường CĐ Kinh tế Đối ngoại (Cơ sở Phước Bình, TP. Thủ Đức, TP.HCM)
  static const double defaultCampusLat = 10.8256;
  static const double defaultCampusLng = 106.7725;
  static const double defaultMaxRadiusMeters = 800.0; // Bán kính 800m quanh khuôn viên

  /// Kiểm tra và yêu cầu cấp quyền vị trí GPS
  Future<bool> checkAndRequestPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[LocationService] Dịch vụ định vị GPS chưa được bật.');
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('[LocationService] Quyền vị trí bị người dùng từ chối.');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('[LocationService] Quyền vị trí bị từ chối vĩnh viễn trong Cài đặt.');
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('[LocationService] Lỗi kiểm tra quyền: $e');
      return false;
    }
  }

  /// Lấy vị trí GPS hiện tại của sinh viên
  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await checkAndRequestPermission();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      debugPrint('[LocationService] Lỗi lấy vị trí hiện tại: $e');
      return null;
    }
  }

  /// Tính khoảng cách (mét) giữa 2 tọa độ GPS
  double calculateDistance({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Xác thực xem sinh viên có đang ở đúng vị trí diễn ra sự kiện không (chống điểm danh hộ)
  Future<LocationCheckResult> verifyEventLocation({
    double targetLat = defaultCampusLat,
    double targetLng = defaultCampusLng,
    double maxRadiusMeters = defaultMaxRadiusMeters,
  }) async {
    // Trên web hoặc thiết bị test không có GPS, cho phép bỏ qua nếu không lấy được
    if (kIsWeb) {
      return const LocationCheckResult(
        isAllowed: true,
        distanceMeters: 0,
        message: 'Bỏ qua kiểm tra GPS trên trình duyệt Web.',
      );
    }

    final pos = await getCurrentPosition();
    if (pos == null) {
      return const LocationCheckResult(
        isAllowed: false,
        distanceMeters: -1,
        message: 'Không thể xác định vị trí GPS. Vui lòng bật định vị trên điện thoại và cấp quyền.',
      );
    }

    final distance = calculateDistance(
      startLatitude: pos.latitude,
      startLongitude: pos.longitude,
      endLatitude: targetLat,
      endLongitude: targetLng,
    );

    if (distance <= maxRadiusMeters) {
      return LocationCheckResult(
        isAllowed: true,
        distanceMeters: distance,
        message: 'Vị trí hợp lệ: Cách sự kiện ${(distance).toStringAsFixed(0)}m.',
        position: pos,
      );
    } else {
      return LocationCheckResult(
        isAllowed: false,
        distanceMeters: distance,
        message: 'Bạn đang ở quá xa địa điểm tổ chức (${(distance / 1000).toStringAsFixed(1)}km, bán kính tối đa ${(maxRadiusMeters).toStringAsFixed(0)}m). Điểm danh không hợp lệ!',
        position: pos,
      );
    }
  }
}
