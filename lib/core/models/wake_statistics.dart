class WakeStatistics {
  const WakeStatistics({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.wakeCount = 0,
    this.lateCount = 0,
    this.missionsCompleted = 0,
    this.totalWakeMinutes = 0,
    this.lastCompletedDay,
  });

  final int currentStreak;
  final int longestStreak;
  final int wakeCount;
  final int lateCount;
  final int missionsCompleted;
  final int totalWakeMinutes;
  final DateTime? lastCompletedDay;

  double get completionRate =>
      wakeCount == 0 ? 0 : missionsCompleted / wakeCount;
  int? get averageWakeMinutes =>
      wakeCount == 0 ? null : totalWakeMinutes ~/ wakeCount;

  WakeStatistics recordCompletion(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final previous = lastCompletedDay;
    final alreadyToday =
        previous != null &&
        DateTime(previous.year, previous.month, previous.day) == today;
    final consecutive =
        previous != null &&
        today
                .difference(
                  DateTime(previous.year, previous.month, previous.day),
                )
                .inDays ==
            1;
    final streak = alreadyToday
        ? currentStreak
        : consecutive
        ? currentStreak + 1
        : 1;
    return WakeStatistics(
      currentStreak: streak,
      longestStreak: streak > longestStreak ? streak : longestStreak,
      wakeCount: wakeCount + 1,
      lateCount: lateCount,
      missionsCompleted: missionsCompleted + 1,
      totalWakeMinutes: totalWakeMinutes + now.hour * 60 + now.minute,
      lastCompletedDay: today,
    );
  }

  Map<String, dynamic> toMap() => {
    'currentStreak': currentStreak,
    'longestStreak': longestStreak,
    'wakeCount': wakeCount,
    'lateCount': lateCount,
    'missionsCompleted': missionsCompleted,
    'totalWakeMinutes': totalWakeMinutes,
    'lastCompletedDay': lastCompletedDay?.toIso8601String(),
  };

  factory WakeStatistics.fromMap(Map<dynamic, dynamic>? map) => WakeStatistics(
    currentStreak: map?['currentStreak'] as int? ?? 0,
    longestStreak: map?['longestStreak'] as int? ?? 0,
    wakeCount: map?['wakeCount'] as int? ?? 0,
    lateCount: map?['lateCount'] as int? ?? 0,
    missionsCompleted: map?['missionsCompleted'] as int? ?? 0,
    totalWakeMinutes: map?['totalWakeMinutes'] as int? ?? 0,
    lastCompletedDay: map?['lastCompletedDay'] == null
        ? null
        : DateTime.tryParse(map!['lastCompletedDay'] as String),
  );
}
