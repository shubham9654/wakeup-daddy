import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/models/mission_config.dart';
import 'mission_scaffold.dart';

/// Type a random motivational sentence exactly (case-insensitive, trimmed).
class TypingMission extends StatefulWidget {
  final MissionConfig config;
  final VoidCallback onComplete;
  const TypingMission(
      {super.key, required this.config, required this.onComplete});

  @override
  State<TypingMission> createState() => _TypingMissionState();
}

class _TypingMissionState extends State<TypingMission> {
  static const _sentences = [
    'I am awake and ready to win the day',
    'Rise and grind, the morning is mine',
    'Discipline beats motivation every time',
    'Today I move closer to my goals',
    'No more snooze, only progress',
    'My future self will thank me for this',
  ];

  final _rng = Random();
  final _controller = TextEditingController();
  late String _sentence;
  int _done = 0;
  bool _match = false;

  int get _target => widget.config.repetitions;

  @override
  void initState() {
    super.initState();
    _sentence = _pick();
    _controller.addListener(() {
      final m = _normalize(_controller.text) == _normalize(_sentence);
      if (m != _match) setState(() => _match = m);
    });
  }

  String _pick() => _sentences[_rng.nextInt(_sentences.length)];
  String _normalize(String s) =>
      s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  void _submit() {
    if (_normalize(_controller.text) != _normalize(_sentence)) return;
    setState(() {
      _done++;
      _controller.clear();
      _match = false;
      if (_done >= _target) {
        widget.onComplete();
      } else {
        _sentence = _pick();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MissionScaffold(
      title: 'Type it out',
      subtitle: 'Type the sentence exactly to continue',
      progress: _done / _target,
      progressLabel: '$_done / $_target',
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: .4)),
            ),
            child: Text(
              _sentence,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w600, height: 1.4),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLines: 3,
            minLines: 1,
            textCapitalization: TextCapitalization.none,
            decoration: InputDecoration(
              hintText: 'Type here…',
              filled: true,
              fillColor: AppColors.surfaceAlt,
              suffixIcon: _match
                  ? const Icon(Icons.check_circle, color: AppColors.success)
                  : null,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _match ? _submit : null,
              child: const Text('Next'),
            ),
          ),
        ],
      ),
    );
  }
}
