import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';
import '../../../shared/widgets/cone_card.dart';
import '../../../shared/widgets/section_header.dart';

class AdminServiceModulesScreen extends StatelessWidget {
  const AdminServiceModulesScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.modules,
  });

  final String title;
  final String subtitle;
  final List<AdminServiceModule> modules;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            SectionHeader(title: title, subtitle: subtitle),
            const SizedBox(height: 14),
            for (final module in modules)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: COneCard(
                  onTap: module.onTap,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: module.ready
                              ? AppColors.success.withValues(alpha: .12)
                              : AppColors.warning.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          module.icon,
                          color: module.ready
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              module.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              module.description,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _Chip(
                                  label: module.ready
                                      ? 'Đã có API mobile'
                                      : 'Thiếu API mobile',
                                  ready: module.ready,
                                ),
                                if (module.api.isNotEmpty)
                                  _Chip(label: module.api, ready: module.ready),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class AdminServiceModule {
  const AdminServiceModule({
    required this.name,
    required this.description,
    required this.icon,
    required this.api,
    required this.ready,
    this.onTap,
  });

  final String name;
  final String description;
  final IconData icon;
  final String api;
  final bool ready;
  final VoidCallback? onTap;
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.ready});

  final String label;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ready
            ? AppColors.primarySoft
            : AppColors.warning.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: ready ? AppColors.primary : AppColors.warning,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}
