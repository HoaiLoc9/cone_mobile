import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:qldrl_mobile/app.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Login screen renders', (tester) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const QldrlApp());
    await tester.pumpAndSettle();

    expect(find.text('COne'), findsOneWidget);
    expect(find.text('Hệ thống Điểm rèn luyện sinh viên'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsWidgets);
  });
}
