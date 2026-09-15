// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:night_safe_walk/main.dart';
import 'package:night_safe_walk/features/auth/screen/login_screen.dart';

void main() {
  testWidgets('App starts on login and rejects empty credentials', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    expect(find.byType(LoginScreen), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, '로그인'));
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
