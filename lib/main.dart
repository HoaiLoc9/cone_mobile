import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'shared/widgets/app_error_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Màn hình hứng lỗi toàn cục: thay thế Red Screen / Grey Screen bằng giao diện COne thân thiện
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return GlobalErrorFallback(details: details);
  };

  FlutterError.onError = (FlutterErrorDetails details) {
    if (kDebugMode) {
      FlutterError.presentError(details);
    } else {
      debugPrint('[COne UI Error] ${details.exceptionAsString()}');
    }
  };

  runApp(const QldrlApp());
}
