import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/local_notification_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/storage/app_storage.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../activities/presentation/activity_helpers.dart';
import '../data/qr_scan_result.dart';
import '../data/qr_scan_service.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({
    super.key,
    required this.service,
    this.onComplete,
  });

  final QrScanService service;
  final VoidCallback? onComplete;

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );
  bool _isBusy = false;
  bool _torchOn = false;
  static const String _historyStorageKey = 'cone_qr_scan_history';
  String? _lastRawValue;
  String? _message;
  QrScanResult? _result;
  List<_QrHistoryEntry> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final raw = await AppStorage.instance.getString(_historyStorageKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        final entries = decoded
            .whereType<Map>()
            .map((e) => _QrHistoryEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        if (mounted) {
          setState(() => _history = entries);
        }
      }
    } catch (_) {}
  }

  Future<void> _saveHistoryEntry(QrScanResult result) async {
    final entry = _QrHistoryEntry(
      activityName: result.activityName,
      location: result.location,
      typeLabel: result.typeLabel.isNotEmpty
          ? result.typeLabel
          : (result.checkOutAt != null ? 'Check-out' : 'Check-in'),
      points: result.points,
      scannedAt: result.scannedAt ?? DateTime.now(),
      checkInAt: result.checkInAt,
      checkOutAt: result.checkOutAt,
    );
    final updated = [entry, ..._history].take(30).toList();
    if (mounted) {
      setState(() => _history = updated);
    }
    try {
      await AppStorage.instance.setString(
        _historyStorageKey,
        jsonEncode(updated.map((e) => e.toJson()).toList()),
      );
    } catch (_) {}
  }

  Future<void> _clearHistory() async {
    if (mounted) {
      setState(() => _history = []);
    }
    try {
      await AppStorage.instance.remove(_historyStorageKey);
    } catch (_) {}
  }

  Future<void> _pickQrFromGallery() async {
    if (_isBusy) return;
    if (kIsWeb) {
      setState(() {
        _message =
            'Chọn ảnh mã QR từ thư viện hiện hỗ trợ trên ứng dụng điện thoại (Android/iOS). Vui lòng dùng camera trực tiếp trên Web.';
      });
      return;
    }

    try {
      final picked = await FilePicker.platform.pickFiles(type: FileType.image);
      if (picked == null || picked.files.isEmpty) return;
      final path = picked.files.single.path;
      if (path == null || path.isEmpty) {
        setState(() => _message = 'Không đọc được đường dẫn ảnh đã chọn.');
        return;
      }

      setState(() {
        _isBusy = true;
        _message = 'Đang phân tích mã QR từ ảnh...';
      });

      final capture = await _controller.analyzeImage(path);
      String? rawValue;
      if (capture != null) {
        for (final barcode in capture.barcodes) {
          final v = barcode.rawValue?.trim();
          if (v != null && v.isNotEmpty) {
            rawValue = v;
            break;
          }
        }
      }

      if (rawValue == null) {
        if (mounted) {
          setState(() {
            _isBusy = false;
            _message = 'Không tìm thấy mã QR hợp lệ trong ảnh đã chọn.';
          });
        }
        return;
      }

      _lastRawValue = rawValue;
      await _submit(rawValue);
    } catch (_) {
      if (mounted) {
        setState(() {
          _isBusy = false;
          _message = 'Không thể phân tích ảnh QR. Vui lòng thử lại.';
        });
      }
    }
  }

  void _openHistorySheet() {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.72,
              ),
              decoration: BoxDecoration(
                color: AppColors.adaptiveCard,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.adaptiveBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 12, 10),
                      child: Row(
                        children: [
                          const Icon(Icons.history_rounded, color: AppColors.primary, size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Lịch sử điểm danh QR (${_history.length})',
                              style: TextStyle(
                                color: AppColors.adaptiveTextPrimary,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (_history.isNotEmpty)
                            TextButton(
                              onPressed: () async {
                                await _clearHistory();
                                setModalState(() {});
                              },
                              child: const Text(
                                'Xóa tất cả',
                                style: TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                          IconButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            icon: Icon(Icons.close_rounded, color: AppColors.adaptiveTextSecondary),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: AppColors.adaptiveBorder),
                    if (_history.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 24),
                        child: Column(
                          children: [
                            Icon(
                              Icons.qr_code_2_rounded,
                              size: 46,
                              color: AppColors.adaptiveTextSecondary.withValues(alpha: 0.45),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Chưa có lịch sử điểm danh trên thiết bị này',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.adaptiveTextPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Các lần quét QR check-in / check-out thành công sẽ được lưu tự động tại đây.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.adaptiveTextSecondary,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                          itemCount: _history.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (_, index) {
                            final item = _history[index];
                            final isCheckout = item.typeLabel.toLowerCase().contains('out');
                            final badgeColor = isCheckout
                                ? const Color(0xFF059669)
                                : AppColors.primary;
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.adaptiveBackground,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.adaptiveBorder),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: badgeColor.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          item.typeLabel,
                                          style: TextStyle(
                                            color: badgeColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        formatDateTime(item.scannedAt),
                                        style: TextStyle(
                                          color: AppColors.adaptiveTextSecondary,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    item.activityName,
                                    style: TextStyle(
                                      color: AppColors.adaptiveTextPrimary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (item.location.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on_outlined,
                                          size: 13.5,
                                          color: AppColors.adaptiveTextSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            item.location,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: AppColors.adaptiveTextSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

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
      HapticFeedback.heavyImpact();
      setState(() {
        _result = result;
        _message = 'Điểm danh thành công!';
      });
      await _saveHistoryEntry(result);

      // 2. Bắn thông báo đẩy cục bộ
      LocalNotificationService.instance.showNotification(
        title: 'Điểm danh thành công',
        body: '${result.activityName} • Đã ghi nhận ĐRL',
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

  void _completeAttendance() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
    widget.onComplete?.call();
  }

  Future<void> _toggleTorch() async {
    await _controller.toggleTorch();
    setState(() => _torchOn = !_torchOn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.adaptiveBackground,
        surfaceTintColor: AppColors.adaptiveBackground,
        title: const Text(
          'QR Scan',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Lịch sử điểm danh',
            onPressed: _openHistorySheet,
            icon: const Icon(Icons.history_rounded),
          ),
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
            : _ResultView(
                result: _result!,
                onScanAgain: _scanAgain,
                onCompleteAttendance: _completeAttendance,
              ),
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
          child: _ScanHint(
            message: _message,
            historyCount: _history.length,
            onPickImage: _isBusy ? null : _pickQrFromGallery,
            onOpenHistory: _openHistorySheet,
          ),
        ),
      ],
    );
  }
}

class _ScanHint extends StatelessWidget {
  const _ScanHint({
    required this.message,
    required this.historyCount,
    required this.onPickImage,
    required this.onOpenHistory,
  });

  final String? message;
  final int historyCount;
  final VoidCallback? onPickImage;
  final VoidCallback onOpenHistory;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.adaptiveCard,
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
          Text(
            'Đưa mã QR điểm danh vào khung quét',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.adaptiveTextPrimary,
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
                  ? AppColors.adaptiveTextSecondary
                  : AppColors.danger,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.isDark
                  ? AppColors.primary.withValues(alpha: 0.16)
                  : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.isDark
                    ? AppColors.primary.withValues(alpha: 0.35)
                    : const Color(0xFFBFDBFE),
              ),
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
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPickImage,
                  icon: const Icon(Icons.photo_library_outlined, size: 17),
                  label: const Text(
                    'Chọn ảnh QR',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.35)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOpenHistory,
                  icon: const Icon(Icons.history_rounded, size: 17),
                  label: Text(
                    historyCount > 0 ? 'Lịch sử ($historyCount)' : 'Lịch sử',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.adaptiveTextPrimary,
                    side: BorderSide(color: AppColors.adaptiveBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.result,
    required this.onScanAgain,
    required this.onCompleteAttendance,
  });

  final QrScanResult result;
  final Future<void> Function() onScanAgain;
  final VoidCallback onCompleteAttendance;

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
          PrimaryButton(
            label: 'Hoàn thành điểm danh',
            icon: Icons.check_circle_rounded,
            backgroundColor: const Color(0xFF059669),
            onPressed: onCompleteAttendance,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: onScanAgain,
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
              label: const Text(
                'Quét mã khác',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.adaptiveTextPrimary,
                side: BorderSide(color: AppColors.adaptiveBorder, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
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
    final bool isCheckedOut = result.checkOutAt != null;
    final double awardedPoints = isCheckedOut ? result.points : (result.points / 2);
    final String awardedPointsStr = awardedPoints > 0
        ? (awardedPoints.truncateToDouble() == awardedPoints
            ? awardedPoints.toInt().toString()
            : awardedPoints.toStringAsFixed(1))
        : (isCheckedOut ? '5' : '2.5');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.adaptiveCard,
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isCheckedOut
                    ? const [Color(0xFF10B981), Color(0xFF059669)]
                    : const [Color(0xFFF59E0B), Color(0xFFD97706)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (isCheckedOut ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isCheckedOut ? Icons.celebration_rounded : Icons.star_half_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  isCheckedOut
                      ? '+$awardedPointsStr ĐIỂM RÈN LUYỆN ĐÃ GHI NHẬN ĐỦ!'
                      : '+$awardedPointsStr ĐIỂM RÈN LUYỆN (CHECK-IN: 50%)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12.5,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
            value: isCheckedOut
                ? '${result.points.toStringAsFixed(result.points.truncateToDouble() == result.points ? 0 : 1)} ĐRL (100%)'
                : '$awardedPointsStr / ${result.points.toStringAsFixed(result.points.truncateToDouble() == result.points ? 0 : 1)} ĐRL (Tạm tính 50%)',
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
              style: TextStyle(
                color: AppColors.adaptiveTextSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: AppColors.adaptiveTextPrimary,
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
      color: AppColors.adaptiveTextPrimary,
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

class _QrHistoryEntry {
  const _QrHistoryEntry({
    required this.activityName,
    required this.location,
    required this.typeLabel,
    required this.points,
    required this.scannedAt,
    this.checkInAt,
    this.checkOutAt,
  });

  final String activityName;
  final String location;
  final String typeLabel;
  final double points;
  final DateTime scannedAt;
  final DateTime? checkInAt;
  final DateTime? checkOutAt;

  Map<String, dynamic> toJson() => {
        'activity_name': activityName,
        'location': location,
        'type_label': typeLabel,
        'points': points,
        'scanned_at': scannedAt.toIso8601String(),
        'check_in_at': checkInAt?.toIso8601String(),
        'check_out_at': checkOutAt?.toIso8601String(),
      };

  factory _QrHistoryEntry.fromJson(Map<String, dynamic> json) {
    return _QrHistoryEntry(
      activityName: json['activity_name']?.toString() ?? 'Hoạt động',
      location: json['location']?.toString() ?? '',
      typeLabel: json['type_label']?.toString() ?? 'Điểm danh',
      points: (json['points'] as num?)?.toDouble() ?? 0,
      scannedAt: DateTime.tryParse(json['scanned_at']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      checkInAt: DateTime.tryParse(json['check_in_at']?.toString() ?? '')?.toLocal(),
      checkOutAt: DateTime.tryParse(json['check_out_at']?.toString() ?? '')?.toLocal(),
    );
  }
}
