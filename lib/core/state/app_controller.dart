import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hive/hive.dart';

import '../models/alarm.dart';
import '../models/app_settings.dart';
import '../models/wake_statistics.dart';
import '../notifications/alarm_notification_service.dart';

final appControllerProvider = ChangeNotifierProvider<AppController>(
  (ref) => AppController(),
);

class AppController extends ChangeNotifier {
  AppController() {
    _load();
  }

  final Box<dynamic> _box = Hive.box<dynamic>('wakequest');
  List<Alarm> alarms = [];
  AppSettings settings = const AppSettings();
  WakeStatistics statistics = const WakeStatistics();

  void _load() {
    final stored = _box.get('alarms') as List<dynamic>? ?? const [];
    alarms =
        stored
            .map(
              (value) =>
                  Alarm.fromMap(Map<dynamic, dynamic>.from(value as Map)),
            )
            .toList()
          ..sort(_sortAlarms);
    settings = AppSettings.fromMap(_map(_box.get('settings')));
    statistics = WakeStatistics.fromMap(_map(_box.get('statistics')));
  }

  Map<dynamic, dynamic>? _map(dynamic value) =>
      value is Map ? Map<dynamic, dynamic>.from(value) : null;

  Alarm? alarmById(String id) {
    for (final alarm in alarms) {
      if (alarm.id == id) return alarm;
    }
    return null;
  }

  Future<void> saveAlarm(Alarm alarm) async {
    final index = alarms.indexWhere((item) => item.id == alarm.id);
    if (index < 0) {
      alarms.add(alarm);
    } else {
      alarms[index] = alarm;
    }
    alarms.sort(_sortAlarms);
    await _persistAlarms();
    await AlarmNotificationService.instance.schedule(alarm);
    notifyListeners();
  }

  Future<void> toggleAlarm(Alarm alarm, bool enabled) =>
      saveAlarm(alarm.copyWith(enabled: enabled));

  Future<void> deleteAlarm(Alarm alarm) async {
    alarms.removeWhere((item) => item.id == alarm.id);
    await _persistAlarms();
    await AlarmNotificationService.instance.cancel(alarm.id);
    notifyListeners();
  }

  Future<void> updateSettings(AppSettings value) async {
    settings = value;
    await _box.put('settings', value.toMap());
    notifyListeners();
  }

  Future<void> completeMission(String alarmId) async {
    statistics = statistics.recordCompletion(DateTime.now());
    await _box.put('statistics', statistics.toMap());
    await AlarmNotificationService.instance.cancel(alarmId);
    final alarm = alarmById(alarmId);
    if (alarm != null && !alarm.repeats) {
      final index = alarms.indexOf(alarm);
      alarms[index] = alarm.copyWith(enabled: false);
      await _persistAlarms();
    }
    notifyListeners();
  }

  Future<void> _persistAlarms() =>
      _box.put('alarms', alarms.map((alarm) => alarm.toMap()).toList());

  int _sortAlarms(Alarm a, Alarm b) =>
      (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute);
}
