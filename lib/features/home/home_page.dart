import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/models/alarm.dart';
import '../../core/state/app_controller.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(appControllerProvider);
    final active = controller.alarms.where((alarm) => alarm.enabled).toList();
    final next = active.isEmpty ? null : _nextAlarm(active);

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('WakeQuest', style: TextStyle(fontWeight: FontWeight.w800)),
            Text('Win your morning', style: TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Statistics',
            onPressed: () => context.push('/statistics'),
            icon: const Icon(Icons.bar_chart_rounded),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/alarm/new'),
        icon: const Icon(Icons.add_alarm_rounded),
        label: const Text('New alarm'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            _HeroCard(alarm: next),
            const SizedBox(height: 24),
            Row(
              children: [
                Text(
                  'Your alarms',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                Text('${controller.alarms.length} total'),
              ],
            ),
            const SizedBox(height: 12),
            if (controller.alarms.isEmpty)
              const _EmptyAlarms()
            else
              ...controller.alarms.map(
                (alarm) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AlarmCard(alarm: alarm),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Alarm _nextAlarm(List<Alarm> alarms) {
    final now = DateTime.now();
    alarms.sort((a, b) {
      DateTime next(Alarm alarm) {
        var value = DateTime(
          now.year,
          now.month,
          now.day,
          alarm.hour,
          alarm.minute,
        );
        if (!value.isAfter(now)) value = value.add(const Duration(days: 1));
        return value;
      }

      return next(a).compareTo(next(b));
    });
    return alarms.first;
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.alarm});

  final Alarm? alarm;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary, colors.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.nights_stay_rounded, color: colors.onPrimary),
              const SizedBox(width: 8),
              Text(
                alarm == null ? 'No alarm set' : 'NEXT ALARM',
                style: TextStyle(
                  color: colors.onPrimary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            alarm == null
                ? 'Sleep easy'
                : TimeOfDay(
                    hour: alarm!.hour,
                    minute: alarm!.minute,
                  ).format(context),
            style: TextStyle(
              color: colors.onPrimary,
              fontSize: 48,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            alarm == null
                ? 'Create an alarm when you’re ready.'
                : '${alarm!.label}  •  ${_missionLabel(alarm!.mission)}',
            style: TextStyle(color: colors.onPrimary.withValues(alpha: .85)),
          ),
        ],
      ),
    );
  }
}

class _AlarmCard extends ConsumerWidget {
  const _AlarmCard({required this.alarm});
  final Alarm alarm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(appControllerProvider);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => context.push('/alarm/${alarm.id}'),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(_missionIcon(alarm.mission)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      TimeOfDay(
                        hour: alarm.hour,
                        minute: alarm.minute,
                      ).format(context),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${alarm.label} • ${_repeatLabel(alarm)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Switch(
                value: alarm.enabled,
                onChanged: (value) => controller.toggleAlarm(alarm, value),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyAlarms extends StatelessWidget {
  const _EmptyAlarms();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 60),
    child: Column(
      children: [
        Icon(
          Icons.alarm_off_rounded,
          size: 64,
          color: Theme.of(context).colorScheme.outline,
        ),
        const SizedBox(height: 16),
        const Text(
          'Your mornings are a blank canvas.',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        const SizedBox(height: 6),
        const Text('Add an alarm and choose your wake-up mission.'),
      ],
    ),
  );
}

String _repeatLabel(Alarm alarm) {
  if (alarm.repeatDays.length == 7) return 'Every day';
  if (alarm.repeatDays.isEmpty) {
    return alarm.date == null ? 'Once' : DateFormat.MMMd().format(alarm.date!);
  }
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return alarm.repeatDays.map((day) => days[day - 1]).join(', ');
}

String _missionLabel(MissionType mission) => switch (mission) {
  MissionType.math => 'Math mission',
  MissionType.qr => 'QR mission',
  MissionType.walking => 'Walking mission',
  MissionType.pushUps => 'Push-up mission',
};

IconData _missionIcon(MissionType mission) => switch (mission) {
  MissionType.math => Icons.calculate_rounded,
  MissionType.qr => Icons.qr_code_scanner_rounded,
  MissionType.walking => Icons.directions_walk_rounded,
  MissionType.pushUps => Icons.fitness_center_rounded,
};
