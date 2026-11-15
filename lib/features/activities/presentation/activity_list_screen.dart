import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/network/api_exception.dart';
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
        keyword: _searchController.text,
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
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        title: const Text(
          'Hoạt động',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _load(refresh: true),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(onSearch: () => _load(refresh: true))),
              SliverToBoxAdapter(child: _buildFilters()),
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_errorMessage != null)
                SliverFillRemaining(child: _Message(message: _errorMessage!, isError: true))
              else if (_items.isEmpty)
                const SliverFillRemaining(
                  child: _Message(message: 'Chưa có hoạt động phù hợp.', isError: false),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                  sliver: SliverList.separated(
                    itemCount: _items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
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
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                    child: OutlinedButton(
                      onPressed: _isLoadingMore ? null : () => _load(refresh: false),
                      child: _isLoadingMore
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Tải thêm'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader({required VoidCallback onSearch}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.darkBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Khám phá hoạt động sinh viên',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cập nhật liên tục các hoạt động rèn luyện mới nhất.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.82)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => onSearch(),
              decoration: InputDecoration(
                hintText: 'Tìm hoạt động...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: onSearch,
                  icon: const Icon(Icons.arrow_forward_rounded),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      child: Row(
        children: [
          _buildFilterChip(label: 'Tất cả', value: ''),
          const SizedBox(width: 8),
          _buildFilterChip(label: 'Đang mở', value: 'open'),
          const SizedBox(width: 8),
          _buildFilterChip(label: 'Đã đóng', value: 'closed'),
        ],
      ),
    );
  }

  Widget _buildFilterChip({required String label, required String value}) {
    final selected = _status == value;
    return ChoiceChip(
      selected: selected,
      label: Text(label),
      onSelected: (_) {
        setState(() => _status = value);
        _load(refresh: true);
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.16),
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: FontWeight.w800,
      ),
      side: BorderSide(
        color: selected ? AppColors.primary : AppColors.textSecondary.withValues(alpha: 0.18),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isError ? AppColors.danger : AppColors.textSecondary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
