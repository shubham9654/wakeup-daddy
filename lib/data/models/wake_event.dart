/// A record of one alarm that actually fired and was dismissed. This is what
/// the Report tab aggregates into wake-up time / time-to-wake statistics.
class WakeEvent {
  final String id;
  final int alarmId;

  /// When the alarm was scheduled to ring.
  final DateTime scheduledAt;

  /// When the user finished dismissing it (mission completed).
  final DateTime dismissedAt;

  /// How long it took from ring to full dismiss.
  final int durationSec;

  final int snoozeCount;

  const WakeEvent({
    required this.id,
    required this.alarmId,
    required this.scheduledAt,
    required this.dismissedAt,
    this.durationSec = 0,
    this.snoozeCount = 0,
  });

  /// Minutes past midnight the user actually woke (for "avg wake-up time").
  int get wakeMinuteOfDay => dismissedAt.hour * 60 + dismissedAt.minute;

  Map<String, dynamic> toJson() => {
        'id': id,
        'alarmId': alarmId,
        'scheduledAt': scheduledAt.toIso8601String(),
        'dismissedAt': dismissedAt.toIso8601String(),
        'durationSec': durationSec,
        'snoozeCount': snoozeCount,
      };

  factory WakeEvent.fromJson(Map<String, dynamic> j) => WakeEvent(
        id: j['id'],
        alarmId: j['alarmId'],
        scheduledAt: DateTime.parse(j['scheduledAt']),
        dismissedAt: DateTime.parse(j['dismissedAt']),
        durationSec: j['durationSec'] ?? 0,
        snoozeCount: j['snoozeCount'] ?? 0,
      );
}
