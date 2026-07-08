enum MissionType { math, memory, walking, pushUps }

enum MathDifficulty { easy, medium, hard }

class Alarm {
  const Alarm({
    required this.id,
    required this.hour,
    required this.minute,
    required this.label,
    required this.enabled,
    required this.repeatDays,
    required this.mission,
    this.date,
    this.mathDifficulty = MathDifficulty.medium,
    this.mathQuestions = 5,
    this.memoryDigits = 4,
    this.stepGoal = 100,
    this.pushUpGoal = 5,
    this.volume = 1,
    this.vibrate = true,
    this.flash = false,
  });

  final String id;
  final int hour;
  final int minute;
  final String label;
  final bool enabled;
  final Set<int> repeatDays;
  final MissionType mission;
  final DateTime? date;
  final MathDifficulty mathDifficulty;
  final int mathQuestions;
  final int memoryDigits;
  final int stepGoal;
  final int pushUpGoal;
  final double volume;
  final bool vibrate;
  final bool flash;

  bool get repeats => repeatDays.isNotEmpty;

  Alarm copyWith({
    int? hour,
    int? minute,
    String? label,
    bool? enabled,
    Set<int>? repeatDays,
    MissionType? mission,
    DateTime? date,
    MathDifficulty? mathDifficulty,
    int? mathQuestions,
    int? memoryDigits,
    int? stepGoal,
    int? pushUpGoal,
    double? volume,
    bool? vibrate,
    bool? flash,
  }) => Alarm(
    id: id,
    hour: hour ?? this.hour,
    minute: minute ?? this.minute,
    label: label ?? this.label,
    enabled: enabled ?? this.enabled,
    repeatDays: repeatDays ?? this.repeatDays,
    mission: mission ?? this.mission,
    date: date ?? this.date,
    mathDifficulty: mathDifficulty ?? this.mathDifficulty,
    mathQuestions: mathQuestions ?? this.mathQuestions,
    memoryDigits: memoryDigits ?? this.memoryDigits,
    stepGoal: stepGoal ?? this.stepGoal,
    pushUpGoal: pushUpGoal ?? this.pushUpGoal,
    volume: volume ?? this.volume,
    vibrate: vibrate ?? this.vibrate,
    flash: flash ?? this.flash,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'hour': hour,
    'minute': minute,
    'label': label,
    'enabled': enabled,
    'repeatDays': repeatDays.toList(),
    'mission': mission.name,
    'date': date?.toIso8601String(),
    'mathDifficulty': mathDifficulty.name,
    'mathQuestions': mathQuestions,
    'memoryDigits': memoryDigits,
    'stepGoal': stepGoal,
    'pushUpGoal': pushUpGoal,
    'volume': volume,
    'vibrate': vibrate,
    'flash': flash,
  };

  factory Alarm.fromMap(Map<dynamic, dynamic> map) => Alarm(
    id: map['id'] as String,
    hour: map['hour'] as int,
    minute: map['minute'] as int,
    label: map['label'] as String? ?? 'Wake up',
    enabled: map['enabled'] as bool? ?? true,
    repeatDays: Set<int>.from(map['repeatDays'] as Iterable? ?? const []),
    mission: _missionFromName(map['mission'] as String?),
    date: map['date'] == null ? null : DateTime.tryParse(map['date'] as String),
    mathDifficulty: MathDifficulty.values.byName(
      map['mathDifficulty'] as String? ?? 'medium',
    ),
    mathQuestions: map['mathQuestions'] as int? ?? 5,
    memoryDigits: map['memoryDigits'] as int? ?? 4,
    stepGoal: map['stepGoal'] as int? ?? 100,
    pushUpGoal: map['pushUpGoal'] as int? ?? 5,
    volume: (map['volume'] as num?)?.toDouble() ?? 1,
    vibrate: map['vibrate'] as bool? ?? true,
    flash: map['flash'] as bool? ?? false,
  );
}

MissionType _missionFromName(String? value) => switch (value) {
  'memory' => MissionType.memory,
  'walking' => MissionType.walking,
  'pushUps' => MissionType.pushUps,
  // Older WakeQuest builds had a QR mission. Convert those alarms to the new
  // no-printing-needed memory mission instead of failing to load local data.
  'qr' => MissionType.memory,
  _ => MissionType.math,
};
