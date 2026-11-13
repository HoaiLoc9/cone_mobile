class ApiConfig {
  static const String webUrl = String.fromEnvironment(
    'WEB_URL',
    defaultValue: 'https://cofer.io.vn',
  );

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://cofer.io.vn/api/mobile',
  );

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
