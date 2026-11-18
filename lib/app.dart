import 'package:flutter/material.dart';

import 'core/config/api_config.dart';
import 'core/config/app_colors.dart';
import 'core/config/cone_theme.dart';
import 'core/network/api_client.dart';
import 'core/services/biometric_auth_service.dart';
import 'core/services/local_notification_service.dart';
import 'core/services/theme_service.dart';
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

class _QldrlAppState extends State<QldrlApp> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();
  final AuthService _authService = AuthService();
  final AdminService _adminService = AdminService();
  AuthSession? _session;
  AdminSession? _adminSession;
  bool _isCheckingSession = true;
  bool _isAppLocked = false;
  bool _isAuthenticatingLock = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ApiClient.onSessionExpired = _handleSessionExpired;
    ThemeService.instance.loadTheme();
    ThemeService.instance.addListener(_onThemeChanged);
    LocalNotificationService.instance.initialize().then((_) {
      LocalNotificationService.instance.requestPermissions();
    });
    _restoreSession();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangePlatformBrightness() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAppLockOnResume();
    }
  }

  Future<void> _checkAppLockOnResume() async {
    if (_session == null || _isAuthenticatingLock) return;
    try {
      final isLockEnabled = await BiometricAuthService.instance.isAppLockEnabled();
      if (!isLockEnabled) return;

      if (mounted) setState(() => _isAppLocked = true);
      _isAuthenticatingLock = true;
      final authenticated = await BiometricAuthService.instance.authenticate(
        reason: 'Xác thực sinh trắc học để mở khóa ứng dụng COne',
      );
      if (authenticated && mounted) {
        setState(() => _isAppLocked = false);
      }
    } catch (_) {
    } finally {
      _isAuthenticatingLock = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ApiClient.onSessionExpired = null;
    ThemeService.instance.removeListener(_onThemeChanged);
    super.dispose();
  }

  Future<void> _handleSessionExpired() async {
    if (!mounted) return;
    if (_session == null && _adminSession == null) return;

    try {
      await _authService.clearSavedSession();
      await _adminService.clearSavedSession();
      await BiometricAuthService.instance.clearBiometricTokenOnly();
    } catch (_) {}

    if (mounted) {
      setState(() {
        _session = null;
        _adminSession = null;
      });

      _messengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.danger,
          duration: Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
      final savedAdmin = await _adminService.getSavedSession();
      if (savedAdmin != null && mounted) {
        setState(() {
          _adminSession = savedAdmin;
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
    try {
      await _adminService.clearSavedSession();
    } catch (_) {}
    if (mounted) {
      setState(() => _adminSession = null);
    }
    _adminService.logout().catchError((_) {});
  }

  Widget _buildLockScreen() {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_rounded, color: AppColors.primary, size: 40),
              ),
              const SizedBox(height: 20),
              const Text(
                'Ứng dụng đang khóa',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                'Vui lòng xác thực Face ID hoặc Vân tay để tiếp tục sử dụng COne Mobile.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: Color(0xFF94A3B8), height: 1.4),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _checkAppLockOnResume,
                icon: const Icon(Icons.fingerprint_rounded, size: 22),
                label: const Text('Mở khóa ngay', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: _messengerKey,
      debugShowCheckedModeBanner: false,
      title: 'COne',
      theme: COneTheme.light(),
      darkTheme: COneTheme.dark(),
      themeMode: ThemeService.instance.themeMode,
      builder: (context, child) {
        if (_isAppLocked && _session != null) {
          return _buildLockScreen();
        }
        return child ?? const SizedBox();
      },
      home: _isCheckingSession
          ? Scaffold(
              backgroundColor: AppColors.adaptiveBackground,
              body: const Center(
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
