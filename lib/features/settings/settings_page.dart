import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/notifications/alarm_notification_service.dart';
import '../../core/state/app_controller.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(appControllerProvider);
    final settings = controller.settings;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text('Theme'),
                  trailing: DropdownButton<ThemeMode>(
                    value: settings.themeMode,
                    underline: const SizedBox(),
                    items: ThemeMode.values
                        .map(
                          (mode) => DropdownMenuItem(
                            value: mode,
                            child: Text(switch (mode) {
                              ThemeMode.system => 'System',
                              ThemeMode.light => 'Light',
                              ThemeMode.dark => 'Dark',
                            }),
                          ),
                        )
                        .toList(),
                    onChanged: (mode) {
                      if (mode != null) {
                        controller.updateSettings(
                          settings.copyWith(themeMode: mode),
                        );
                      }
                    },
                  ),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.schedule_rounded),
                  title: const Text('24-hour time'),
                  value: settings.use24Hour,
                  onChanged: (value) => controller.updateSettings(
                    settings.copyWith(use24Hour: value),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Reliability', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: const Text('Alarm permissions'),
                  subtitle: const Text(
                    'Notifications, exact alarms, and full-screen display',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    await AlarmNotificationService.instance
                        .requestPermissions();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.battery_saver_outlined),
                  title: const Text('Battery optimization'),
                  subtitle: const Text(
                    'Allow WakeQuest to run reliably in the background',
                  ),
                  trailing: const Icon(Icons.open_in_new_rounded),
                  onTap: openAppSettings,
                ),
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings_outlined),
                  title: const Text('Manage all permissions'),
                  trailing: const Icon(Icons.open_in_new_rounded),
                  onTap: openAppSettings,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: const ListTile(
              leading: Icon(Icons.info_outline_rounded),
              title: Text('WakeQuest'),
              subtitle: Text('Version 1.0.0 • Offline-first MVP'),
            ),
          ),
        ],
      ),
    );
  }
}
