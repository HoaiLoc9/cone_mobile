import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/local_notification_service.dart';
import '../../../core/services/location_service.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../activities/presentation/activity_helpers.dart';
import '../data/qr_scan_result.dart';
import '../data/qr_scan_service.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key, required this.service});

  final QrScanService service;

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );
  bool _isBusy = false;
  bool _torchOn = false;
  String? _lastRawValue;
  String? _message;
  QrScanResult? _result;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isBusy) {
      return;
    }

    String? rawValue;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();
      if (value != null && value.isNotEmpty) {
        rawValue = value;
        break;
      }
    }

    if (rawValue == null || rawValue == _lastRawValue) {
      return;
    }

    _lastRawValue = rawValue;
    await _submit(rawValue);
  }

  Future<void> _submit(String rawValue) async {
    setState(() {
      _isBusy = true;
      _message = 'Đang kiểm tra vị trí GPS...';
    });

    try {
      await _controller.stop();

      // 1. Kiểm tra vị trí GPS chống điểm danh hộ từ xa
      final locationCheck = await LocationService.instance.verifyEventLocation();
      if (!locationCheck.isAllowed) {
        setState(() => _message = locationCheck.message);
        await _restartScannerAfterError();
        return;
      }

      final result = await widget.service.submit(rawValue);
      setState(() {
        _result = result;
        _message = 'Điểm danh thành công!';
      });

      // 2. Bắn thông báo đẩy cục bộ
      LocalNotificationService.instance.showNotification(
        title: 'Điểm danh thành công! 🎉',
        body: 'Hoạt động: ${result.activityName}. Điểm rèn luyện của bạn đã được ghi nhận.',
      );
    } on ApiException catch (error) {
      setState(() => _message = error.message);
      await _restartScannerAfterError();
    } catch (_) {
      setState(() => _message = 'Không xử lý được mã QR. Vui lòng thử lại.');
      await _restartScannerAfterError();
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _restartScannerAfterError() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted || _result != null) {
      return;
    }
    _lastRawValue = null;
    await _controller.start();
  }

  Future<void> _scanAgain() async {
    setState(() {
      _result = null;
      _message = null;
      _lastRawValue = null;
    });
    await _controller.start();
  }

  Future<void> _toggleTorch() async {
    await _controller.toggleTorch();
    setState(() => _torchOn = !_torchOn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        title: const Text(
          'QR Scan',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Đổi camera',
            onPressed: _result == null ? _controller.switchCamera : null,
            icon: const Icon(Icons.cameraswitch_rounded),
          ),
          IconButton(
            tooltip: 'Đèn flash',
            onPressed: _result == null ? _toggleTorch : null,
            icon: Icon(
              _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _result == null
            ? _buildScanner()
            : _ResultView(result: _result!, onScanAgain: _scanAgain),
      ),
    );
  }

  Widget _buildScanner() {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                children: [
                  MobileScanner(
                    controller: _controller,
                    onDetect: _onDetect,
                    errorBuilder: (context, error) => _ScannerError(
                      message:
                          error.errorDetails?.message ??
                          'Không mở được camera.',
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.85),
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Center(
                          child: Container(
                            width: 230,
                            height: 230,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.primary,
                                width: 4,
                              ),
                              borderRadius: BorderRadius.circular(26),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_isBusy)
                    Positioned.fill(
                      child: ColoredBox(
                        color: Colors.black.withValues(alpha: 0.35),
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
          child: _ScanHint(message: _message),
        ),
      ],
    );
  }
}

class _ScanHint extends StatelessWidget {
  const _ScanHint({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkBlue.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.qr_code_scanner_rounded,
            color: AppColors.primary,
            size: 34,
          ),
          const SizedBox(height: 10),
          const Text(
            'Đưa mã QR điểm danh vào khung quét',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message ?? 'Camera sẽ tự nhận diện khi QR hợp lệ.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: message == null
                  ? AppColors.textSecondary
                  : AppColors.danger,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.security_rounded, size: 14, color: AppColors.primary),
                SizedBox(width: 6),
                Text(
                  'Định vị GPS bảo vệ: Chống điểm danh hộ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.result, required this.onScanAgain});

  final QrScanResult result;
  final Future<void> Function() onScanAgain;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF059669), AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.verified_rounded,
                  color: Colors.white,
                  size: 52,
                ),
                const SizedBox(height: 14),
                const Text(
                  'Điểm danh thành công!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  result.typeLabel,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.86),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _ResultCard(result: result),
          const SizedBox(height: 24),
          PrimaryButton(label: 'Quét mã khác', onPressed: onScanAgain),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final QrScanResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkBlue.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _RowInfo(
            icon: Icons.event_available,
            label: 'Hoạt động',
            value: result.activityName,
          ),
          _RowInfo(
            icon: Icons.place_outlined,
            label: 'Địa điểm',
            value: result.location.isEmpty ? '-' : result.location,
          ),
          _RowInfo(
            icon: Icons.schedule,
            label: 'Thời gian',
            value: formatDateTime(result.timeStart),
          ),
          _RowInfo(
            icon: Icons.stars_outlined,
            label: 'Điểm',
            value: result.points.toStringAsFixed(
              result.points.truncateToDouble() == result.points ? 0 : 1,
            ),
          ),
          _RowInfo(
            icon: Icons.how_to_reg,
            label: 'Đăng ký',
            value: result.hasRegistered ? 'Đã đăng ký' : 'Chưa đăng ký',
          ),
          _RowInfo(
            icon: Icons.login_rounded,
            label: 'Check-in',
            value: formatDateTime(result.checkInAt),
          ),
          _RowInfo(
            icon: Icons.logout_rounded,
            label: 'Check-out',
            value: formatDateTime(result.checkOutAt),
          ),
        ],
      ),
    );
  }
}

class _RowInfo extends StatelessWidget {
  const _RowInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerError extends StatelessWidget {
  const _ScannerError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.textPrimary,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
