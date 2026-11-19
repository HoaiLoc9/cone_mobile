import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';

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
    final activeModules = modules.where((m) => m.ready).toList();

    return Scaffold(
      backgroundColor: AppColors.adaptiveBackground,
      appBar: AppBar(
        backgroundColor: AppColors.adaptiveAppBarBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: AppColors.adaptiveTextPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.adaptiveBorder, height: 1),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            if (subtitle.isNotEmpty) ...[
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.adaptiveTextSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
            ],
            Container(
              decoration: BoxDecoration(
                color: AppColors.adaptiveCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.adaptiveBorder),
              ),
              child: Column(
                children: List.generate(activeModules.length, (index) {
                  final module = activeModules[index];
                  return Column(
                    children: [
                      InkWell(
                        onTap: module.onTap,
                        borderRadius: BorderRadius.vertical(
                          top: index == 0 ? const Radius.circular(20) : Radius.zero,
                          bottom: index == activeModules.length - 1
                              ? const Radius.circular(20)
                              : Radius.zero,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  module.icon,
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
                                      module.name,
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.adaptiveTextPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      module.description,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.adaptiveTextSecondary,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                                color: AppColors.adaptiveTextSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (index < activeModules.length - 1)
                        Divider(
                          height: 1,
                          indent: 68,
                          endIndent: 14,
                          color: AppColors.adaptiveBorder,
                        ),
                    ],
                  );
                }),
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
