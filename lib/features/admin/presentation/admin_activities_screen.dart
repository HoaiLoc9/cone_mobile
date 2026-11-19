import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';
import '../../../shared/widgets/app_state_view.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../data/admin_models.dart';
import '../data/admin_service.dart';

class AdminActivitiesScreen extends StatefulWidget {
  const AdminActivitiesScreen({super.key, required this.service});

  final AdminService service;

  @override
  State<AdminActivitiesScreen> createState() => _AdminActivitiesScreenState();
}

class _AdminActivitiesScreenState extends State<AdminActivitiesScreen> {
  final _searchController = TextEditingController();
  late Future<List<AdminActivity>> _future = widget.service.activities();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _future = widget.service.activities(keyword: _searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adaptiveBackground,
      appBar: AppBar(
        backgroundColor: AppColors.adaptiveAppBarBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Quản lý hoạt động',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: AppColors.adaptiveTextPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: Icon(Icons.refresh_rounded, color: AppColors.adaptiveTextSecondary),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.adaptiveBorder, height: 1),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _reload(),
              style: TextStyle(color: AppColors.adaptiveTextPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Tìm tên hoạt động...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _reload();
                  },
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<AdminActivity>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SingleChildScrollView(
                    child: ShimmerListLoading(itemCount: 5),
                  );
                }
                if (snapshot.hasError) {
                  return AppStateView(
                    icon: Icons.wifi_off_rounded,
                    title: 'Không tải được hoạt động',
                    message: snapshot.error.toString(),
                    actionLabel: 'Thử lại',
                    onAction: _reload,
                  );
                }
                final items = snapshot.data ?? const [];
                if (items.isEmpty) {
                  return AppStateView(
                    icon: Icons.event_busy_outlined,
                    title: 'Chưa có hoạt động',
                    message: 'Không tìm thấy hoạt động trong phạm vi quản lý.',
                    actionLabel: 'Tải lại',
                    onAction: _reload,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) =>
                        _ActivityCard(activity: items[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity});

  final AdminActivity activity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.adaptiveCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.adaptiveBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.event_available_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.name.isEmpty ? 'Hoạt động' : activity.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.adaptiveTextPrimary,
                      ),
                    ),
                    if (activity.semester.isNotEmpty || activity.department.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        activity.semester.isEmpty
                            ? activity.department
                            : activity.semester,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.adaptiveTextSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _StatusBadge(label: _statusLabel(activity.status)),
              if (activity.points != null)
                _InfoChip(label: '+${activity.points!.toStringAsFixed(activity.points! % 1 == 0 ? 0 : 1)} điểm'),
              if (activity.maxRegistrations > 0)
                _InfoChip(label: 'Tối đa ${activity.maxRegistrations} SV'),
              if (activity.timeStart.isNotEmpty)
                _InfoChip(label: activity.timeStart),
            ],
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    return switch (status) {
      'planned' => 'Dự kiến',
      'registration_closed' => 'Đóng đăng ký',
      'running' => 'Đang diễn ra',
      'completed' => 'Đã kết thúc',
      _ => 'Hoạt động',
    };
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: AppColors.adaptiveCardSubtle,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.adaptiveBorder),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.adaptiveTextSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
