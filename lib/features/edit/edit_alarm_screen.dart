import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../core/wallpapers.dart';
import '../../data/storage.dart';
import '../../data/models/alarm_model.dart';
import '../../data/models/enums.dart';
import '../../data/models/mission_config.dart';
import '../../services/routine_service.dart';
import '../../state/providers.dart';
import 'widgets/section_card.dart';

class EditAlarmScreen extends ConsumerStatefulWidget {
  final AlarmModel? existing;

  /// When true (new alarm from the home + button), the time clock opens
  /// immediately so the user can set the alarm time right away.
  final bool autoPickTime;
  const EditAlarmScreen(
      {super.key, this.existing, this.autoPickTime = false});

  @override
  ConsumerState<EditAlarmScreen> createState() => _EditAlarmScreenState();
}

class _EditAlarmScreenState extends ConsumerState<EditAlarmScreen> {
  late TimeOfDay _time;
  late TextEditingController _label;
  late Set<int> _days;
  late int _wallpaper;
  late AlarmSoundType _sound;
  late double _volume;
  late bool _gradual;
  late int _gradualSeconds;
  late bool _vibrate;
  late bool _flash;
  late bool _snooze;
  late int _snoozeMin;
  late int _maxSnoozes;
  late MissionConfig _mission;
  late bool _penalty;
  late int _penaltyAmount;
  late bool _accountability;
  late TextEditingController _buddy;
  late bool _routine;
  late Set<RoutineAction> _routineActions;
  late TextEditingController _qrPayload;
  late TextEditingController _photoLabel;

  /// Plays a short preview when the user taps a sound.
  final AudioPlayer _preview = AudioPlayer();

