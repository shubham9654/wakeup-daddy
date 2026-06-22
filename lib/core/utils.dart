import '../data/models/alarm_model.dart';

/// Formatting + small domain helpers shared across the UI.
class Fmt {
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  /// Generate a fresh, stable, positive 31-bit alarm id (also used natively).
  static int newAlarmId() =>
      DateTime.now().millisecondsSinceEpoch.remainder(1 << 31);

  static String time(int hour, int minute) {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final ampm = hour < 12 ? 'AM' : 'PM';
    return '$h:${minute.toString().padLeft(2, '0')} $ampm';
  }

  static String repeatLabel(AlarmModel a) {
    if (a.isOneShot) return 'Once';
    if (a.repeatDays.length == 7) return 'Every day';
    if (a.repeatDays.length == 5 &&
        a.repeatDays.containsAll({1, 2, 3, 4, 5})) {
      return 'Weekdays';
    }
    if (a.repeatDays.length == 2 && a.repeatDays.containsAll({6, 7})) {
      return 'Weekends';
    }
    final sorted = a.repeatDays.toList()..sort();
    return sorted.map((d) => _days[d - 1]).join(', ');
  }

  static String untilNext(DateTime next) {
    final diff = next.difference(DateTime.now());
    if (diff.inMinutes < 1) return 'now';
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    if (h == 0) return 'in ${m}m';
    if (h < 24) return 'in ${h}h ${m}m';
    final d = diff.inDays;
    return 'in ${d}d ${h % 24}h';
  }
}
