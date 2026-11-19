import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../data/admin_models.dart';
import '../data/admin_service.dart';

class AdminAppellationRegistrationsScreen extends StatefulWidget {
  const AdminAppellationRegistrationsScreen({super.key, required this.service});

  final AdminService service;

  @override
  State<AdminAppellationRegistrationsScreen> createState() =>
      _AdminAppellationRegistrationsScreenState();
}

class _AdminAppellationRegistrationsScreenState
    extends State<AdminAppellationRegistrationsScreen> {
  late Future<List<AdminAppellationRegistration>> _future = widget.service
      .appellationRegistrations();

  void _reload() {
    setState(() => _future = widget.service.appellationRegistrations());
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
          'Hồ sơ danh hiệu',
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
      body: FutureBuilder<List<AdminAppellationRegistration>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SingleChildScrollView(
              child: ShimmerListLoading(itemCount: 5),
            );
          }
          if (snapshot.hasError) {
            return _StateMessage(
              message: snapshot.error.toString(),
              onRetry: _reload,
            );
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return _StateMessage(
              message: 'Chưa có hồ sơ danh hiệu trong phạm vi quản lý.',
              onRetry: _reload,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  _RegistrationCard(item: items[index]),
            ),
          );
        },
      ),
    );
  }
}

class _RegistrationCard extends StatelessWidget {
  const _RegistrationCard({required this.item});

  final AdminAppellationRegistration item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.adaptiveCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.adaptiveBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
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
                  item.appellationName.isEmpty
                      ? 'Danh hiệu'
                      : item.appellationName,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    color: AppColors.adaptiveTextPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.studentCode} • ${item.studentName}',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.adaptiveTextSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.statusLabel,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (item.createdAt.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          item.createdAt,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.adaptiveTextSecondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.workspace_premium_outlined,
              size: 40,
              color: AppColors.adaptiveTextSecondary,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.adaptiveTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: const Text('Tải lại'),
            ),
          ],
        ),
      ),
    );
  }
}
