import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';
import '../../../shared/widgets/app_state_view.dart';
import '../../../shared/widgets/cone_card.dart';
import '../data/activity_model.dart';
import '../data/activity_service.dart';
import 'activity_detail_screen.dart';
import 'activity_helpers.dart';

class RegisteredActivitiesScreen extends StatefulWidget {
  const RegisteredActivitiesScreen({super.key, required this.service});

  final ActivityService service;

  @override
  State<RegisteredActivitiesScreen> createState() =>
      _RegisteredActivitiesScreenState();
}

class _RegisteredActivitiesScreenState
    extends State<RegisteredActivitiesScreen> {
  late Future<List<ActivityItem>> _future =
      widget.service.fetchRegisteredActivities();

  void _reload() {
    setState(() => _future = widget.service.fetchRegisteredActivities());
  }

  Future<void> _openDetail(ActivityItem item) async {
    final updated = await Navigator.of(context).push<ActivityItem>(
      MaterialPageRoute(
        builder: (_) =>
            ActivityDetailScreen(service: widget.service, activityId: item.id),
      ),
    );
    if (updated != null) {
      _reload();
    }
  }

  String _timeRange(ActivityItem item) {
    return '${formatDateTime(item.timeStart)} - ${formatDateTime(item.timeStop)}';
  }

  String _points(double? points) {
    if (points == null) return '0';
    if (points == points.roundToDouble()) return points.toInt().toString();
    return points.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Hoạt động đã đăng ký',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [IconButton(onPressed: _reload, icon: const Icon(Icons.refresh))],
      ),
      body: FutureBuilder<List<ActivityItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return AppStateView(
              icon: Icons.error_outline,
              title: 'Chưa tải được hoạt động',
              message: snapshot.error.toString(),
              actionLabel: 'Thử lại',
              onAction: _reload,
            );
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return const AppStateView(
              icon: Icons.event_busy_outlined,
              title: 'Chưa đăng ký hoạt động',
              message:
                  'Bạn có thể vào mục Hoạt động để đăng ký tham gia.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.builder(
              padding: const EdgeInsets.all(18),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: COneCard(
                    onTap: () => _openDetail(item),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            _StatusPill(item.registrationStatusLabel),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _timeRange(item),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${item.location.isEmpty ? 'Chưa có địa điểm' : item.location} • ${_points(item.points)} điểm',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.isEmpty ? 'Đã đăng ký' : label,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
