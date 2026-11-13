import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';
import '../../../shared/widgets/app_state_view.dart';
import '../../../shared/widgets/cone_card.dart';
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
      appBar: AppBar(
        title: const Text('Hoạt động CTSV'),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _reload(),
              decoration: InputDecoration(
                hintText: 'Tìm tên hoạt động',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _reload();
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<AdminActivity>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
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
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
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
    return COneCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: .11),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Icon(
                  Icons.event_available_outlined,
                  color: AppColors.purple,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.name.isEmpty ? 'Hoạt động' : activity.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activity.semester.isEmpty
                          ? activity.department
                          : activity.semester,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(label: _statusLabel(activity.status)),
              if (activity.timeStart.isNotEmpty)
                _InfoChip(label: 'Bắt đầu: ${activity.timeStart}'),
              if (activity.points != null)
                _InfoChip(label: '${activity.points!.toStringAsFixed(1)} điểm'),
              if (activity.maxRegistrations > 0)
                _InfoChip(label: 'Tối đa ${activity.maxRegistrations} SV'),
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

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
