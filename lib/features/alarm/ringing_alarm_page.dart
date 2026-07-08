import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/models/alarm.dart';
import '../../core/notifications/native_alarm_player.dart';
import '../../core/state/app_controller.dart';
import 'push_up_mission.dart';

class RingingAlarmPage extends ConsumerStatefulWidget {
  const RingingAlarmPage({super.key, required this.alarmId});
  final String alarmId;

  @override
  ConsumerState<RingingAlarmPage> createState() => _RingingAlarmPageState();
}

class _RingingAlarmPageState extends ConsumerState<RingingAlarmPage> {
  bool _started = false;

  @override
  Widget build(BuildContext context) {
    final alarm = ref.watch(appControllerProvider).alarmById(widget.alarmId);
    if (alarm == null) {
      return Scaffold(
        body: Center(
          child: FilledButton(
            onPressed: () => context.go('/'),
            child: const Text('Back to alarms'),
          ),
        ),
      );
    }
    if (!_started) {
      _started = true;
      NativeAlarmPlayer.start(vibrate: alarm.vibrate);
    }
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                Text(
                  TimeOfDay(
                    hour: alarm.hour,
                    minute: alarm.minute,
                  ).format(context),
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  alarm.label,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 30),
                Expanded(
                  flex: 5,
                  child: Card(
                    color: Theme.of(context).colorScheme.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: switch (alarm.mission) {
                        MissionType.math => _MathMission(
                          difficulty: alarm.mathDifficulty,
                          target: alarm.mathQuestions,
                          onComplete: () => _complete(context),
                        ),
                        MissionType.memory => _MemoryMission(
                          digits: alarm.memoryDigits,
                          onComplete: () => _complete(context),
                        ),
                        MissionType.walking => _WalkingMission(
                          target: alarm.stepGoal,
                          onComplete: () => _complete(context),
                        ),
                        MissionType.pushUps => PushUpMission(
                          target: alarm.pushUpGoal,
                          onComplete: () => _complete(context),
                        ),
                      },
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'The alarm dismisses when your mission is complete.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _complete(BuildContext context) async {
    await NativeAlarmPlayer.stop();
    await ref.read(appControllerProvider).completeMission(widget.alarmId);
    if (context.mounted) context.go('/');
  }
}

class _MathMission extends StatefulWidget {
  const _MathMission({
    required this.difficulty,
    required this.target,
    required this.onComplete,
  });
  final MathDifficulty difficulty;
  final int target;
  final VoidCallback onComplete;

  @override
  State<_MathMission> createState() => _MathMissionState();
}

class _MathMissionState extends State<_MathMission> {
  final _answer = TextEditingController();
  final _random = Random();
  late int _a;
  late int _b;
  late bool _subtract;
  int _correct = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _next();
  }

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  void _next() {
    final max = switch (widget.difficulty) {
      MathDifficulty.easy => 20,
      MathDifficulty.medium => 100,
      MathDifficulty.hard => 500,
    };
    _a = _random.nextInt(max - 2) + 2;
    _b = _random.nextInt(max - 2) + 2;
    _subtract = widget.difficulty != MathDifficulty.easy && _random.nextBool();
    if (_subtract && _b > _a) {
      final swap = _a;
      _a = _b;
      _b = swap;
    }
  }

  void _check() {
    final expected = _subtract ? _a - _b : _a + _b;
    if (int.tryParse(_answer.text) != expected) {
      setState(() => _error = 'Not quite—try again.');
      _answer.clear();
      return;
    }
    _correct++;
    if (_correct >= widget.target) {
      widget.onComplete();
      return;
    }
    setState(() {
      _error = null;
      _answer.clear();
      _next();
    });
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.calculate_rounded, size: 44),
      const SizedBox(height: 12),
      Text(
        'Question ${_correct + 1} of ${widget.target}',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 20),
      Text(
        '$_a ${_subtract ? '−' : '+'} $_b = ?',
        style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 20),
      TextField(
        controller: _answer,
        autofocus: true,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _check(),
        decoration: InputDecoration(
          labelText: 'Your answer',
          errorText: _error,
        ),
      ),
      const SizedBox(height: 12),
      FilledButton(onPressed: _check, child: const Text('Check answer')),
    ],
  );
}

class _MemoryMission extends StatefulWidget {
  const _MemoryMission({required this.digits, required this.onComplete});
  final int digits;
  final VoidCallback onComplete;

  @override
  State<_MemoryMission> createState() => _MemoryMissionState();
}

class _MemoryMissionState extends State<_MemoryMission> {
  final _answer = TextEditingController();
  final _focusNode = FocusNode();
  late final String _code;
  Timer? _hideTimer;
  bool _showCode = true;
  bool _completed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final random = Random();
    _code = List.generate(widget.digits, (_) => random.nextInt(10)).join();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() => _showCode = false);
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _answer.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _check() {
    if (_completed) return;
    if (_answer.text.trim() == _code) {
      _completed = true;
      widget.onComplete();
      return;
    }
    setState(() {
      _error = 'Wrong code. Take a breath and try again.';
      _answer.clear();
    });
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.psychology_rounded, size: 44),
      const SizedBox(height: 12),
      Text(
        _showCode ? 'Memorise this code' : 'Type the code from memory',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 20),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _showCode
            ? Container(
                key: const ValueKey('code'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  _code,
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8,
                  ),
                ),
              )
            : TextField(
                key: const ValueKey('answer'),
                controller: _answer,
                focusNode: _focusNode,
                autofocus: true,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _check(),
                decoration: InputDecoration(
                  labelText: '${widget.digits}-digit code',
                  errorText: _error,
                  prefixIcon: const Icon(Icons.lock_open_rounded),
                ),
              ),
      ),
      const SizedBox(height: 16),
      if (!_showCode)
        FilledButton(onPressed: _check, child: const Text('Unlock alarm'))
      else
        const Text(
          'It will disappear in a moment.',
          textAlign: TextAlign.center,
        ),
    ],
  );
}

class _WalkingMission extends StatefulWidget {
  const _WalkingMission({required this.target, required this.onComplete});
  final int target;
  final VoidCallback onComplete;

  @override
  State<_WalkingMission> createState() => _WalkingMissionState();
}

class _WalkingMissionState extends State<_WalkingMission> {
  StreamSubscription<StepCount>? _subscription;
  int? _start;
  int _steps = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  Future<void> _listen() async {
    final status = await Permission.activityRecognition.request();
    if (!status.isGranted) {
      setState(() => _error = 'Activity permission is needed to count steps.');
      return;
    }
    _subscription = Pedometer.stepCountStream.listen(
      (event) {
        _start ??= event.steps;
        final value = max(0, event.steps - _start!);
        if (!mounted) return;
        setState(() => _steps = value);
        if (value >= widget.target) widget.onComplete();
      },
      onError: (_) {
        if (mounted) {
          setState(
            () => _error = 'Step counting is unavailable on this device.',
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_steps / widget.target).clamp(0.0, 1.0);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 150,
          height: 150,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 14,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$_steps',
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text('of ${widget.target} steps'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _error ?? 'Get moving. Each step brings back a little consciousness.',
          textAlign: TextAlign.center,
        ),
        if (_error != null)
          TextButton(
            onPressed: openAppSettings,
            child: const Text('Open permission settings'),
          ),
      ],
    );
  }
}
