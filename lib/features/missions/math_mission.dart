import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../data/models/mission_config.dart';
import '../../data/models/enums.dart';
import 'mission_scaffold.dart';

/// Solve a series of math problems. Difficulty controls the operand size and
/// whether multiplication is involved.
class MathMission extends StatefulWidget {
  final MissionConfig config;
  final VoidCallback onComplete;
  const MathMission({super.key, required this.config, required this.onComplete});

  @override
  State<MathMission> createState() => _MathMissionState();
}

class _MathMissionState extends State<MathMission> {
  final _rng = Random();
  final _controller = TextEditingController();
  late _Problem _problem;
  int _solved = 0;

  int get _target => widget.config.repetitions;

  @override
  void initState() {
    super.initState();
    _problem = _generate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  _Problem _generate() {
    switch (widget.config.difficulty) {
      case MissionDifficulty.easy:
        // Small single/low-double digit plus & minus, never negative.
        final a = _rng.nextInt(9) + 1;
        final b = _rng.nextInt(9) + 1;
        if (_rng.nextBool()) {
          return _Problem('$a + $b', a + b);
        }
        final hi = a >= b ? a : b;
        final lo = a >= b ? b : a;
        return _Problem('$hi − $lo', hi - lo);
      case MissionDifficulty.medium:
        final a = _rng.nextInt(40) + 10;
        final b = _rng.nextInt(40) + 10;
        final op = _rng.nextBool();
        return op
            ? _Problem('$a + $b', a + b)
            : _Problem('${a + b} − $b', a);
      case MissionDifficulty.hard:
        final a = _rng.nextInt(12) + 4;
        final b = _rng.nextInt(12) + 4;
        final c = _rng.nextInt(20) + 5;
        return _Problem('$a × $b + $c', a * b + c);
    }
  }

  void _submit() {
    final answer = int.tryParse(_controller.text.trim());
    if (answer == _problem.answer) {
      HapticFeedback.lightImpact();
      setState(() {
        _solved++;
        _controller.clear();
        if (_solved >= _target) {
          widget.onComplete();
        } else {
          _problem = _generate();
        }
      });
    } else {
      HapticFeedback.heavyImpact();
      _controller.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Wrong — try again'),
            duration: Duration(milliseconds: 700)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MissionScaffold(
      title: 'Solve to wake up',
      progress: _solved / _target,
      progressLabel: '$_solved / $_target',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _problem.text,
            style: const TextStyle(
                fontSize: 56, fontWeight: FontWeight.w800, letterSpacing: 1),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9-]'))],
            decoration: InputDecoration(
              hintText: '?',
              filled: true,
              fillColor: AppColors.surfaceAlt,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: _submit, child: const Text('Check')),
          ),
        ],
      ),
    );
  }
}

class _Problem {
  final String text;
  final int answer;
  _Problem(this.text, this.answer);
}
