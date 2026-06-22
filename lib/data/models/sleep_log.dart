/// A single night's sleep record, used by the AI Wake-Up Coach to learn
/// patterns and recommend an optimal bedtime.
class SleepLog {
  final String id;
  final DateTime sleepAt; // when the user reported going to bed
  final DateTime wakeAt; // when the alarm was actually dismissed
  final int snoozeCount; // how many times they snoozed that morning
  final int dismissDurationSec; // how long it took to complete the mission

  const SleepLog({
    required this.id,
    required this.sleepAt,
    required this.wakeAt,
    this.snoozeCount = 0,
    this.dismissDurationSec = 0,
  });

  Duration get duration => wakeAt.difference(sleepAt);

  Map<String, dynamic> toJson() => {
        'id': id,
        'sleepAt': sleepAt.toIso8601String(),
        'wakeAt': wakeAt.toIso8601String(),
        'snoozeCount': snoozeCount,
        'dismissDurationSec': dismissDurationSec,
      };

  factory SleepLog.fromJson(Map<String, dynamic> j) => SleepLog(
        id: j['id'],
        sleepAt: DateTime.parse(j['sleepAt']),
        wakeAt: DateTime.parse(j['wakeAt']),
        snoozeCount: j['snoozeCount'] ?? 0,
        dismissDurationSec: j['dismissDurationSec'] ?? 0,
      );
}
