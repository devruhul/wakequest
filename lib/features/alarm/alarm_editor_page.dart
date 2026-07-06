import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/models/alarm.dart';
import '../../core/notifications/alarm_notification_service.dart';
import '../../core/state/app_controller.dart';

class AlarmEditorPage extends ConsumerStatefulWidget {
  const AlarmEditorPage({super.key, this.id});
  final String? id;

  @override
  ConsumerState<AlarmEditorPage> createState() => _AlarmEditorPageState();
}

class _AlarmEditorPageState extends ConsumerState<AlarmEditorPage> {
  late TimeOfDay _time;
  late TextEditingController _label;
  Set<int> _days = {1, 2, 3, 4, 5};
  DateTime? _date;
  MissionType _mission = MissionType.math;
  MathDifficulty _difficulty = MathDifficulty.medium;
  int _questions = 5;
  int _steps = 100;
  double _volume = 1;
  bool _vibrate = true;
  bool _flash = false;
  String? _qrValue;
  Alarm? _existing;

  @override
  void initState() {
    super.initState();
    _existing = widget.id == null
        ? null
        : ref.read(appControllerProvider).alarmById(widget.id!);
    final alarm = _existing;
    _time = alarm == null
        ? const TimeOfDay(hour: 7, minute: 0)
        : TimeOfDay(hour: alarm.hour, minute: alarm.minute);
    _label = TextEditingController(text: alarm?.label ?? 'Good morning');
    if (alarm != null) {
      _days = {...alarm.repeatDays};
      _date = alarm.date;
      _mission = alarm.mission;
      _difficulty = alarm.mathDifficulty;
      _questions = alarm.mathQuestions;
      _steps = alarm.stepGoal;
      _volume = alarm.volume;
      _vibrate = alarm.vibrate;
      _flash = alarm.flash;
      _qrValue = alarm.qrValue;
    }
  }

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_existing == null ? 'New alarm' : 'Edit alarm'),
        actions: [TextButton(onPressed: _save, child: const Text('Save'))],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: _pickTime,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Text(
                  _time.format(context),
                  style: const TextStyle(
                    fontSize: 58,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          TextField(
            controller: _label,
            decoration: const InputDecoration(
              labelText: 'Alarm label',
              prefixIcon: Icon(Icons.label_outline_rounded),
            ),
          ),
          const SizedBox(height: 24),
          const _SectionTitle('Repeat'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: List.generate(7, (index) {
              final day = index + 1;
              return FilterChip(
                label: Text(const ['M', 'T', 'W', 'T', 'F', 'S', 'S'][index]),
                selected: _days.contains(day),
                onSelected: (selected) => setState(() {
                  selected ? _days.add(day) : _days.remove(day);
                }),
              );
            }),
          ),
          if (_days.isEmpty) ...[
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_month_rounded),
              title: const Text('One-time date'),
              subtitle: Text(
                _date == null
                    ? 'Next occurrence'
                    : MaterialLocalizations.of(
                        context,
                      ).formatMediumDate(_date!),
              ),
              trailing: const Icon(Icons.edit_calendar_rounded),
              onTap: _pickDate,
            ),
          ],
          const SizedBox(height: 24),
          const _SectionTitle('Wake-up mission'),
          const SizedBox(height: 10),
          SegmentedButton<MissionType>(
            segments: const [
              ButtonSegment(
                value: MissionType.math,
                icon: Icon(Icons.calculate_rounded),
                label: Text('Math'),
              ),
              ButtonSegment(
                value: MissionType.qr,
                icon: Icon(Icons.qr_code_rounded),
                label: Text('QR'),
              ),
              ButtonSegment(
                value: MissionType.walking,
                icon: Icon(Icons.directions_walk_rounded),
                label: Text('Walk'),
              ),
            ],
            selected: {_mission},
            onSelectionChanged: (value) =>
                setState(() => _mission = value.first),
          ),
          const SizedBox(height: 16),
          _missionOptions(),
          const SizedBox(height: 24),
          const _SectionTitle('Alarm behavior'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.volume_up_rounded),
            title: const Text('Volume'),
            subtitle: Slider(
              value: _volume,
              onChanged: (value) => setState(() => _volume = value),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.vibration_rounded),
            title: const Text('Vibrate'),
            value: _vibrate,
            onChanged: (value) => setState(() => _vibrate = value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.flashlight_on_rounded),
            title: const Text('Flashlight'),
            subtitle: const Text('Requires supported Android hardware'),
            value: _flash,
            onChanged: (value) => setState(() => _flash = value),
          ),
          if (_existing != null) ...[
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Delete alarm'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _missionOptions() => switch (_mission) {
    MissionType.math => Column(
      children: [
        DropdownButtonFormField<MathDifficulty>(
          initialValue: _difficulty,
          decoration: const InputDecoration(labelText: 'Difficulty'),
          items: MathDifficulty.values
              .map(
                (value) => DropdownMenuItem(
                  value: value,
                  child: Text(
                    value.name[0].toUpperCase() + value.name.substring(1),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) =>
              setState(() => _difficulty = value ?? _difficulty),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          initialValue: _questions,
          decoration: const InputDecoration(labelText: 'Correct answers'),
          items: const [3, 5, 10]
              .map(
                (value) => DropdownMenuItem(
                  value: value,
                  child: Text('$value questions'),
                ),
              )
              .toList(),
          onChanged: (value) =>
              setState(() => _questions = value ?? _questions),
        ),
      ],
    ),
    MissionType.qr => Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            if (_qrValue != null)
              QrImageView(
                data: _qrValue!,
                size: 150,
                backgroundColor: Colors.white,
              )
            else
              const Icon(Icons.qr_code_2_rounded, size: 80),
            const SizedBox(height: 12),
            Text(
              _qrValue == null
                  ? 'Create a code, then place it away from your bed.'
                  : 'Save or print this code and place it at your destination.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => setState(
                () => _qrValue =
                    'wakequest:${DateTime.now().microsecondsSinceEpoch}',
              ),
              child: Text(_qrValue == null ? 'Create QR code' : 'New code'),
            ),
          ],
        ),
      ),
    ),
    MissionType.walking => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$_steps steps', style: const TextStyle(fontSize: 18)),
        Slider(
          min: 20,
          max: 200,
          divisions: 9,
          value: _steps.toDouble(),
          label: '$_steps',
          onChanged: (value) => setState(() => _steps = value.round()),
        ),
      ],
    ),
  };

  Future<void> _pickTime() async {
    final result = await showTimePicker(context: context, initialTime: _time);
    if (result != null) setState(() => _time = result);
  }

  Future<void> _save() async {
    if (_mission == MissionType.qr && _qrValue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Create a QR code for this mission first.'),
        ),
      );
      return;
    }
    await AlarmNotificationService.instance.requestPermissions();
    final now = DateTime.now();
    final alarm = Alarm(
      id: _existing?.id ?? now.microsecondsSinceEpoch.toString(),
      hour: _time.hour,
      minute: _time.minute,
      label: _label.text.trim().isEmpty ? 'Wake up' : _label.text.trim(),
      enabled: _existing?.enabled ?? true,
      repeatDays: _days,
      date: _days.isEmpty ? _date : null,
      mission: _mission,
      mathDifficulty: _difficulty,
      mathQuestions: _questions,
      qrValue: _qrValue,
      stepGoal: _steps,
      volume: _volume,
      vibrate: _vibrate,
      flash: _flash,
    );
    await ref.read(appControllerProvider).saveAlarm(alarm);
    if (mounted) context.pop();
  }

  Future<void> _delete() async {
    await ref.read(appControllerProvider).deleteAlarm(_existing!);
    if (mounted) context.pop();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final result = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 3),
    );
    if (result != null) setState(() => _date = result);
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
  );
}
