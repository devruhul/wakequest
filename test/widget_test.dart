import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';

import 'package:wakequest/app/app.dart';

void main() {
  late Directory directory;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    directory = await Directory.systemTemp.createTemp('wakequest_test');
    Hive.init(directory.path);
    await Hive.openBox<dynamic>('wakequest');
  });

  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  testWidgets('app opens the alarm dashboard', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: WakeQuestApp()));
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('WakeQuest'), findsOneWidget);
    expect(find.text('Your alarms'), findsOneWidget);
  });
}
