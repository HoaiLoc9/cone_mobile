import 'package:flutter/material.dart';

import 'core/config/api_config.dart';
import 'core/config/app_colors.dart';
import 'core/config/cone_theme.dart';
import 'features/admin/data/admin_models.dart';
import 'features/admin/data/admin_service.dart';
import 'features/admin/presentation/admin_home_screen.dart';
import 'features/admin/presentation/gvcn_home_screen.dart';
import 'features/auth/data/auth_service.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/home/presentation/home_screen.dart';

class QldrlApp extends StatefulWidget {
  const QldrlApp({super.key});

  @override
  State<QldrlApp> createState() => _QldrlAppState();
}

class _QldrlAppState extends State<QldrlApp> {
  final AuthService _authService = AuthService();
  final AdminService _adminService = AdminService();
  AuthSession? _session;
  AdminSession? _adminSession;
  bool _isCheckingSession = true;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      await ApiConfig.loadSavedConfig();
      final savedSession = await _authService.getSavedSession();
      if (savedSession != null && mounted) {
        setState(() {
          _session = savedSession;
          _isCheckingSession = false;
        });
        return;
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isCheckingSession = false);
    }
  }

  void _handleLogin(AuthSession session) {
    setState(() {
      _session = session;
      _adminSession = null;
    });
  }

  void _handleAdminLogin(AdminSession session) {
    setState(() {
      _adminSession = session;
      _session = null;
    });
  }

  Future<void> _handleLogout() async {
    try {
      await _authService.clearSavedSession();
    } catch (_) {}
    if (mounted) {
      setState(() => _session = null);
    }
    _authService.logout().catchError((_) {});
  }

  Future<void> _handleAdminLogout() async {
    if (mounted) {
      setState(() => _adminSession = null);
    }
    _adminService.logout().catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'COne',
      theme: COneTheme.light(),
      home: _isCheckingSession
          ? const Scaffold(
              backgroundColor: AppColors.background,
              body: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            )
          : _session != null
              ? HomeScreen(session: _session!, onLogout: _handleLogout)
              : _adminSession != null
                  ? _adminSession!.admin.isGvcn
                      ? GvcnHomeScreen(
                          session: _adminSession!,
                          onLogout: _handleAdminLogout,
                        )
                      : AdminHomeScreen(
                          session: _adminSession!,
                          onLogout: _handleAdminLogout,
                        )
                  : LoginScreen(
                      authService: _authService,
                      adminService: _adminService,
                      onLoggedIn: _handleLogin,
                      onAdminLoggedIn: _handleAdminLogin,
                    ),
    );
  }
}
