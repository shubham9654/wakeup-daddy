import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../data/models/sleep_log.dart';
import '../../data/models/wake_event.dart';
import '../../state/providers.dart';
import '../coach/coach_screen.dart';

/// Report tab — weekly Wake-up / Sleep / Habit summaries computed from the
/// real alarm-dismissal history ([wakeEventsProvider]) and sleep logs.
class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  int _tab = 0; // 0 wake-up, 1 sleep, 2 habit
  int _weekOffset = 0;

  static const _tabs = ['Wake up report', 'Sleep report', 'Habit report'];
  static const _dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  Widget build(BuildContext context) {
    final allEvents = ref.watch(wakeEventsProvider);
    final allLogs = ref.watch(sleepLogsProvider);

    final start = _weekStart();
    final end = start.add(const Duration(days: 7));
    final events = allEvents
        .where((e) =>
            !e.dismissedAt.isBefore(start) && e.dismissedAt.isBefore(end))
        .toList();
    final logs = allLogs
        .where((l) => !l.wakeAt.isBefore(start) && l.wakeAt.isBefore(end))
        .toList();

    final stats = _stats(events, logs);
    final bars = _bars(start, events, logs);
    final hasData = bars.any((b) => b != null);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            const Text('Report',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),

            // ---- Week selector ----
            Row(
              children: [
                IconButton(
                  onPressed: () => setState(() => _weekOffset--),
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(_weekLabel(start),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                IconButton(
                  onPressed: _weekOffset >= 0
                      ? null
                      : () => setState(() => _weekOffset++),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // ---- Segmented tabs ----
            Row(
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _tab = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 9),
                        decoration: BoxDecoration(
                          color:
                              _tab == i ? Colors.white : AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(_tabs[i],
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _tab == i
                                    ? Colors.black
                                    : AppColors.textMuted)),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // ---- Stat row ----
            Row(
              children: [
                _Stat(label: stats.$1, value: stats.$2),
                _Stat(label: stats.$3, value: stats.$4),
              ],
            ),
            const SizedBox(height: 36),

            if (!hasData)
              _NoRecord(onSet: () {})
            else
              _RecordChart(
                  values: bars,
                  labels: _dayLabels,
                  color: _tab == 1 ? AppColors.accent : AppColors.primary),

            const SizedBox(height: 30),

            // ---- View daily report ----
            Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {},
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                  child: Row(
                    children: [
                      Icon(Icons.wb_sunny, color: AppColors.primary),
                      SizedBox(width: 14),
                      Expanded(
                          child: Text('View daily report',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700))),
                      Icon(Icons.chevron_right, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CoachScreen())),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(22)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.nightlight_round,
                          color: AppColors.accent, size: 18),
                      SizedBox(width: 8),
                      Text('Sleep coach',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      Icon(Icons.expand_more, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- computations ----

  DateTime _weekStart() {
    final now = DateTime.now().add(Duration(days: 7 * _weekOffset));
    final midnight = DateTime(now.year, now.month, now.day);
    // Week starts on Sunday (weekday 7 → 0 offset).
    return midnight.subtract(Duration(days: now.weekday % 7));
  }

  String _weekLabel(DateTime start) {
    final end = start.add(const Duration(days: 6));
    final fmt = DateFormat('MMM d');
    final prefix = _weekOffset == 0 ? 'This week ' : '';
    return '$prefix${fmt.format(start)} - ${fmt.format(end)}';
  }

  /// Returns (leftLabel, leftValue, rightLabel, rightValue) for the stat row.
  (String, String, String, String) _stats(
      List<WakeEvent> events, List<SleepLog> logs) {
    switch (_tab) {
      case 1: // Sleep
        if (logs.isEmpty) {
          return ('Avg. sleep time', '–', 'Avg. bedtime', '–');
        }
        final avgDur = logs
                .map((l) => l.duration.inMinutes)
                .reduce((a, b) => a + b) ~/
            logs.length;
        final avgBed = _avgClock(
            logs.map((l) => l.sleepAt.hour * 60 + l.sleepAt.minute).toList());
        return (
          'Avg. sleep time',
          '${avgDur ~/ 60}h ${avgDur % 60}m',
          'Avg. bedtime',
          avgBed
        );
      case 2: // Habit
        if (events.isEmpty) {
          return ('Wake-ups', '0', 'Avg. snoozes', '–');
        }
        final snoozes =
            events.map((e) => e.snoozeCount).reduce((a, b) => a + b);
        return (
          'Wake-ups',
          '${events.length}',
          'Avg. snoozes',
          (snoozes / events.length).toStringAsFixed(1)
        );
      default: // Wake up
        if (events.isEmpty) {
          return ('Avg. wake-up time', '–', 'Avg. time to wake up', '–');
        }
        final avgWake =
            _avgClock(events.map((e) => e.wakeMinuteOfDay).toList());
        final avgSec =
            events.map((e) => e.durationSec).reduce((a, b) => a + b) ~/
                events.length;
        final m = avgSec ~/ 60;
        final s = avgSec % 60;
        return (
          'Avg. wake-up time',
          avgWake,
          'Avg. time to wake up',
          m > 0 ? '$m min' : '$s sec'
        );
    }
  }

  String _avgClock(List<int> minutesOfDay) {
    final avg = minutesOfDay.reduce((a, b) => a + b) ~/ minutesOfDay.length;
    final h = avg ~/ 60;
    final m = avg % 60;
    final ampm = h < 12 ? 'am' : 'pm';
    final hh = h % 12 == 0 ? 12 : h % 12;
    return '$hh:${m.toString().padLeft(2, '0')} $ampm';
  }

  /// Per-weekday bar values (null = no record that day), 0..1 normalized.
  List<double?> _bars(
      DateTime start, List<WakeEvent> events, List<SleepLog> logs) {
    final bars = List<double?>.filled(7, null);
    if (_tab == 1) {
      // Sleep duration in hours, normalized to 12h.
      for (final l in logs) {
        final idx = l.wakeAt.difference(start).inDays;
        if (idx < 0 || idx > 6) continue;
        final hours = l.duration.inMinutes / 60.0;
        bars[idx] = (hours / 12).clamp(0.05, 1.0);
      }
    } else if (_tab == 2) {
      // Snooze count normalized to 5.
      for (final e in events) {
        final idx = e.dismissedAt.difference(start).inDays;
        if (idx < 0 || idx > 6) continue;
        bars[idx] = (e.snoozeCount / 5).clamp(0.05, 1.0);
      }
    } else {
      // Minutes-to-wake normalized to 10 min.
      for (final e in events) {
        final idx = e.dismissedAt.difference(start).inDays;
        if (idx < 0 || idx > 6) continue;
        final mins = e.durationSec / 60.0;
        bars[idx] = (mins / 10).clamp(0.08, 1.0);
      }
    }
    return bars;
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style:
                  const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Row(
            children: [
              Flexible(
                child: Text(label,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 13)),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.info_outline,
                  size: 14, color: AppColors.textMuted),
            ],
          ),
        ],
      ),
    );
  }
}

class _NoRecord extends StatelessWidget {
  final VoidCallback onSet;
  const _NoRecord({required this.onSet});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.bar_chart,
            size: 48, color: AppColors.textMuted.withValues(alpha: .5)),
        const SizedBox(height: 12),
        const Text('No alarm record',
            style: TextStyle(color: AppColors.textMuted)),
        const SizedBox(height: 6),
        const Text('Dismiss an alarm to start tracking',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
      ],
    );
  }
}

class _RecordChart extends StatelessWidget {
  final List<double?> values;
  final List<String> labels;
  final Color color;
  const _RecordChart(
      {required this.values, required this.labels, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: values[i] ?? 0),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, _) => Container(
                      height: 8 + 122 * v,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: values[i] == null
                            ? AppColors.surfaceAlt
                            : color.withValues(alpha: .85),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(labels[i],
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
