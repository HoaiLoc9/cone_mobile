import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../activities/presentation/activity_helpers.dart';
import '../data/appellation_models.dart';
import '../data/appellation_service.dart';
import 'appellation_detail_screen.dart';

class AppellationListScreen extends StatefulWidget {
  const AppellationListScreen({super.key, required this.service});

  final AppellationService service;

  @override
  State<AppellationListScreen> createState() => _AppellationListScreenState();
}

class _AppellationListScreenState extends State<AppellationListScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = true;
  String? _errorMessage;
  List<AppellationItem> _items = [];
  String _filter = 'all'; // 'all', 'open', 'registered'

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await widget.service.fetchAppellations(keyword: _searchController.text.trim());
      setState(() => _items = data.items);
    } on ApiException catch (error) {
      setState(() => _errorMessage = error.message);
    } catch (_) {
      setState(() => _errorMessage = 'Không tải được danh sách danh hiệu.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openDetail(AppellationItem item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AppellationDetailScreen(
          service: widget.service,
          appellationId: item.id,
        ),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final openCount = _items.where((i) => i.isOpen).length;
    final registeredCount = _items.where((i) => i.isRegistered).length;

    final filteredItems = _items.where((item) {
      if (_filter == 'open') return item.isOpen;
      if (_filter == 'registered') return item.isRegistered;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.appBarBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Danh hiệu & Giải thưởng',
          style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.textPrimary, fontSize: 18),
        ),
        actions: [
          IconButton(
            onPressed: _load,
            icon: Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            tooltip: 'Làm mới',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              // Thẻ Hero Vinh danh Sang trọng
              _buildHeroAwardsCard(count: _items.length),
              const SizedBox(height: 16),

              // Ô tìm kiếm danh hiệu
              Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: AppColors.isDark ? 0.2 : 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _load(),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm danh hiệu, Sinh viên 5 tốt...',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 22),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF94A3B8)),
                            onPressed: () {
                              _searchController.clear();
                              _load();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Bộ lọc Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Tất cả (${_items.length})', 'all'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Đang mở xét chọn ($openCount) 🌟', 'open'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Đã nộp hồ sơ ($registeredCount) 📝', 'registered'),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 80),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_errorMessage != null)
                _buildMessage(message: _errorMessage!, isError: true)
              else if (filteredItems.isEmpty)
                _buildEmptyView()
              else
                ...filteredItems.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildAppellationItemCard(item),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroAwardsCard({required int count}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF312E81), Color(0xFF4338CA), Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4338CA).withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFDE68A), Color(0xFFF59E0B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hệ thống Danh hiệu & Giải thưởng',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Vinh danh thành tích Sinh viên 5 Tốt & phong trào',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return InkWell(
      onTap: () => setState(() => _filter = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildAppellationItemCard(AppellationItem item) {
    final registration = item.myRegistration;
    final isRegistered = item.isRegistered;
    final isOpen = item.isOpen;

    final statusColor = isRegistered
        ? const Color(0xFF10B981)
        : (isOpen ? const Color(0xFF2563EB) : const Color(0xFF64748B));

    final statusBg = isRegistered
        ? const Color(0xFFD1FAE5)
        : (isOpen ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9));

    final statusText = isRegistered
        ? (registration?.statusLabel ?? 'ĐÃ NỘP HỒ SƠ')
        : (isOpen ? 'ĐANG MỞ XÉT CHỌN' : 'ĐÃ ĐÓNG XÉT CHỌN');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openDetail(item),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isRegistered
                  ? const Color(0xFF10B981).withValues(alpha: 0.35)
                  : AppColors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: AppColors.isDark ? 0.2 : 0.02),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isRegistered ? Icons.check_circle_rounded : Icons.star_rounded,
                          size: 13,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          statusText.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Row(
                    children: [
                      Icon(Icons.military_tech_rounded, size: 16, color: Color(0xFFD97706)),
                      SizedBox(width: 4),
                      Text(
                        'Cấp Trường',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFFB45309)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFD97706), size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name.isEmpty ? 'Danh hiệu sinh viên' : item.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.textSecondary),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                'Thời hạn: ${compactDate(item.timeStart)} - ${compactDate(item.timeStop)}',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (item.note.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  item.note,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.35),
                ),
              ],
              const SizedBox(height: 12),
              Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Xem tiêu chuẩn & Hồ sơ',
                    style: TextStyle(fontSize: 12.5, color: AppColors.primary, fontWeight: FontWeight.w700),
                  ),
                  Row(
                    children: [
                      Text(
                        isRegistered ? 'Đã ứng tuyển' : (isOpen ? 'Ứng tuyển ngay' : 'Đã hết hạn'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.chevron_right_rounded, size: 16, color: statusColor),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium_outlined, color: AppColors.primary, size: 32),
            ),
            const SizedBox(height: 16),
            const Text(
              'Chưa có danh hiệu nào',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Khi Nhà trường hoặc Đoàn - Hội mở đợt xét chọn danh hiệu (như Sinh viên 5 Tốt), các tiêu chí sẽ hiển thị tại đây.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage({required String message, required bool isError}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.info_outline_rounded,
              color: isError ? const Color(0xFFEF4444) : AppColors.primary,
              size: 44,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isError ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
