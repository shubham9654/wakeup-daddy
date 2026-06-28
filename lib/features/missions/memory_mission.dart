import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/models/enums.dart';
import '../../data/models/mission_config.dart';
import 'mission_scaffold.dart';

/// Classic memory match game. Flip cards to find all the icon pairs.
class MemoryMission extends StatefulWidget {
  final MissionConfig config;
  final VoidCallback onComplete;
  const MemoryMission(
      {super.key, required this.config, required this.onComplete});

  @override
  State<MemoryMission> createState() => _MemoryMissionState();
}

class _MemoryMissionState extends State<MemoryMission> {
  static const _icons = <IconData>[
    Icons.local_fire_department,
    Icons.bolt,
    Icons.wb_sunny,
    Icons.alarm,
    Icons.rocket_launch,
    Icons.star,
    Icons.favorite,
    Icons.flag,
    Icons.diamond,
    Icons.pets,
  ];

  late List<IconData> _deck;
  final Set<int> _matched = {};
  final List<int> _flipped = [];
  bool _busy = false;

  int get _pairs {
    switch (widget.config.difficulty) {
      case MissionDifficulty.easy:
        return 3;
      case MissionDifficulty.medium:
        return 4;
      case MissionDifficulty.hard:
        return 6;
    }
  }

  @override
  void initState() {
    super.initState();
    final rng = Random();
    final chosen = (_icons.toList()..shuffle(rng)).take(_pairs).toList();
    _deck = [...chosen, ...chosen]..shuffle(rng);
  }

  void _tap(int i) async {
    if (_busy || _flipped.contains(i) || _matched.contains(i)) return;
    setState(() => _flipped.add(i));
    if (_flipped.length == 2) {
      _busy = true;
      final a = _flipped[0], b = _flipped[1];
      if (_deck[a] == _deck[b]) {
        setState(() {
          _matched.addAll([a, b]);
          _flipped.clear();
          _busy = false;
        });
        if (_matched.length == _deck.length) widget.onComplete();
      } else {
        await Future.delayed(const Duration(milliseconds: 700));
        if (!mounted) return;
        setState(() {
          _flipped.clear();
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cols = _pairs <= 3 ? 3 : 4;
    return MissionScaffold(
      title: 'Find the pairs',
      subtitle: 'Match every card to dismiss',
      progress: _matched.length / _deck.length,
      progressLabel: '${_matched.length ~/ 2} / $_pairs',
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _deck.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: .85,
        ),
        itemBuilder: (_, i) {
          final revealed = _flipped.contains(i) || _matched.contains(i);
          return GestureDetector(
            onTap: () => _tap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: _matched.contains(i)
                    ? AppColors.success.withValues(alpha: .25)
                    : revealed
                        ? AppColors.surfaceAlt
                        : AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: revealed
                  ? Icon(_deck[i], size: 36, color: Colors.white)
                  : const SizedBox.shrink(),
            ),
          );
        },
      ),
    );
  }
}
