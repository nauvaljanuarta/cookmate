// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cookmate2/main.dart';

void main() {
  testWidgets('Cookmate app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CookmateApp());

    // Verify that the app builds without errors
    expect(find.byType(CupertinoApp), findsOneWidget);
    
    // Wait for splash screen to finish
    await tester.pump(const Duration(seconds: 3));
    
    // Pump additional frames to complete any animations
    await tester.pumpAndSettle();
    
    // Verify that the app has loaded by checking for the CupertinoTabBar
    expect(find.byType(CupertinoTabBar), findsOneWidget);
    
    // Verify that at least one of our tab labels is present
    expect(find.text('Home'), findsOneWidget);
  });
}

