// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:market_explorer_frontend/main.dart';

void main() {
  testWidgets('앱이 정상적으로 빌드되는지 확인', (WidgetTester tester) async {
    // 앱을 빌드하고 프레임을 트리거합니다.
    await tester.pumpWidget(const MyApp());

    // 앱이 정상적으로 빌드되었는지 확인합니다.
    // MaterialApp.router가 사용되므로 Material 위젯이 있는지 확인
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
