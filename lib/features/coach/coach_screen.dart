import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../data/storage.dart';
import '../../services/sleep_coach_service.dart';
import '../../state/providers.dart';

/// AI Wake-Up Coach dashboard: pattern insight + bedtime recommendation + log.
class CoachScreen extends ConsumerWidget {
  const CoachScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(sleepLogsProvider);
    final alarms = ref.watch(alarmsProvider);

    // Use the soonest enabled alarm as the target wake time, else 7:00.
    final enabled = alarms.where((a) => a.enabled).toList()
      ..sort((a, b) => a.nextOccurrence().compareTo(b.nextOccurrence()));
    final wake = enabled.isNotEmpty
        ? TimeOfDayLite(enabled.first.hour, enabled.first.minute)
        : const TimeOfDayLite(7, 0);

    final insight = SleepCoachService.instance.analyze(logs, wakeTime: wake);

    return Scaffold(
      appBar: AppBar(title: const Text('AI Wake-Up Coach')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.pad, 4, AppSpacing.pad, 32),
        children: [
          _InsightCard(insight: insight),
          const SizedBox(height: AppSpacing.gap),
          _bedtimeCheckIn(context, ref),
          const SizedBox(height: 28),
          _sectionHeader('RECENT NIGHTS'),
          const SizedBox(height: 12),
          if (logs.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                    'No sleep data yet. Dismiss a few alarms and check in your bedtime to train your coach.',
                    style: TextStyle(color: AppColors.textMuted)),
              ),
            )
          else
            ...logs.take(10).map((l) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.nightlight_round,
                          color: AppColors.primary),
                      title: Text(
                          '${l.duration.inHours}h ${l.duration.inMinutes % 60}m sleep'),
                      subtitle: Text(
                          '${DateFormat('EEE d MMM').format(l.wakeAt)} • woke ${DateFormat('h:mm a').format(l.wakeAt)}'),
                      trailing: l.snoozeCount > 0
                          ? Chip(
                              label: Text('${l.snoozeCount}× snooze'),
                              backgroundColor:
                                  AppColors.warning.withValues(alpha: .2),
                            )
                          : null,
                    ),
                  ),
                )),
        ],
      ),
    );
  }

  Widget _sectionHeader(String text) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(text,
            style: const TextStyle(
                letterSpacing: 1.5,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted)),
      );

  Widget _bedtimeCheckIn(BuildContext context, WidgetRef ref) {
    final saved = Storage.instance.getSetting<String>('last_bedtime');
    final parsed = saved == null ? null : DateTime.tryParse(saved);
    return Card(
      child: ListTile(
        leading: const Icon(Icons.bedtime, color: AppColors.accent),
        title: const Text('Going to bed now'),
        subtitle: Text(parsed != null
            ? 'Last check-in: ${DateFormat('EEE h:mm a').format(parsed)}'
            : 'Tap to log your bedtime so the coach can learn'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          await Storage.instance
              .setSetting('last_bedtime', DateTime.now().toIso8601String());
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sleep well. Bedtime logged.')));
            ref.invalidate(sleepLogsProvider);
          }
        },
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final SleepInsight insight;
  const _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(insight.headline,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Row(
            children: [
              _stat('Optimal bedtime', insight.recommendedBedtime.format(),
                  AppColors.accent),
              const SizedBox(width: 12),
              _stat(
                  'Sleep need',
                  '${insight.recommendedSleepNeed.inHours}h${(insight.recommendedSleepNeed.inMinutes % 60).toString().padLeft(2, '0')}m',
                  AppColors.primary),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            insight.detail,
            style: const TextStyle(color: AppColors.textMuted, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

