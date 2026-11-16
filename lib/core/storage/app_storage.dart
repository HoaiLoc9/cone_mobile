import 'app_storage_io.dart'
    if (dart.library.html) 'app_storage_web.dart';

abstract class AppStorage {
  Future<void> setString(String key, String value);
  Future<String?> getString(String key);
  Future<void> remove(String key);

  static final AppStorage instance = createAppStorage();
}
