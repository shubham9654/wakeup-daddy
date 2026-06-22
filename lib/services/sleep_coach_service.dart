import '../data/models/sleep_log.dart';

/// On-device "AI" Wake-Up Coach.
///
/// We deliberately keep the intelligence on-device and explainable: it learns
/// from the user's [SleepLog] history to estimate their natural sleep need and
/// recommend an optimal bedtime for a given wake time, accounting for ~15 min
/// to fall asleep and aligning to 90-minute sleep cycles.
class SleepInsight {
  final Duration averageSleep;
  final Duration recommendedSleepNeed;
  final double avgSnoozes;
  final TimeOfDayLite recommendedBedtime; // for the next wake-up
  final String headline;
  final String detail;

  const SleepInsight({
    required this.averageSleep,
    required this.recommendedSleepNeed,
    required this.avgSnoozes,
    required this.recommendedBedtime,
    required this.headline,
    required this.detail,
  });
}

/// Minimal time-of-day holder (avoids importing Flutter into a service).
class TimeOfDayLite {
  final int hour;
  final int minute;
  const TimeOfDayLite(this.hour, this.minute);

  String format() {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final ampm = hour < 12 ? 'AM' : 'PM';
    return '$h:${minute.toString().padLeft(2, '0')} $ampm';
  }
}

class SleepCoachService {
  SleepCoachService._();
  static final SleepCoachService instance = SleepCoachService._();

  static const _cycle = Duration(minutes: 90);
  static const _fallAsleepBuffer = Duration(minutes: 15);
  static const _defaultNeed = Duration(hours: 7, minutes: 30); // 5 cycles

  SleepInsight analyze(List<SleepLog> logs, {required TimeOfDayLite wakeTime}) {
    if (logs.isEmpty) {
      return SleepInsight(
        averageSleep: Duration.zero,
        recommendedSleepNeed: _defaultNeed,
        avgSnoozes: 0,
        recommendedBedtime: _bedtimeFor(wakeTime, _defaultNeed),
        headline: 'Let\'s learn your rhythm',
        detail:
            'Log a few nights and WakeDaddy will tailor your ideal bedtime. '
            'For now we suggest a 7h30m night (5 sleep cycles).',
      );
    }

    final recent = logs.take(14).toList();
    final avgMinutes = recent
            .map((l) => l.duration.inMinutes)
            .fold<int>(0, (a, b) => a + b) /
        recent.length;
    final avgSleep = Duration(minutes: avgMinutes.round());
    final avgSnoozes =
        recent.map((l) => l.snoozeCount).fold<int>(0, (a, b) => a + b) /
            recent.length;

    // Estimate need: round average to the nearest whole 90-min cycle, but never
    // below 6h. If they snooze a lot, nudge the need up by half a cycle.
    var cycles = (avgMinutes / 90).round().clamp(4, 7);
    if (avgSnoozes >= 2) cycles += 1;
    var need = _cycle * cycles;
    if (need < const Duration(hours: 6)) need = const Duration(hours: 6);

    final bedtime = _bedtimeFor(wakeTime, need);

    final headline = avgSnoozes >= 2
        ? 'You\'re fighting your alarm'
        : 'You\'re on a solid rhythm';
    final detail = 'Over the last ${recent.length} nights you slept '
        '${_fmt(avgSleep)} on average and snoozed '
        '${avgSnoozes.toStringAsFixed(1)}× per morning. '
        'To wake at ${wakeTime.format()} feeling rested, aim to be asleep by '
        '${bedtime.format()} ($cycles sleep cycles).';

    return SleepInsight(
      averageSleep: avgSleep,
      recommendedSleepNeed: need,
      avgSnoozes: avgSnoozes,
      recommendedBedtime: bedtime,
      headline: headline,
      detail: detail,
    );
  }

  TimeOfDayLite _bedtimeFor(TimeOfDayLite wake, Duration need) {
    final totalSubtract = need + _fallAsleepBuffer;
    var minutes = wake.hour * 60 + wake.minute - totalSubtract.inMinutes;
    minutes %= (24 * 60);
    if (minutes < 0) minutes += 24 * 60;
    return TimeOfDayLite(minutes ~/ 60, minutes % 60);
  }

  String _fmt(Duration d) => '${d.inHours}h${(d.inMinutes % 60).toString().padLeft(2, '0')}m';
}
