import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../state/providers.dart';
import '../coach/coach_screen.dart';

/// Sleep tab — "Find out what you did in your sleep" + entry to the sleep coach.
class SleepScreen extends ConsumerWidget {
  const SleepScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(sleepLogsProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            const Text('Sleep',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),

            // ---- Track my sleep hero card ----
            Container(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text('Find out what you did in your sleep',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  const Text('Check your tossing, snoring sounds',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textMuted)),
                  const SizedBox(height: 22),
                  const _WaveformCard(),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const CoachScreen())),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      child: const Text('Track my sleep'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ---- My sleep report ----
            Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CoachScreen())),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 18),
                  child: Row(
                    children: [
                      const Icon(Icons.nightlight_round,
                          color: AppColors.accent),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          logs.isEmpty
                              ? 'My sleep report'
                              : 'My sleep report (${logs.length} nights)',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaveformCard extends StatelessWidget {
  const _WaveformCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('am 01:26',
                  style: TextStyle(
                      color: AppColors.textMuted, fontSize: 13)),
              SizedBox(height: 2),
              Text('Very loud',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14)),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 36,
              child: CustomPaint(painter: _WavePainter()),
            ),
          ),
        ],
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  static const _bars = [
    .3, .5, .2, .7, .4, .9, .35, .6, .25, .8, .45, .5, .3, .65, .4, .55, .2,
    .75, .3, .5, .9, .4, .6, .35, .5, .25, .7, .45, .85, .3, .55, .4,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textMuted
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    final gap = size.width / _bars.length;
    for (var i = 0; i < _bars.length; i++) {
      final x = gap * i + gap / 2;
      final h = size.height * _bars[i];
      canvas.drawLine(
        Offset(x, size.height / 2 - h / 2),
        Offset(x, size.height / 2 + h / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
