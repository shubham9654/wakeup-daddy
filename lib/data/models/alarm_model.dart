import 'enums.dart';
import 'mission_config.dart';

/// A single configured alarm. Persisted as JSON inside a Hive box.
///
/// [id] doubles as the native alarm id used by the `alarm` plugin, so it must
/// be a stable positive int that fits in a 32-bit range.
class AlarmModel {
  final int id;
  final String label;
  final int hour; // 0-23
  final int minute; // 0-59

  /// Days the alarm repeats on, using DateTime weekday numbering (1=Mon..7=Sun).
  /// Empty means a one-shot alarm.
  final Set<int> repeatDays;

  final bool enabled;

  // --- Sound & wake intensity ---
  final AlarmSoundType sound;
  final double maxVolume; // 0.0 - 1.0
  final bool gradualVolume;
  final int gradualSeconds; // ramp duration
  final bool vibrate;
  final bool flash; // strobe the camera flash / screen

  // --- Snooze ---
  final bool snoozeEnabled;
  final int snoozeMinutes;
  final int maxSnoozes; // 0 = unlimited

  // --- Dismiss mission ---
  final MissionConfig mission;

  // --- "Better than Alarmy" add-ons ---
  final bool penaltyEnabled;
  final int penaltyAmount; // ₹ to donate if ignored
  final bool accountabilityEnabled;
  final String accountabilityContact; // phone / email of the buddy
  final bool routineEnabled;
  final List<String> routineActions; // serialized routine step ids

  /// Transient alarms (e.g. the "test alarm" preview) that should delete
  /// themselves after they're dismissed instead of cluttering the list.
  final bool ephemeral;

  final DateTime createdAt;

  const AlarmModel({
    required this.id,
    this.label = 'Alarm',
    required this.hour,
    required this.minute,
    this.repeatDays = const {},
    this.enabled = true,
    this.sound = AlarmSoundType.pulse,
    this.maxVolume = 1.0,
    this.gradualVolume = true,
    this.gradualSeconds = 30,
    this.vibrate = true,
    this.flash = false,
    this.snoozeEnabled = true,
    this.snoozeMinutes = 5,
    this.maxSnoozes = 3,
    this.mission = const MissionConfig(),
    this.penaltyEnabled = false,
    this.penaltyAmount = 50,
    this.accountabilityEnabled = false,
    this.accountabilityContact = '',
    this.routineEnabled = false,
    this.routineActions = const [],
    this.ephemeral = false,
    required this.createdAt,
  });

  bool get isOneShot => repeatDays.isEmpty;

  /// Resolve a stored sound name, tolerating sounds that were renamed/removed
  /// in an update so old saved alarms don't crash on load.
  static AlarmSoundType _soundFromName(dynamic name) {
    for (final s in AlarmSoundType.values) {
      if (s.name == name) return s;
    }
    return AlarmSoundType.pulse;
  }

  AlarmModel copyWith({
    String? label,
    int? hour,
    int? minute,
    Set<int>? repeatDays,
    bool? enabled,
    AlarmSoundType? sound,
    double? maxVolume,
    bool? gradualVolume,
    int? gradualSeconds,
    bool? vibrate,
    bool? flash,
    bool? snoozeEnabled,
    int? snoozeMinutes,
    int? maxSnoozes,
    MissionConfig? mission,
    bool? penaltyEnabled,
    int? penaltyAmount,
    bool? accountabilityEnabled,
    String? accountabilityContact,
    bool? routineEnabled,
    List<String>? routineActions,
  }) {
    return AlarmModel(
      id: id,
      label: label ?? this.label,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      repeatDays: repeatDays ?? this.repeatDays,
      enabled: enabled ?? this.enabled,
      sound: sound ?? this.sound,
      maxVolume: maxVolume ?? this.maxVolume,
      gradualVolume: gradualVolume ?? this.gradualVolume,
      gradualSeconds: gradualSeconds ?? this.gradualSeconds,
      vibrate: vibrate ?? this.vibrate,
      flash: flash ?? this.flash,
      snoozeEnabled: snoozeEnabled ?? this.snoozeEnabled,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      maxSnoozes: maxSnoozes ?? this.maxSnoozes,
      mission: mission ?? this.mission,
      penaltyEnabled: penaltyEnabled ?? this.penaltyEnabled,
      penaltyAmount: penaltyAmount ?? this.penaltyAmount,
      accountabilityEnabled:
          accountabilityEnabled ?? this.accountabilityEnabled,
      accountabilityContact:
          accountabilityContact ?? this.accountabilityContact,
      routineEnabled: routineEnabled ?? this.routineEnabled,
      routineActions: routineActions ?? this.routineActions,
      ephemeral: ephemeral,
      createdAt: createdAt,
    );
  }

