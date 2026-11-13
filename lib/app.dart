import 'package:flutter/material.dart';

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
    await _authService.logout();
    if (mounted) {
      setState(() => _session = null);
    }
  }

  Future<void> _handleAdminLogout() async {
    await _adminService.logout();
    if (mounted) {
      setState(() => _adminSession = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'COne',
      theme: COneTheme.light(),
      home: _session != null
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
