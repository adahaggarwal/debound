import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:debound/main.dart';

void main() {
  testWidgets('App should start with splash screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the splash screen is displayed
    expect(find.text('Debound'), findsOneWidget);
    expect(find.text('Weather & News Dashboard'), findsOneWidget);
    
    // Verify that the loading indicator is present
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}