import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/alarm.dart';

class AlarmNotificationService {
  AlarmNotificationService._();

  static final instance = AlarmNotificationService._();
  final plugin = FlutterLocalNotificationsPlugin();
  String? initialAlarmId;
  void Function(String alarmId)? onAlarmSelected;

  Future<void> initialize() async {
    tz.initializeTimeZones();
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
    } catch (_) {
      // tz.local remains UTC only on unsupported desktop test platforms.
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        initialAlarmId = response.payload;
        if (response.payload != null) onAlarmSelected?.call(response.payload!);
      },
    );
    final launch = await plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      initialAlarmId = launch?.notificationResponse?.payload;
    }
  }

  Future<void> requestPermissions() async {
    if (!Platform.isAndroid) return;
    final android = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
    await android?.requestFullScreenIntentPermission();
  }

  Future<void> schedule(Alarm alarm) async {
    await cancel(alarm.id);
    if (!alarm.enabled) return;

    if (alarm.repeatDays.isEmpty) {
      final time = _nextOneOff(alarm);
      await plugin.zonedSchedule(
        id: _notificationId(alarm.id, 0),
        title: alarm.label,
        body: 'Complete your ${_missionName(alarm.mission)} mission to dismiss',
        scheduledDate: time,
        notificationDetails: _detailsFor(alarm),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        payload: alarm.id,
      );
      return;
    }

    for (final weekday in alarm.repeatDays) {
      await plugin.zonedSchedule(
        id: _notificationId(alarm.id, weekday),
        title: alarm.label,
        body: 'Complete your ${_missionName(alarm.mission)} mission to dismiss',
        scheduledDate: _nextWeekday(alarm, weekday),
        notificationDetails: _detailsFor(alarm),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: alarm.id,
      );
    }
  }

  Future<void> cancel(String alarmId) async {
    await plugin.cancel(id: _notificationId(alarmId, 0));
    for (var day = 1; day <= 7; day++) {
      await plugin.cancel(id: _notificationId(alarmId, day));
    }
  }

  Future<void> showTest(Alarm alarm) => plugin.show(
    id: _notificationId(alarm.id, 9),
    title: alarm.label,
    body: 'Test alarm — tap to begin your mission',
    notificationDetails: _detailsFor(alarm),
    payload: alarm.id,
  );

  NotificationDetails _detailsFor(Alarm alarm) => NotificationDetails(
    android: AndroidNotificationDetails(
      'wakequest_alarms_${alarm.vibrate}_${alarm.flash}',
      'WakeQuest alarms',
      channelDescription: 'Urgent alarms that require a mission to dismiss',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      ongoing: true,
      autoCancel: false,
      playSound: true,
      enableVibration: alarm.vibrate,
      enableLights: alarm.flash,
      ledColor: alarm.flash ? const Color(0xFFFFFFFF) : null,
      visibility: NotificationVisibility.public,
    ),
  );

  tz.TZDateTime _nextOneOff(Alarm alarm) {
    final now = tz.TZDateTime.now(tz.local);
    final selected = alarm.date;
    var result = selected == null
        ? tz.TZDateTime(
            tz.local,
            now.year,
            now.month,
            now.day,
            alarm.hour,
            alarm.minute,
          )
        : tz.TZDateTime(
            tz.local,
            selected.year,
            selected.month,
            selected.day,
            alarm.hour,
            alarm.minute,
          );
    if (!result.isAfter(now)) result = result.add(const Duration(days: 1));
    return result;
  }

  tz.TZDateTime _nextWeekday(Alarm alarm, int weekday) {
    var result = _nextOneOff(alarm);
    while (result.weekday != weekday) {
      result = result.add(const Duration(days: 1));
    }
    return result;
  }

  int _notificationId(String id, int suffix) =>
      (id.hashCode.abs() % 100000000) * 10 + suffix;

  String _missionName(MissionType mission) => switch (mission) {
    MissionType.math => 'math',
    MissionType.qr => 'QR scan',
    MissionType.walking => 'walking',
  };
}
