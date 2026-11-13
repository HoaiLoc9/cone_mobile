import 'package:flutter_test/flutter_test.dart';

import 'package:qldrl_mobile/app.dart';

void main() {
  testWidgets('Login screen renders', (tester) async {
    await tester.pumpWidget(const QldrlApp());

    expect(find.text('COne'), findsOneWidget);
    expect(find.text('Hệ thống Điểm rèn luyện'), findsOneWidget);
    expect(find.text('Sinh viên'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsWidgets);
  });
}
