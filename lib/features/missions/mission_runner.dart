import 'package:flutter/material.dart';

import '../../data/models/enums.dart';
import '../../data/models/mission_config.dart';
import 'math_mission.dart';
import 'memory_mission.dart';
import 'photo_mission.dart';
import 'qr_mission.dart';
import 'steps_mission.dart';
import 'typing_mission.dart';

/// Builds the correct mission widget for a given [MissionConfig] and invokes
/// [onComplete] when the user has satisfied it.
class MissionRunner extends StatelessWidget {
  final MissionConfig config;
  final VoidCallback onComplete;
  const MissionRunner(
      {super.key, required this.config, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    switch (config.type) {
      case MissionType.math:
        return MathMission(config: config, onComplete: onComplete);
      case MissionType.typing:
        return TypingMission(config: config, onComplete: onComplete);
      case MissionType.memory:
        return MemoryMission(config: config, onComplete: onComplete);
      case MissionType.qrScan:
        return QrMission(config: config, onComplete: onComplete);
      case MissionType.photo:
        return PhotoMission(config: config, onComplete: onComplete);
      case MissionType.steps:
        return StepsMission(config: config, onComplete: onComplete);
      case MissionType.none:
        // No mission — auto-complete immediately.
        WidgetsBinding.instance.addPostFrameCallback((_) => onComplete());
        return const SizedBox.shrink();
    }
  }
}