  /// Computes the next time this alarm should fire, relative to [from].
  DateTime nextOccurrence([DateTime? from]) {
    final now = from ?? DateTime.now();
    final todayAt = DateTime(now.year, now.month, now.day, hour, minute);

    if (isOneShot) {
      return todayAt.isAfter(now) ? todayAt : todayAt.add(const Duration(days: 1));
    }
    // Find the soonest matching repeat day.
    for (int offset = 0; offset < 8; offset++) {
      final candidate = todayAt.add(Duration(days: offset));
      if (repeatDays.contains(candidate.weekday) && candidate.isAfter(now)) {
        return candidate;
      }
    }
    return todayAt.add(const Duration(days: 1));
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'hour': hour,
        'minute': minute,
        'repeatDays': repeatDays.toList(),
        'enabled': enabled,
        'sound': sound.name,
        'maxVolume': maxVolume,
        'gradualVolume': gradualVolume,
        'gradualSeconds': gradualSeconds,
        'vibrate': vibrate,
        'flash': flash,
        'snoozeEnabled': snoozeEnabled,
        'snoozeMinutes': snoozeMinutes,
        'maxSnoozes': maxSnoozes,
        'mission': mission.toJson(),
        'penaltyEnabled': penaltyEnabled,
        'penaltyAmount': penaltyAmount,
        'accountabilityEnabled': accountabilityEnabled,
        'accountabilityContact': accountabilityContact,
        'routineEnabled': routineEnabled,
        'routineActions': routineActions,
        'ephemeral': ephemeral,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AlarmModel.fromJson(Map<String, dynamic> j) => AlarmModel(
        id: j['id'],
        label: j['label'] ?? 'Alarm',
        hour: j['hour'],
        minute: j['minute'],
        repeatDays: (j['repeatDays'] as List).map((e) => e as int).toSet(),
        enabled: j['enabled'] ?? true,
        sound: _soundFromName(j['sound']),
        maxVolume: (j['maxVolume'] ?? 1.0).toDouble(),
        gradualVolume: j['gradualVolume'] ?? true,
        gradualSeconds: j['gradualSeconds'] ?? 30,
        vibrate: j['vibrate'] ?? true,
        flash: j['flash'] ?? false,
        snoozeEnabled: j['snoozeEnabled'] ?? true,
        snoozeMinutes: j['snoozeMinutes'] ?? 5,
        maxSnoozes: j['maxSnoozes'] ?? 3,
        mission: MissionConfig.fromJson(
            Map<String, dynamic>.from(j['mission'] ?? {})),
        penaltyEnabled: j['penaltyEnabled'] ?? false,
        penaltyAmount: j['penaltyAmount'] ?? 50,
        accountabilityEnabled: j['accountabilityEnabled'] ?? false,
        accountabilityContact: j['accountabilityContact'] ?? '',
        routineEnabled: j['routineEnabled'] ?? false,
        routineActions:
            (j['routineActions'] as List?)?.map((e) => e as String).toList() ??
                const [],
        ephemeral: j['ephemeral'] ?? false,
        createdAt: DateTime.parse(j['createdAt']),
      );
}
