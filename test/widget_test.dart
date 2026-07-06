import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wakequest/app/app.dart';

void main() {
  testWidgets('App starts correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const WakeQuestApp());

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
