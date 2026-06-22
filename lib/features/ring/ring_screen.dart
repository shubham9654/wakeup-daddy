import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../data/models/alarm_model.dart';
import '../../data/models/enums.dart';
import '../../data/models/sleep_log.dart';
import '../../data/storage.dart';
import '../../services/accountability_service.dart';
import '../../services/alarm_service.dart';
import '../../services/penalty_service.dart';
import '../../services/routine_service.dart';
import '../../state/providers.dart';
import '../missions/mission_runner.dart';

/// Full-screen wake experience: big clock, optional screen-flash strobe,
/// snooze + dismiss, and the dismiss mission gate. Also runs the
/// accountability grace timer and penalty trigger.
class RingScreen extends ConsumerStatefulWidget {
  final AlarmModel alarm;
  const RingScreen({super.key, required this.alarm});

  @override
  ConsumerState<RingScreen> createState() => _RingScreenState();
}

class _RingScreenState extends ConsumerState<RingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flash;
  Timer? _clock;
  Timer? _accountabilityTimer;
  int _snoozesUsed = 0;
  final _startedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _flash = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    if (widget.alarm.flash) _flash.repeat(reverse: true);
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _startAccountabilityGrace();
  }

  void _startAccountabilityGrace() {
    if (!widget.alarm.accountabilityEnabled && !widget.alarm.penaltyEnabled) {
      return;
    }
    // If the user hasn't fully dismissed within the grace window, escalate.
    _accountabilityTimer = Timer(const Duration(minutes: 2), () {
      if (!mounted) return;
      if (widget.alarm.accountabilityEnabled) {
        AccountabilityService.instance.notifyBuddy(
          contact: widget.alarm.accountabilityContact,
          sleeperName: Storage.instance
                  .getSetting<String>('user_name', 'Your friend') ??
              'Your friend',
          alarmLabel: widget.alarm.label,
        );
      }
      if (widget.alarm.penaltyEnabled) {
        PenaltyService.instance.trigger(
          amount: widget.alarm.penaltyAmount,
          charity: Storage.instance
                  .getSetting<String>('penalty_charity', 'GiveIndia') ??
              'GiveIndia',
        );
      }
    });
  }

  @override
  void dispose() {
    _flash.dispose();
    _clock?.cancel();
    _accountabilityTimer?.cancel();
    super.dispose();
  }

  Future<void> _snooze() async {
    if (widget.alarm.maxSnoozes != 0 &&
        _snoozesUsed >= widget.alarm.maxSnoozes) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No snoozes left — complete the mission!')));
      return;
    }
    _snoozesUsed++;
    await AlarmService.instance.snooze(widget.alarm);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _beginDismiss() async {
    HapticFeedback.mediumImpact();
    if (widget.alarm.mission.type == MissionType.none) {
      await _finishDismiss();
      return;
    }
    // Push the mission; only a completed mission returns true.
    final completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: AppColors.bg,
          body: MissionRunner(
            config: widget.alarm.mission,
            onComplete: () => Navigator.of(context).pop(true),
          ),
        ),
      ),
    );
    if (completed == true) await _finishDismiss();
  }

  Future<void> _finishDismiss() async {
    _accountabilityTimer?.cancel();
    await AlarmService.instance.dismiss(widget.alarm);
    _logSleep();
    _maybeRunRoutine();

    final alarms = ref.read(alarmsProvider.notifier);
    if (widget.alarm.ephemeral) {
      // Test/preview alarms clean themselves up.
      await alarms.remove(widget.alarm.id);
    } else if (widget.alarm.isOneShot) {
      // A one-time alarm has served its purpose — switch it off.
      await alarms.toggle(widget.alarm.id, false);
    }

    if (mounted) Navigator.of(context).pop();
  }

  void _logSleep() {
    final wake = DateTime.now();
    final bedRaw = Storage.instance.getSetting<String>('last_bedtime');
    DateTime sleepAt;
    final parsed = bedRaw == null ? null : DateTime.tryParse(bedRaw);
    if (parsed != null && wake.difference(parsed).inHours.abs() <= 16) {
      sleepAt = parsed;
    } else {
      sleepAt = wake.subtract(const Duration(hours: 7, minutes: 30));
    }
    ref.read(sleepLogsProvider.notifier).add(SleepLog(
          id: const Uuid().v4(),
          sleepAt: sleepAt,
          wakeAt: wake,
          snoozeCount: _snoozesUsed,
          dismissDurationSec: wake.difference(_startedAt).inSeconds,
        ));
  }

  void _maybeRunRoutine() {
    if (!widget.alarm.routineEnabled) return;
    final actions = widget.alarm.routineActions
        .map((n) => RoutineAction.values
            .firstWhere((a) => a.name == n, orElse: () => RoutineAction.motivation))
        .toList();
    final goals = (Storage.instance.getSetting<List>('daily_goals') ?? const [])
        .cast<String>();
    RoutineService.instance.run(actions, goals: goals);
  }

  @override
  Widget build(BuildContext context) {
    final now = TimeOfDay.now();
    final canSnooze = widget.alarm.snoozeEnabled &&
        (widget.alarm.maxSnoozes == 0 ||
            _snoozesUsed < widget.alarm.maxSnoozes);

    return PopScope(
      canPop: false, // can't back out of an alarm
      child: AnimatedBuilder(
        animation: _flash,
        builder: (context, child) {
          final bg = widget.alarm.flash
              ? Color.lerp(AppColors.bg, AppColors.accent, _flash.value)!
              : AppColors.bg;
          return Scaffold(backgroundColor: bg, body: child);
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                const Spacer(),
                Text(widget.alarm.label.toUpperCase(),
                    style: const TextStyle(
                        letterSpacing: 4,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Text(
                  Fmt.time(now.hour, now.minute),
                  style: const TextStyle(
                      fontSize: 84, fontWeight: FontWeight.w900, height: 1),
                ),
                const SizedBox(height: 8),
                if (widget.alarm.mission.type != MissionType.none)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.flag, size: 16, color: AppColors.accent),
                        const SizedBox(width: 8),
                        Text(widget.alarm.mission.type.label),
                      ],
                    ),
                  ),
                const Spacer(),
                GestureDetector(
                  onTap: _beginDismiss,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 22),
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: .45),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.alarm_off, color: Colors.white),
                        const SizedBox(width: 10),
                        Text(
                          widget.alarm.mission.type == MissionType.none
                              ? 'Dismiss'
                              : 'Start mission to dismiss',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (widget.alarm.snoozeEnabled)
                  TextButton(
                    onPressed: canSnooze ? _snooze : null,
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.textMuted),
                    child: Text(
                      canSnooze
                          ? 'Snooze ${widget.alarm.snoozeMinutes} min'
                              '${widget.alarm.maxSnoozes == 0 ? '' : ' (${widget.alarm.maxSnoozes - _snoozesUsed} left)'}'
                          : 'No snoozes left',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
