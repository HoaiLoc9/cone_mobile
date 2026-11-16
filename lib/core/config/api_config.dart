import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const String defaultWebUrl = 'https://cofer.io.vn';
  static const String defaultBaseUrl = 'https://cofer.io.vn/api/mobile';

  static String _webUrl = const String.fromEnvironment(
    'WEB_URL',
    defaultValue: defaultWebUrl,
  );

  static String _baseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: defaultBaseUrl,
  );

  static String get webUrl => _webUrl;
  static String get baseUrl => _baseUrl;

  static void setBaseUrl(String url) {
    var clean = url.trim();
    if (clean.endsWith('/')) {
      clean = clean.substring(0, clean.length - 1);
    }
    if (!clean.endsWith('/api/mobile')) {
      if (clean.endsWith('/api')) {
        clean = '$clean/mobile';
      } else {
        clean = '$clean/api/mobile';
      }
    }
    _baseUrl = clean;
    _webUrl = clean.replaceAll('/api/mobile', '');
  }

  static Future<void> loadSavedConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('custom_api_host');
      if (saved != null && saved.trim().isNotEmpty) {
        setBaseUrl(saved.trim());
      }
    } catch (_) {}
  }

  static Future<void> saveConfig(String host) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_api_host', host.trim());
    setBaseUrl(host.trim());
  }

  static Future<void> resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('custom_api_host');
    _webUrl = defaultWebUrl;
    _baseUrl = defaultBaseUrl;
  }

  static String storageUrl(String path) {
    final value = path.trim();
    if (value.isEmpty) {
      return '';
    }

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    final normalized = value.startsWith('/') ? value : '/$value';
    return '$webUrl$normalized';
  }
}
