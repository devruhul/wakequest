# WakeQuest

WakeQuest is an offline-first Android alarm clock that requires a physical or
mental mission before an alarm can be dismissed.

## MVP features

- Multiple one-time or repeating alarms
- Exact Android alarm scheduling and reboot recovery
- Lock-screen/full-screen alarm experience
- Math missions with three difficulty levels
- Generated QR-code missions with camera verification
- Walking missions using the device step counter
- Local Hive persistence
- Streaks, wake statistics, and achievements
- Material 3 light/dark/system themes and 12/24-hour time
- Permission and battery-reliability guidance

## Run

```sh
flutter pub get
flutter run
```

Use a physical Android device to test exact alarms, full-screen intents, camera
scanning, and step counting. Grant notification, exact-alarm, full-screen,
camera, and activity-recognition permissions when requested.

## Verify

```sh
flutter analyze
flutter test
flutter build apk --debug
```

The debug APK is written to `build/app/outputs/flutter-apk/app-debug.apk`.

## Roadmap

Authentication, Firebase sync, premium subscriptions, AI pose/photo missions,
voice missions, widgets, and Wear OS support belong to later releases in the
SRS. The current app deliberately implements the recommended version 1 MVP.
