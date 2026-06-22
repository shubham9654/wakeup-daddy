import 'enums.dart';

/// Configuration for a dismiss mission. Only the fields relevant to the
/// chosen [type] are used, but all are persisted so switching types keeps
/// the user's previous settings.
class MissionConfig {
  final MissionType type;
  final MissionDifficulty difficulty;

  /// Number of repetitions required (e.g. how many math problems / typing lines).
  final int repetitions;

  /// For [MissionType.steps]: number of steps required.
  final int stepCount;

  /// For [MissionType.qrScan]: the exact payload the scanned code must match.
  final String qrPayload;

  /// For [MissionType.photo]: a human label of the object to photograph
  /// (e.g. "kitchen sink", "toothbrush").
  final String photoLabel;

  const MissionConfig({
    this.type = MissionType.math,
    this.difficulty = MissionDifficulty.easy,
    this.repetitions = 2,
    this.stepCount = 100,
    this.qrPayload = '',
    this.photoLabel = '',
  });

  MissionConfig copyWith({
    MissionType? type,
    MissionDifficulty? difficulty,
    int? repetitions,
    int? stepCount,
    String? qrPayload,
    String? photoLabel,
  }) {
    return MissionConfig(
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      repetitions: repetitions ?? this.repetitions,
      stepCount: stepCount ?? this.stepCount,
      qrPayload: qrPayload ?? this.qrPayload,
      photoLabel: photoLabel ?? this.photoLabel,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'difficulty': difficulty.name,
        'repetitions': repetitions,
        'stepCount': stepCount,
        'qrPayload': qrPayload,
        'photoLabel': photoLabel,
      };

  factory MissionConfig.fromJson(Map<String, dynamic> j) => MissionConfig(
        type: MissionType.values.byName(j['type'] ?? 'none'),
        difficulty:
            MissionDifficulty.values.byName(j['difficulty'] ?? 'medium'),
        repetitions: j['repetitions'] ?? 3,
        stepCount: j['stepCount'] ?? 100,
        qrPayload: j['qrPayload'] ?? '',
        photoLabel: j['photoLabel'] ?? '',
      );
}
