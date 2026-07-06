import 'package:flutter/material.dart';

class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.use24Hour = false,
  });

  final ThemeMode themeMode;
  final bool use24Hour;

  AppSettings copyWith({ThemeMode? themeMode, bool? use24Hour}) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    use24Hour: use24Hour ?? this.use24Hour,
  );

  Map<String, dynamic> toMap() => {
    'themeMode': themeMode.name,
    'use24Hour': use24Hour,
  };

  factory AppSettings.fromMap(Map<dynamic, dynamic>? map) => AppSettings(
    themeMode: ThemeMode.values.byName(
      map?['themeMode'] as String? ?? 'system',
    ),
    use24Hour: map?['use24Hour'] as bool? ?? false,
  );
}
