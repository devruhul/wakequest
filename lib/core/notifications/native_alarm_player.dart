import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NativeAlarmPlayer {
  NativeAlarmPlayer._();

  static const _channel = MethodChannel('com.ruhulamin.wakequest/alarm_player');

  static Future<void> start({required bool vibrate}) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    await _channel.invokeMethod<void>('start', {'vibrate': vibrate});
  }

  static Future<void> stop() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    await _channel.invokeMethod<void>('stop');
  }
}
