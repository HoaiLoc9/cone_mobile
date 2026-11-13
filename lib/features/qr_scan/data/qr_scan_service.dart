import '../../../core/network/api_client.dart';
import 'qr_scan_result.dart';

class QrScanService {
  QrScanService({required String token, ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient() {
    _apiClient.setToken(token);
  }

  final ApiClient _apiClient;

  Future<QrScanResult> preview(String qrValue) async {
    final path = Uri(
      path: '/mobile/qr/preview',
      queryParameters: {'qr': qrValue},
    ).toString();
    final data = await _apiClient.get(path);
    return QrScanResult.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<QrScanResult> submit(String qrValue) async {
    final data = await _apiClient.post(
      '/mobile/qr/scan',
      body: {'qr': qrValue},
    );
    return QrScanResult.fromJson(data['data'] as Map<String, dynamic>);
  }
}