  @override
  void initState() {
    super.initState();
    final a = widget.existing;
    _time = a != null
        ? TimeOfDay(hour: a.hour, minute: a.minute)
        : TimeOfDay.now();
    // Pop the time clock straight away when creating a fresh alarm.
    if (a == null && widget.autoPickTime) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _pickTime());
    }
    _label = TextEditingController(text: a?.label ?? 'Alarm');
    _days = {...?a?.repeatDays};
    _wallpaper = a?.wallpaper ?? 0;
    // New alarms inherit the user's saved defaults from Settings.
    final s = Storage.instance;
    final defSoundName = s.getSetting<String>('default_sound', 'uplift');
    final defSound = AlarmSoundType.values.firstWhere(
        (x) => x.name == defSoundName,
        orElse: () => AlarmSoundType.uplift);
    _sound = a?.sound ?? defSound;
    _volume = a?.maxVolume ?? 1.0;
    _gradual = a?.gradualVolume ?? (s.getSetting<bool>('default_gradual', true) ?? true);
    _gradualSeconds = a?.gradualSeconds ?? 30;
    _vibrate = a?.vibrate ?? (s.getSetting<bool>('default_vibrate', true) ?? true);
    _flash = a?.flash ?? false;
    _snooze = a?.snoozeEnabled ?? true;
    _snoozeMin = a?.snoozeMinutes ?? 5;
    _maxSnoozes = a?.maxSnoozes ?? 3;
    _mission = a?.mission ?? const MissionConfig();
    _penalty = a?.penaltyEnabled ?? false;
    _penaltyAmount = a?.penaltyAmount ?? 50;
    _accountability = a?.accountabilityEnabled ?? false;
    _buddy = TextEditingController(text: a?.accountabilityContact ?? '');
    _routine = a?.routineEnabled ?? false;
    _routineActions = {
      ...?a?.routineActions.map((n) => RoutineAction.values
          .firstWhere((x) => x.name == n, orElse: () => RoutineAction.motivation))
    };
    _qrPayload = TextEditingController(text: a?.mission.qrPayload ?? '');
    _photoLabel = TextEditingController(text: a?.mission.photoLabel ?? '');
  }

  @override
  void dispose() {
    _label.dispose();
    _buddy.dispose();
    _qrPayload.dispose();
    _photoLabel.dispose();
    _preview.dispose();
    super.dispose();
  }

  /// Select a sound and immediately play a short preview so the user can hear it.
  Future<void> _selectSound(AlarmSoundType s) async {
    setState(() => _sound = s);
    try {
      await _preview.stop();
      await _preview.play(AssetSource(s.asset.replaceFirst('assets/', '')));
    } catch (_) {
      // ignore preview failures (e.g. no audio focus)
    }
  }

  void _save() {
    final base = widget.existing;
    final alarm = AlarmModel(
      id: base?.id ?? Fmt.newAlarmId(),
      label: _label.text.trim().isEmpty ? 'Alarm' : _label.text.trim(),
      hour: _time.hour,
      minute: _time.minute,
      repeatDays: _days,
      enabled: base?.enabled ?? true,
      wallpaper: _wallpaper,
      sound: _sound,
      maxVolume: _volume,
      gradualVolume: _gradual,
      gradualSeconds: _gradualSeconds,
      vibrate: _vibrate,
      flash: _flash,
      snoozeEnabled: _snooze,
      snoozeMinutes: _snoozeMin,
      maxSnoozes: _maxSnoozes,
      mission: _mission.copyWith(
        qrPayload: _qrPayload.text.trim(),
        photoLabel: _photoLabel.text.trim(),
      ),
      penaltyEnabled: _penalty,
      penaltyAmount: _penaltyAmount,
      accountabilityEnabled: _accountability,
      accountabilityContact: _buddy.text.trim(),
      routineEnabled: _routine,
      routineActions: _routineActions.map((e) => e.name).toList(),
      createdAt: base?.createdAt ?? DateTime.now(),
    );
    ref.read(alarmsProvider.notifier).save(alarm);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'New alarm' : 'Edit alarm'),
      ),
      // ---- Scrolling content + fixed bottom Save bar ----
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _timePicker(),
                const SizedBox(height: 20),
                _basics(),
                _repeat(),
                _soundSection(),
                _wallpaperSection(),
                _missionSection(),
                CollapsibleSection(
                  title: 'Wake-up & snooze',
                  icon: Icons.tune,
                  children: [..._intensityChildren(), ..._snoozeChildren()],
                ),
                CollapsibleSection(
                  title: 'Extras',
                  icon: Icons.auto_awesome,
                  children: [
                    ..._penaltyChildren(),
                    const Divider(height: 24),
                    ..._accountabilityChildren(),
                    const Divider(height: 24),
                    ..._routineChildren(),
                  ],
                ),
                if (widget.existing != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: _delete,
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14)),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete alarm',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          _BottomSaveBar(onSave: _save),
        ],
      ),
    );
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete alarm?'),
        content: Text('"${_label.text.trim()}" will be removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(alarmsProvider.notifier).remove(widget.existing!.id);
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null && mounted) setState(() => _time = picked);
  }

  Widget _timePicker() {
    final hhmm = Fmt.time(_time.hour, _time.minute)
        .replaceAll(RegExp(r' (AM|PM)'), '');
    final ampm = _time.hour < 12 ? 'AM' : 'PM';
    return GestureDetector(
      onTap: _pickTime,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(hhmm,
                    style: const TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -2)),
                const SizedBox(width: 8),
                Text(ampm,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app_outlined,
                    size: 13, color: AppColors.textMuted.withValues(alpha: .8)),
                const SizedBox(width: 5),
                Text('Tap to change',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted.withValues(alpha: .8))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _basics() {
    return SectionCard(
      title: 'Label',
      child: TextField(
        controller: _label,
        decoration: const InputDecoration(
          hintText: 'e.g. Gym, Work, Meds',
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _repeat() {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return SectionCard(
      title: 'Repeat',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (i) {
          final day = i + 1;
          final on = _days.contains(day);
          return GestureDetector(
            onTap: () => setState(
                () => on ? _days.remove(day) : _days.add(day)),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: on ? AppColors.primary : AppColors.surfaceAlt,
              child: Text(labels[i],
                  style: TextStyle(
                      color: on ? Colors.white : AppColors.textMuted,
                      fontWeight: FontWeight.bold)),
            ),
          );
        }),
      ),
    );
  }

  Widget _soundSection() {
    return SectionCard(
      title: 'Alarm sound',
      child: SizedBox(
        height: 42,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: AlarmSoundType.values.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final s = AlarmSoundType.values[i];
            final sel = _sound == s;
            return GestureDetector(
              onTap: () => _selectSound(s),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: sel ? AppColors.primary : AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(21),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(sel ? Icons.volume_up : Icons.play_arrow_rounded,
                        size: 17,
                        color: sel ? Colors.white : AppColors.textMuted),
                    const SizedBox(width: 6),
                    Text(s.label,
                        style: TextStyle(
                            color: sel ? Colors.white : AppColors.textMuted,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _wallpaperSection() {
    return SectionCard(
      title: 'Alarm wallpaper',
      child: SizedBox(
        height: 110,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: Wallpapers.all.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final wp = Wallpapers.all[i];
            final sel = _wallpaper == i;
            return GestureDetector(
              onTap: () => setState(() => _wallpaper = i),
              child: Container(
                width: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: sel ? Colors.white : Colors.transparent,
                      width: 2.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      WallpaperView(wp),
                      if (sel)
                        const Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.check_circle,
                                color: Colors.white, size: 18),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _intensityChildren() {
    return [
      Row(
        children: [
          const Icon(Icons.volume_up, color: AppColors.textMuted),
          Expanded(
            child: Slider(
              value: _volume,
              onChanged: (v) => setState(() => _volume = v),
              min: 0.2,
              max: 1.0,
            ),
          ),
          Text('${(_volume * 100).round()}%'),
        ],
      ),
      SwitchListTile(
        value: _gradual,
        onChanged: (v) => setState(() => _gradual = v),
        title: const Text('Gradually increase volume'),
        subtitle: Text('Ramp up over $_gradualSeconds s'),
        contentPadding: EdgeInsets.zero,
      ),
      if (_gradual)
        Slider(
          value: _gradualSeconds.toDouble(),
          min: 5,
          max: 120,
          divisions: 23,
          label: '$_gradualSeconds s',
          onChanged: (v) => setState(() => _gradualSeconds = v.round()),
        ),
      SwitchListTile(
        value: _vibrate,
        onChanged: (v) => setState(() => _vibrate = v),
        title: const Text('Vibrate'),
        contentPadding: EdgeInsets.zero,
      ),
      SwitchListTile(
        value: _flash,
        onChanged: (v) => setState(() => _flash = v),
        title: const Text('Flash screen'),
        subtitle: const Text('Strobe the screen to wake you'),
        contentPadding: EdgeInsets.zero,
      ),
    ];
  }

  List<Widget> _snoozeChildren() {
    return [
      const Divider(height: 24),
      SwitchListTile(
        value: _snooze,
        onChanged: (v) => setState(() => _snooze = v),
        title: const Text('Allow snooze'),
        contentPadding: EdgeInsets.zero,
      ),
      if (_snooze) ...[
        _stepperRow('Snooze length', '$_snoozeMin min',
            () => setState(() => _snoozeMin = (_snoozeMin - 1).clamp(1, 30)),
            () => setState(() => _snoozeMin = (_snoozeMin + 1).clamp(1, 30))),
        _stepperRow(
            'Max snoozes',
            _maxSnoozes == 0 ? 'Unlimited' : '$_maxSnoozes',
            () => setState(() => _maxSnoozes = (_maxSnoozes - 1).clamp(0, 10)),
            () => setState(() => _maxSnoozes = (_maxSnoozes + 1).clamp(0, 10))),
      ],
    ];
  }

  Widget _stepperRow(
      String label, String value, VoidCallback minus, VoidCallback plus) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          IconButton(onPressed: minus, icon: const Icon(Icons.remove_circle_outline)),
          SizedBox(width: 70, child: Center(child: Text(value))),
          IconButton(onPressed: plus, icon: const Icon(Icons.add_circle_outline)),
        ],
      ),
    );
  }

  Widget _missionSection() {
    return SectionCard(
      title: 'Dismiss mission',
      subtitle: 'How you must prove you\'re awake',
      child: Column(
        children: [
          DropdownButtonFormField<MissionType>(
            initialValue: _mission.type,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: MissionType.values
                .map((m) => DropdownMenuItem(value: m, child: Text(m.label)))
                .toList(),
            onChanged: (v) =>
                setState(() => _mission = _mission.copyWith(type: v)),
          ),
          if (_mission.type != MissionType.none) ...[
            const SizedBox(height: 8),
            Text(_mission.type.description,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 13)),
          ],
          if (_missionUsesDifficulty) ...[
            const SizedBox(height: 12),
            SegmentedButton<MissionDifficulty>(
              segments: MissionDifficulty.values
                  .map((d) =>
                      ButtonSegment(value: d, label: Text(d.label)))
                  .toList(),
              selected: {_mission.difficulty},
              onSelectionChanged: (s) => setState(
                  () => _mission = _mission.copyWith(difficulty: s.first)),
            ),
          ],
          if (_missionUsesReps)
            _stepperRow(
                'Repetitions',
                '${_mission.repetitions}',
                () => setState(() => _mission = _mission.copyWith(
                    repetitions: (_mission.repetitions - 1).clamp(1, 10))),
                () => setState(() => _mission = _mission.copyWith(
                    repetitions: (_mission.repetitions + 1).clamp(1, 10)))),
          if (_mission.type == MissionType.steps)
            _stepperRow(
                'Steps',
                '${_mission.stepCount}',
                () => setState(() => _mission = _mission.copyWith(
                    stepCount: (_mission.stepCount - 10).clamp(10, 1000))),
                () => setState(() => _mission = _mission.copyWith(
                    stepCount: (_mission.stepCount + 10).clamp(10, 1000)))),
          if (_mission.type == MissionType.qrScan)
            TextField(
              controller: _qrPayload,
              decoration: const InputDecoration(
                labelText: 'Required QR content (optional)',
                hintText: 'Leave blank to accept any code',
              ),
            ),
          if (_mission.type == MissionType.photo)
            TextField(
              controller: _photoLabel,
              decoration: const InputDecoration(
                labelText: 'Object to photograph',
                hintText: 'e.g. bathroom sink',
              ),
            ),
        ],
      ),
    );
  }

  bool get _missionUsesDifficulty =>
      {MissionType.math, MissionType.memory}.contains(_mission.type);
  bool get _missionUsesReps =>
      {MissionType.math, MissionType.typing}.contains(_mission.type);

  List<Widget> _penaltyChildren() {
    return [
      SwitchListTile(
        value: _penalty,
        onChanged: (v) => setState(() => _penalty = v),
        title: const Text('Penalty mode'),
        subtitle: Text('Donate ₹$_penaltyAmount to charity if ignored'),
        contentPadding: EdgeInsets.zero,
      ),
      if (_penalty)
        Slider(
          value: _penaltyAmount.toDouble(),
          min: 10,
          max: 100,
          divisions: 9,
          label: '₹$_penaltyAmount',
          onChanged: (v) => setState(() => _penaltyAmount = v.round()),
        ),
    ];
  }

  List<Widget> _accountabilityChildren() {
    return [
      SwitchListTile(
        value: _accountability,
        onChanged: (v) => setState(() => _accountability = v),
        title: const Text('Accountability mode'),
        subtitle: const Text('Notify a friend if I don\'t wake up'),
        contentPadding: EdgeInsets.zero,
      ),
      if (_accountability)
        TextField(
          controller: _buddy,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Buddy phone number',
            prefixIcon: Icon(Icons.group),
          ),
        ),
    ];
  }

  List<Widget> _routineChildren() {
    return [
      SwitchListTile(
        value: _routine,
        onChanged: (v) => setState(() => _routine = v),
        title: const Text('Morning routine'),
        subtitle: const Text('Run a routine after dismiss'),
        contentPadding: EdgeInsets.zero,
      ),
      if (_routine)
        ...RoutineAction.values.map((a) => CheckboxListTile(
              value: _routineActions.contains(a),
              onChanged: (v) => setState(() => v == true
                  ? _routineActions.add(a)
                  : _routineActions.remove(a)),
              title: Text(a.label),
              contentPadding: EdgeInsets.zero,
              activeColor: AppColors.primary,
            )),
    ];
  }
}

/// Fixed Save bar pinned to the bottom of the alarm editor.
class _BottomSaveBar extends StatelessWidget {
  final VoidCallback onSave;
  const _BottomSaveBar({required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(top: BorderSide(color: AppColors.surfaceAlt, width: .5)),
      ),
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: onSave,
          child: const Text('Save'),
        ),
      ),
    );
  }
}
