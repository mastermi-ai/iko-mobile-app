import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:iko_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const IKOApp());

    // Verify that login screen is shown
    expect(find.text('IKO'), findsOneWidget);
    expect(find.text('Mobile Sales'), findsOneWidget);
  });
}
