import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../data/activity_model.dart';
import '../data/activity_service.dart';
import 'activity_card.dart';
import 'activity_detail_screen.dart';

class ActivityListScreen extends StatefulWidget {
  const ActivityListScreen({super.key, required this.service});

  final ActivityService service;

  @override
  State<ActivityListScreen> createState() => _ActivityListScreenState();
}

class _ActivityListScreenState extends State<ActivityListScreen> {
  final _searchController = TextEditingController();
  final List<ActivityItem> _items = [];
  int _page = 1;
  int _lastPage = 1;
  String _status = '';
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load(refresh: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({required bool refresh}) async {
    if (refresh) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _page = 1;
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final result = await widget.service.fetchActivities(
        page: refresh ? 1 : _page + 1,
        keyword: _searchController.text.trim(),
        status: _status,
      );
      setState(() {
        if (refresh) {
          _items
            ..clear()
            ..addAll(result.items);
        } else {
          _items.addAll(result.items);
        }
        _page = result.currentPage;
        _lastPage = result.lastPage;
      });
    } on ApiException catch (error) {
      setState(() => _errorMessage = error.message);
    } catch (_) {
      setState(() => _errorMessage = 'Không tải được danh sách hoạt động.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _openDetail(ActivityItem activity) async {
    final updated = await Navigator.of(context).push<ActivityItem>(
      MaterialPageRoute(
        builder: (_) => ActivityDetailScreen(service: widget.service, activityId: activity.id),
      ),
    );

    if (updated != null && mounted) {
      final index = _items.indexWhere((item) => item.id == updated.id);
      if (index >= 0) {
        setState(() => _items[index] = updated);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adaptiveBackground,
      appBar: AppBar(
        backgroundColor: AppColors.appBarBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Hoạt động sinh viên',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: AppColors.adaptiveTextPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _load(refresh: true),
            icon: Icon(Icons.refresh_rounded, color: AppColors.adaptiveTextSecondary),
            tooltip: 'Làm mới',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.adaptiveBorder, height: 1),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _load(refresh: true),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                  child: Column(
                    children: [
                      // Thanh tìm kiếm cao cấp
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.adaptiveCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.adaptiveBorder),
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
                          onSubmitted: (_) => _load(refresh: true),
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm hoạt động, sự kiện...',
                            hintStyle: TextStyle(color: AppColors.adaptiveTextSecondary, fontSize: 13.5),
                            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 22),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF94A3B8)),
                                    onPressed: () {
                                      _searchController.clear();
                                      _load(refresh: true);
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Bộ lọc nhanh (Tất cả, Đang mở, Đã đóng)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('Tất cả', ''),
                            const SizedBox(width: 8),
                            _buildFilterChip('Đang mở đăng ký 🟢', 'open'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Đã đóng đăng ký', 'closed'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_isLoading)
                const SliverToBoxAdapter(
                  child: ShimmerListLoading(itemCount: 4),
                )
              else if (_errorMessage != null)
                SliverFillRemaining(
                  child: _buildEmptyOrError(
                    icon: Icons.error_outline_rounded,
                    title: 'Đã xảy ra lỗi',
                    message: _errorMessage!,
                    isError: true,
                    onRetry: () => _load(refresh: true),
                  ),
                )
              else if (_items.isEmpty)
                SliverFillRemaining(
                  child: _buildEmptyOrError(
                    icon: Icons.event_busy_rounded,
                    title: 'Chưa có hoạt động phù hợp',
                    message: 'Hiện chưa có hoạt động nào trong danh mục hoặc từ khóa tìm kiếm này.',
                    isError: false,
                    onRetry: () {
                      _searchController.clear();
                      setState(() => _status = '');
                      _load(refresh: true);
                    },
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  sliver: SliverList.separated(
                    itemCount: _items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final activity = _items[index];
                      return ActivityCard(
                        activity: activity,
                        onTap: () => _openDetail(activity),
                      );
                    },
                  ),
                ),

              if (!_isLoading && _page < _lastPage)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      onPressed: _isLoadingMore ? null : () => _load(refresh: false),
                      child: _isLoadingMore
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Xem thêm hoạt động',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _status == value;
    return InkWell(
      onTap: () {
        setState(() => _status = value);
        _load(refresh: true);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.adaptiveCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.adaptiveBorder,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.adaptiveTextSecondary,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyOrError({
    required IconData icon,
    required String title,
    required String message,
    required bool isError,
    required VoidCallback onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: isError
                    ? const Color(0xFFFEE2E2)
                    : (AppColors.isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF)),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isError ? const Color(0xFFEF4444) : AppColors.primary,
                size: 34,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.adaptiveTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Làm mới'),
            ),
          ],
        ),
      ),
    );
  }
}
