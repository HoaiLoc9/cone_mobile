import '../storage/app_storage.dart';

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
      final saved = await AppStorage.instance.getString('custom_api_host');
      if (saved != null && saved.trim().isNotEmpty) {
        setBaseUrl(saved.trim());
      }
    } catch (_) {}
  }

  static Future<void> saveConfig(String host) async {
    try {
      await AppStorage.instance.setString('custom_api_host', host.trim());
      setBaseUrl(host.trim());
    } catch (_) {}
  }

  static Future<void> resetToDefault() async {
    try {
      await AppStorage.instance.remove('custom_api_host');
      _webUrl = defaultWebUrl;
      _baseUrl = defaultBaseUrl;
    } catch (_) {}
  }

  static String storageUrl(String path) {
    var value = path.trim();
    if (value.isEmpty) {
      return '';
    }

    // Ignore placeholder svg images to avoid NetworkImage decoding crashes
    if (value.contains('default-avatar.svg') || value.contains('no-image.svg')) {
      return '';
    }

    // Rewrite localhost/127.0.0.1 from backend to the actual mobile webUrl
    if (value.startsWith('http://localhost/') || value.startsWith('http://localhost:80/')) {
      value = value.replaceFirst(RegExp(r'^http:\/\/localhost(:80)?'), webUrl);
    } else if (value.startsWith('http://127.0.0.1/') || value.startsWith('http://127.0.0.1:80/')) {
      value = value.replaceFirst(RegExp(r'^http:\/\/127\.0\.0\.1(:80)?'), webUrl);
    }

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    final normalized = value.startsWith('/') ? value : '/$value';
    return '$webUrl$normalized';
  }
}
