import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../state/providers.dart';
import '../coach/coach_screen.dart';
import '../report/report_screen.dart';

/// Morning tab — a local, network-free "start your day" hub: time-based
/// greeting, quick links, and a daily motivational card.
class MorningScreen extends ConsumerWidget {
  const MorningScreen({super.key});

  static const _quotes = [
    'Win the morning, win the day.',
    'The way you start your morning sets the tone for everything.',
    'Discipline is choosing what you want most over what you want now.',
    'You don\'t have to be extreme, just consistent.',
    'Every morning is a fresh start — make it count.',
    'Small habits, done daily, become your future.',
    'Wake up with determination, go to bed with satisfaction.',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12
        ? 'Good morning'
        : (hour < 17 ? 'Good afternoon' : 'Good evening');
    final quote = _quotes[now.weekday % _quotes.length];

    final alarms = ref.watch(alarmsProvider);
    final enabled = alarms.where((a) => a.enabled).toList()
      ..sort((a, b) => a.nextOccurrence().compareTo(b.nextOccurrence()));

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ---- Greeting header ----
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).padding.top + 28, 20, 30),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFB4E63), Color(0xFFFF5C72)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat('EEEE, d MMMM').format(now),
                    style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 6),
                Text(greeting,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  enabled.isEmpty
                      ? 'No alarms armed'
                      : 'Next alarm at '
                          '${_fmt(enabled.first.hour, enabled.first.minute)}',
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---- Quick tiles ----
                Row(
                  children: [
                    _QuickTile(
                        icon: Icons.sentiment_satisfied_alt,
                        label: 'Morning\nfeeling',
                        onTap: () => _mood(context)),
                    _QuickTile(
                        icon: Icons.format_quote,
                        label: 'Daily\nquote',
                        onTap: () => _showQuote(context, quote)),
                    _QuickTile(
                        icon: Icons.assignment,
                        label: 'Alarm\nreport',
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ReportScreen()))),
                    _QuickTile(
                        icon: Icons.insights,
                        label: 'Sleep\nanalysis',
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const CoachScreen()))),
                  ],
                ),
                const SizedBox(height: 20),

                // ---- Daily motivation card ----
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3A1D24), Color(0xFF1C1C1E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.auto_awesome,
                          color: AppColors.primary),
                      const SizedBox(height: 12),
                      Text(quote,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              height: 1.3)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ---- Pull-yourself-together card ----
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Take a minute to pull yourself together.',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w800)),
                      SizedBox(height: 10),
                      Text(
                          'A short morning routine helps shake off grogginess and start the day with intention.',
                          style: TextStyle(color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(int h, int m) {
    final hh = h % 12 == 0 ? 12 : h % 12;
    final ampm = h < 12 ? 'am' : 'pm';
    return '$hh:${m.toString().padLeft(2, '0')} $ampm';
  }

  void _showQuote(BuildContext context, String quote) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Daily motivation'),
        content: Text(quote, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }

  void _mood(BuildContext context) {
    const moods = <IconData>[
      Icons.sentiment_very_satisfied,
      Icons.sentiment_satisfied,
      Icons.sentiment_neutral,
      Icons.sentiment_dissatisfied,
      Icons.sentiment_very_dissatisfied,
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('How do you feel this morning?',
                  style:
                      TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final m in moods)
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Mood logged')));
                      },
                      child: Icon(m, color: AppColors.primary, size: 40),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickTile(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              height: 58,
              width: 58,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: .18),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, height: 1.2)),
          ],
        ),
      ),
    );
  }
}
