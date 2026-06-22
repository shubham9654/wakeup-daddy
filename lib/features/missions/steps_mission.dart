import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';

import '../../core/permissions.dart';
import '../../core/theme.dart';
import '../../data/models/mission_config.dart';
import 'mission_scaffold.dart';

/// Walk a target number of steps (default 100) to dismiss.
class StepsMission extends StatefulWidget {
  final MissionConfig config;
  final VoidCallback onComplete;
  const StepsMission(
      {super.key, required this.config, required this.onComplete});

  @override
  State<StepsMission> createState() => _StepsMissionState();
}

class _StepsMissionState extends State<StepsMission> {
  StreamSubscription<StepCount>? _sub;
  int? _baseline;
  int _walked = 0;
  String? _error;

  int get _target => widget.config.stepCount;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final granted = await Permissions.activityRecognition();
    if (!granted) {
      setState(() => _error =
          'Motion permission is required for the step mission. Enable it in settings.');
      return;
    }
    _sub = Pedometer.stepCountStream.listen(
      (event) {
        _baseline ??= event.steps;
        final delta = event.steps - _baseline!;
        setState(() => _walked = delta.clamp(0, _target));
        if (delta >= _target) {
          _sub?.cancel();
          widget.onComplete();
        }
      },
      onError: (e) => setState(() =>
          _error = 'Step sensor unavailable on this device ($e).'),
      cancelOnError: true,
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MissionScaffold(
      title: 'Walk it off',
      subtitle: 'Take $_target steps to dismiss',
      progress: _walked / _target,
      progressLabel: '$_walked / $_target',
      child: Column(
        children: [
          const Icon(Icons.directions_walk, size: 96, color: AppColors.primary),
          const SizedBox(height: 16),
          Text('$_walked',
              style: const TextStyle(
                  fontSize: 72, fontWeight: FontWeight.w900, height: 1)),
          const Text('steps', style: TextStyle(color: AppColors.textMuted)),
          if (_error != null) ...[
            const SizedBox(height: 24),
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.warning)),
            const SizedBox(height: 12),
            TextButton(
                onPressed: widget.onComplete,
                child: const Text('Skip (sensor unavailable)')),
          ],
        ],
      ),
    );
  }
}
