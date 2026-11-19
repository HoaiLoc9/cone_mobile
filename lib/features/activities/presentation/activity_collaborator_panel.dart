import 'package:flutter/material.dart';
import 'package:qr/qr.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../data/activity_model.dart';
import '../data/activity_service.dart';

class ActivityCollaboratorPanel extends StatelessWidget {
  const ActivityCollaboratorPanel({
    super.key,
    required this.activity,
    required this.service,
  });

  final ActivityItem activity;
  final ActivityService service;

  void _openCollaboratorDashboard(BuildContext context, {int initialTab = 0}) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CollaboratorWorkspaceSheet(
        activity: activity,
        service: service,
        initialTab: initialTab,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final collab = activity.collaborator;
    if (!collab.isCollaborator) {
      return const SizedBox.shrink();
    }

    if (collab.isExpired) {
      return Container(
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.adaptiveCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.adaptiveBorder),
        ),
        child: Row(
          children: [
            Icon(Icons.history_toggle_off_rounded, color: AppColors.adaptiveTextSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Quyền Cộng tác viên tạm thời cho sự kiện này đã hết hạn và tự động thu hồi (${collab.expiresAtLabel}).',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.adaptiveTextSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.30),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'QUYỀN TẠM THỜI: CTV HỖ TRỢ SỰ KIỆN',
                      style: TextStyle(
                        color: Color(0xFF93C5FD),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      collab.expiresAtLabel.isNotEmpty
                          ? 'Tự động thu hồi: ${collab.expiresAtLabel}'
                          : 'Tự động thu hồi sau khi sự kiện kết thúc',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (collab.canDisplayQr)
                _buildActionPill(
                  icon: Icons.qr_code_2_rounded,
                  label: 'Chiếu mã QR Vào/Ra',
                  onTap: () => _openCollaboratorDashboard(context, initialTab: 0),
                ),
              if (collab.canManualCheckIn)
                _buildActionPill(
                  icon: Icons.person_add_alt_1_rounded,
                  label: 'Điểm danh theo MSSV',
                  onTap: () => _openCollaboratorDashboard(context, initialTab: 1),
                ),
              if (collab.canViewAttendees)
                _buildActionPill(
                  icon: Icons.fact_check_rounded,
                  label: 'Danh sách & Sĩ số',
                  onTap: () => _openCollaboratorDashboard(context, initialTab: 2),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionPill({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 17),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CollaboratorWorkspaceSheet extends StatefulWidget {
  const _CollaboratorWorkspaceSheet({
    required this.activity,
    required this.service,
    this.initialTab = 0,
  });

  final ActivityItem activity;
  final ActivityService service;
  final int initialTab;

  @override
  State<_CollaboratorWorkspaceSheet> createState() =>
      _CollaboratorWorkspaceSheetState();
}

class _CollaboratorWorkspaceSheetState extends State<_CollaboratorWorkspaceSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 3,
    vsync: this,
    initialIndex: widget.initialTab.clamp(0, 2),
  );

  late Future<CollaboratorOverviewData> _overviewFuture = _loadOverview();
  final TextEditingController _mssvCtrl = TextEditingController();
  int _checkInType = 1; // 1 = QR Vào, 2 = QR Ra
  int _qrDisplayType = 1; // 1 = QR Vào, 2 = QR Ra
  bool _submittingCheckIn = false;

  Future<CollaboratorOverviewData> _loadOverview() {
    return widget.service.fetchCollaboratorOverview(widget.activity.id);
  }

  void _reload() {
    setState(() {
      _overviewFuture = _loadOverview();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mssvCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitManualCheckIn() async {
    final code = _mssvCtrl.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập Mã số sinh viên (MSSV).'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _submittingCheckIn = true);
    try {
      final msg = await widget.service.collaboratorCheckIn(
        id: widget.activity.id,
        studentCode: code,
        type: _checkInType,
      );
      if (!mounted) return;
      _mssvCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.primary),
      );
      _reload();
    } catch (e) {
      if (!mounted) return;
      final errMsg = e is ApiException ? e.message : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errMsg), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _submittingCheckIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.55,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, _) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.adaptiveBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.adaptiveBorder,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 12, 6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bảng điều khiển CTV Sự kiện',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.adaptiveTextPrimary,
                            ),
                          ),
                          Text(
                            widget.activity.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.adaptiveTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh_rounded),
                      tooltip: 'Làm mới',
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.adaptiveTextSecondary,
                indicatorColor: AppColors.primary,
                labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                tabs: const [
                  Tab(icon: Icon(Icons.qr_code_2_rounded, size: 18), text: 'Chiếu QR'),
                  Tab(icon: Icon(Icons.person_add_alt_1_rounded, size: 18), text: 'Điểm danh MSSV'),
                  Tab(icon: Icon(Icons.fact_check_rounded, size: 18), text: 'Sĩ số & DS'),
                ],
              ),
              Expanded(
                child: FutureBuilder<CollaboratorOverviewData>(
                  future: _overviewFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, color: AppColors.danger, size: 42),
                              const SizedBox(height: 10),
                              Text(
                                snapshot.error.toString(),
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.adaptiveTextSecondary),
                              ),
                              const SizedBox(height: 14),
                              FilledButton(onPressed: _reload, child: const Text('Thử lại')),
                            ],
                          ),
                        ),
                      );
                    }

                    final data = snapshot.data!;
                    return TabBarView(
                      controller: _tabController,
                      children: [
                        _buildQrProjectionTab(data),
                        _buildManualCheckInTab(data),
                        _buildAttendeesTab(data),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQrProjectionTab(CollaboratorOverviewData data) {
    if (!widget.activity.collaborator.canDisplayQr) {
      return const Center(
        child: Text('Bạn không được cấp quyền hiển thị mã QR cho sự kiện này.'),
      );
    }

    final qrPayload = _qrDisplayType == 1
        ? (data.qrVaoUrl.isNotEmpty ? data.qrVaoUrl : data.qrVaoToken)
        : (data.qrRaUrl.isNotEmpty ? data.qrRaUrl : data.qrRaToken);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(
              value: 1,
              icon: Icon(Icons.login_rounded),
              label: Text('Mã QR Vào (Check-in)'),
            ),
            ButtonSegment(
              value: 2,
              icon: Icon(Icons.logout_rounded),
              label: Text('Mã QR Ra (Check-out)'),
            ),
          ],
          selected: {_qrDisplayType},
          onSelectionChanged: (s) => setState(() => _qrDisplayType = s.first),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.adaptiveBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _qrDisplayType == 1 ? 'ĐIỂM DANH VÀO (CHECK-IN)' : 'ĐIỂM DANH RA (CHECK-OUT)',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (qrPayload.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Chưa có mã QR cho loại điểm danh này.'),
                )
              else
                SizedBox(
                  width: 220,
                  height: 220,
                  child: CustomPaint(
                    painter: _CollabQrPainter(
                      data: qrPayload,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'Đưa màn hình này cho sinh viên tham gia quét bằng ứng dụng COne',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildManualCheckInTab(CollaboratorOverviewData data) {
    if (!widget.activity.collaborator.canManualCheckIn) {
      return const Center(
        child: Text('Bạn không được cấp quyền điểm danh thủ công theo MSSV.'),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.adaptiveCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.adaptiveBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Điểm danh hỗ trợ sinh viên tại bàn trực',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppColors.adaptiveTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Dùng khi sinh viên bị hết pin điện thoại hoặc camera không quét được mã QR. Hệ thống sẽ ghi nhận tên bạn là CTV xác nhận.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.adaptiveTextSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(
                    value: 1,
                    icon: Icon(Icons.login_rounded),
                    label: Text('Check-in (Vào)'),
                  ),
                  ButtonSegment(
                    value: 2,
                    icon: Icon(Icons.logout_rounded),
                    label: Text('Check-out (Ra)'),
                  ),
                ],
                selected: {_checkInType},
                onSelectionChanged: (s) => setState(() => _checkInType = s.first),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _mssvCtrl,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submitManualCheckIn(),
                decoration: InputDecoration(
                  labelText: 'Nhập Mã số sinh viên (MSSV)',
                  hintText: 'VD: 22714651',
                  prefixIcon: const Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _submittingCheckIn ? null : _submitManualCheckIn,
                  icon: _submittingCheckIn
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.verified_user_rounded, size: 18),
                  label: Text(
                    _checkInType == 1
                        ? 'Xác nhận Điểm danh Vào (Check-in)'
                        : 'Xác nhận Điểm danh Ra (Check-out)',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttendeesTab(CollaboratorOverviewData data) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard('Đã đăng ký', '${data.registeredCount}', AppColors.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard('Đã Vào', '${data.checkInCount}', const Color(0xFF0284C7)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard('Đã Ra', '${data.checkOutCount}', const Color(0xFF10B981)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (!widget.activity.collaborator.canViewAttendees)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Bạn không được cấp quyền xem danh sách chi tiết.'),
            ),
          )
        else if (data.attendees.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Text(
                'Chưa có sinh viên nào trong danh sách.',
                style: TextStyle(color: AppColors.adaptiveTextSecondary),
              ),
            ),
          )
        else
          ...data.attendees.map((stu) {
            final hasIn = stu['has_checkin'] == true;
            final hasOut = stu['has_checkout'] == true;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.adaptiveCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.adaptiveBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stu['name']?.toString() ?? 'Sinh viên',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.adaptiveTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'MSSV: ${stu['code'] ?? ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.adaptiveTextSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildCheckBadge('Vào', hasIn, stu['checkin_at']?.toString()),
                  const SizedBox(width: 6),
                  _buildCheckBadge('Ra', hasOut, stu['checkout_at']?.toString()),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.adaptiveCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.adaptiveBorder),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.adaptiveTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckBadge(String label, bool done, String? time) {
    final color = done ? const Color(0xFF10B981) : const Color(0xFF94A3B8);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            done && time != null && time.isNotEmpty ? '$label ($time)' : label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _CollabQrPainter extends CustomPainter {
  _CollabQrPainter({required this.data, required this.color});

  final String data;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    try {
      final qrCode = QrCode.fromData(
        data: data,
        errorCorrectLevel: QrErrorCorrectLevel.M,
      );
      final qrImage = QrImage(qrCode);
      final count = qrImage.moduleCount;
      final pixelSize = size.width / count;
      final paint = Paint()..color = color;

      for (int x = 0; x < count; x++) {
        for (int y = 0; y < count; y++) {
          if (qrImage.isDark(y, x)) {
            final rect = Rect.fromLTWH(
              x * pixelSize,
              y * pixelSize,
              pixelSize,
              pixelSize,
            );
            canvas.drawRRect(
              RRect.fromRectAndRadius(rect, Radius.circular(pixelSize * 0.2)),
              paint,
            );
          }
        }
      }
    } catch (_) {}
  }

  @override
  bool shouldRepaint(covariant _CollabQrPainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.color != color;
}
