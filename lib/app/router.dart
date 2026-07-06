import 'package:go_router/go_router.dart';

import '../core/notifications/alarm_notification_service.dart';
import '../features/alarm/alarm_editor_page.dart';
import '../features/alarm/ringing_alarm_page.dart';
import '../features/home/home_page.dart';
import '../features/settings/settings_page.dart';
import '../features/statistics/statistics_page.dart';

final appRouter = GoRouter(
  initialLocation: AlarmNotificationService.instance.initialAlarmId == null
      ? '/'
      : '/ring/${AlarmNotificationService.instance.initialAlarmId}',
  routes: [
    GoRoute(path: '/', builder: (_, _) => const HomePage()),
    GoRoute(path: '/alarm/new', builder: (_, _) => const AlarmEditorPage()),
    GoRoute(
      path: '/alarm/:id',
      builder: (_, state) => AlarmEditorPage(id: state.pathParameters['id']),
    ),
    GoRoute(
      path: '/ring/:id',
      builder: (_, state) =>
          RingingAlarmPage(alarmId: state.pathParameters['id']!),
    ),
    GoRoute(path: '/statistics', builder: (_, _) => const StatisticsPage()),
    GoRoute(path: '/settings', builder: (_, _) => const SettingsPage()),
  ],
);
