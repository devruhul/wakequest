import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/state/app_controller.dart';
import '../core/notifications/alarm_notification_service.dart';
import 'router.dart';

class WakeQuestApp extends ConsumerWidget {
  const WakeQuestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appControllerProvider).settings;
    AlarmNotificationService.instance.onAlarmSelected = (id) =>
        appRouter.go('/ring/$id');
    final seed = const Color(0xFF6558D3);

    ThemeData theme(Brightness brightness) {
      final scheme = ColorScheme.fromSeed(
        seedColor: seed,
        brightness: brightness,
      );
      return ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        textTheme: GoogleFonts.nunitoTextTheme(
          ThemeData(brightness: brightness).textTheme,
        ),
        scaffoldBackgroundColor: scheme.surface,
        cardTheme: CardThemeData(
          elevation: 0,
          color: scheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      );
    }

    return MaterialApp.router(
      title: 'WakeQuest',
      debugShowCheckedModeBanner: false,
      theme: theme(Brightness.light),
      darkTheme: theme(Brightness.dark),
      themeMode: settings.themeMode,
      routerConfig: appRouter,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(alwaysUse24HourFormat: settings.use24Hour),
        child: child!,
      ),
    );
  }
}
