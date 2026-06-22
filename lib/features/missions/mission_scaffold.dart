import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Shared chrome for every dismiss mission: a title, a progress bar, and the
/// mission body centred on screen. Keeps the missions visually consistent.
class MissionScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double progress; // 0..1
  final String? progressLabel;
  final Widget child;

  const MissionScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.progress,
    this.progressLabel,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Text(title,
                style: const TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w800)),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!,
                  style: const TextStyle(color: AppColors.textMuted)),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0, 1),
                      minHeight: 10,
                      backgroundColor: AppColors.surfaceAlt,
                      color: AppColors.success,
                    ),
                  ),
                ),
                if (progressLabel != null) ...[
                  const SizedBox(width: 12),
                  Text(progressLabel!,
                      style:
                          const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ],
            ),
            Expanded(child: Center(child: SingleChildScrollView(child: child))),
          ],
        ),
      ),
    );
  }
}
