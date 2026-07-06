import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/app_controller.dart';

class StatisticsPage extends ConsumerWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(appControllerProvider).statistics;
    final average = stats.averageWakeMinutes;
    final averageText = average == null
        ? '—'
        : TimeOfDay(hour: average ~/ 60, minute: average % 60).format(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Your progress')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 50)),
                Text(
                  '${stats.currentStreak} day streak',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text('Complete a mission each day to keep it alive.'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.25,
            children: [
              _StatCard(
                icon: Icons.emoji_events_rounded,
                value: '${stats.longestStreak}',
                label: 'Longest streak',
              ),
              _StatCard(
                icon: Icons.wb_sunny_rounded,
                value: '${stats.wakeCount}',
                label: 'Wake-ups',
              ),
              _StatCard(
                icon: Icons.schedule_rounded,
                value: averageText,
                label: 'Average wake time',
              ),
              _StatCard(
                icon: Icons.task_alt_rounded,
                value: '${(stats.completionRate * 100).round()}%',
                label: 'Completion rate',
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Achievements',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          _Achievement(
            title: 'First light',
            subtitle: 'Complete your first mission',
            unlocked: stats.missionsCompleted >= 1,
          ),
          _Achievement(
            title: 'Morning Champion',
            subtitle: 'Build a 7-day streak',
            unlocked: stats.longestStreak >= 7,
          ),
          _Achievement(
            title: 'Unstoppable',
            subtitle: 'Build a 100-day streak',
            unlocked: stats.longestStreak >= 100,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          Text(label),
        ],
      ),
    ),
  );
}

class _Achievement extends StatelessWidget {
  const _Achievement({
    required this.title,
    required this.subtitle,
    required this.unlocked,
  });
  final String title;
  final String subtitle;
  final bool unlocked;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: CircleAvatar(
      child: Icon(unlocked ? Icons.star_rounded : Icons.lock_outline_rounded),
    ),
    title: Text(title),
    subtitle: Text(subtitle),
    trailing: unlocked ? const Icon(Icons.check_circle_rounded) : null,
    enabled: unlocked,
  );
}
