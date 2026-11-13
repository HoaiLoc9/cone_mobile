import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';
import '../../../shared/widgets/app_state_view.dart';
import '../../../shared/widgets/cone_card.dart';
import '../../activities/data/activity_service.dart';
import '../../drl/data/drl_models.dart';
import '../../drl/data/drl_service.dart';
import '../../notifications/data/notification_service.dart';

class StudentStatsScreen extends StatefulWidget {
  const StudentStatsScreen({
    super.key,
    required this.drlService,
    required this.activityService,
    required this.notificationService,
  });

  final DrlService drlService;
  final ActivityService activityService;
  final NotificationService notificationService;

  @override
  State<StudentStatsScreen> createState() => _StudentStatsScreenState();
}

class _StudentStatsScreenState extends State<StudentStatsScreen> {
  late Future<_StatsData> _future = _load();

  Future<_StatsData> _load() async {
    final results = await Future.wait<Object>([
      widget.drlService.fetchSummary(),
      widget.activityService.fetchRegisteredActivities(),
      widget.notificationService.fetchUnreadCount(),
    ]);
    return _StatsData(
      summary: results[0] as DrlSummary,
      registeredCount: (results[1] as List).length,
      unreadNotifications: results[2] as int,
    );
  }

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Thống kê cá nhân',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [IconButton(onPressed: _reload, icon: const Icon(Icons.refresh))],
      ),
      body: FutureBuilder<_StatsData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return AppStateView(
              icon: Icons.error_outline,
              title: 'Chưa tải được thống kê',
              message: snapshot.error.toString(),
              actionLabel: 'Thử lại',
              onAction: _reload,
            );
          }
          final data = snapshot.data!;
          final currentSemester = data.summary.semesterSummaries.isEmpty
              ? null
              : data.summary.semesterSummaries.first;
          final score = currentSemester?.totalPoints ?? data.summary.totalPoints;
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                _HeroStat(score: score),
                const SizedBox(height: 14),
                _StatTile(
                  icon: Icons.event_available_outlined,
                  title: 'Hoạt động đã đăng ký',
                  value: data.registeredCount.toString(),
                ),
                _StatTile(
                  icon: Icons.notifications_none_rounded,
                  title: 'Thông báo chưa đọc',
                  value: data.unreadNotifications.toString(),
                ),
                _StatTile(
                  icon: Icons.school_outlined,
                  title: 'Số học kỳ có dữ liệu',
                  value: data.summary.semesterSummaries.length.toString(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatsData {
  const _StatsData({
    required this.summary,
    required this.registeredCount,
    required this.unreadNotifications,
  });

  final DrlSummary summary;
  final int registeredCount;
  final int unreadNotifications;
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    return COneCard(
      padding: const EdgeInsets.all(24),
      gradient: const LinearGradient(
        colors: [AppColors.darkBlue, AppColors.primary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Điểm hoạt động hiện tại',
            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            score.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tổng hợp từ dữ liệu rèn luyện và hoạt động đã tham gia.',
            style: TextStyle(color: Colors.white70, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: COneCard(
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}
