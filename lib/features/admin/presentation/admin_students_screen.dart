import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';
import '../../../shared/widgets/app_state_view.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../data/admin_models.dart';
import '../data/admin_service.dart';

class AdminStudentsScreen extends StatefulWidget {
  const AdminStudentsScreen({super.key, required this.service});

  final AdminService service;

  @override
  State<AdminStudentsScreen> createState() => _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends State<AdminStudentsScreen> {
  final _searchController = TextEditingController();
  late Future<List<AdminStudent>> _future = widget.service.students();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _future = widget.service.students(keyword: _searchController.text);
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
          'Danh sách sinh viên',
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
                hintText: 'Tìm MSSV, họ tên hoặc email...',
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
            child: FutureBuilder<List<AdminStudent>>(
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
                    title: 'Không tải được sinh viên',
                    message: snapshot.error.toString(),
                    actionLabel: 'Thử lại',
                    onAction: _reload,
                  );
                }
                final items = snapshot.data ?? const [];
                if (items.isEmpty) {
                  return AppStateView(
                    icon: Icons.groups_2_outlined,
                    title: 'Chưa có sinh viên',
                    message: 'Không tìm thấy sinh viên trong phạm vi quản lý.',
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
                        _StudentCard(student: items[index]),
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

class _StudentCard extends StatelessWidget {
  const _StudentCard({required this.student});

  final AdminStudent student;

  @override
  Widget build(BuildContext context) {
    final name = student.name.isEmpty ? 'Sinh viên' : student.name;
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'S';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.adaptiveCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.adaptiveBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.adaptiveTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${student.code}${student.email.isNotEmpty ? ' • ${student.email}' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.adaptiveTextSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _InfoChip(
                      label: student.studentClass.isEmpty
                          ? 'Chưa có lớp'
                          : student.studentClass,
                    ),
                    _InfoChip(
                      label: student.department.isEmpty
                          ? 'Chưa có khoa'
                          : student.department,
                    ),
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
