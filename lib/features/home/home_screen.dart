import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../data/models/alarm_model.dart';
import '../../state/providers.dart';
import '../edit/edit_alarm_screen.dart';
import 'widgets/alarm_tile.dart';

/// The Alarm tab — home screen: the "Ring in X" countdown header, alarm cards,
/// and a + button that opens a fresh alarm editor (with the time clock).
class AlarmTab extends ConsumerWidget {
  const AlarmTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarms = ref.watch(alarmsProvider);

    final enabled = alarms.where((a) => a.enabled).toList()
      ..sort((a, b) => a.nextOccurrence().compareTo(b.nextOccurrence()));
    final next = enabled.isNotEmpty ? enabled.first : null;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          children: [
            // ---- Title row ----
            Row(
              children: [
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                        fontSize: 26, fontWeight: FontWeight.w800),
                    children: [
                      TextSpan(
                          text: 'Wakeup ',
                          style: TextStyle(color: AppColors.textPrimary)),
                      TextSpan(
                          text: 'Daddy',
                          style: TextStyle(color: AppColors.primary)),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _showOverflow(context, ref),
                  icon: const Icon(Icons.more_horiz,
                      color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ---- Ring in X header ----
            if (next != null)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 14),
                child: Row(
                  children: [
                    Text(
                      'Ring ${Fmt.untilNext(next.nextOccurrence())}',
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right,
                        size: 20, color: AppColors.textMuted),
                  ],
                ),
              ),

            if (alarms.isEmpty)
              _EmptyState(onAdd: () => _openEditor(context, null))
            else
              for (final a in alarms)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AlarmTile(
                    alarm: a,
                    onTap: () => _openEditor(context, a),
                    onToggle: (v) =>
                        ref.read(alarmsProvider.notifier).toggle(a.id, v),
                    onDelete: () =>
                        ref.read(alarmsProvider.notifier).remove(a.id),
                  ),
                ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(context, null, autoPick: true),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _openEditor(BuildContext context, AlarmModel? alarm,
      {bool autoPick = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) =>
              EditAlarmScreen(existing: alarm, autoPickTime: autoPick)),
    );
  }

  void _showOverflow(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.delete_sweep_outlined),
              title: const Text('Delete all alarms'),
              onTap: () {
                Navigator.pop(ctx);
                for (final a in ref.read(alarmsProvider)) {
                  ref.read(alarmsProvider.notifier).remove(a.id);
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          const Icon(Icons.alarm_off, size: 72, color: AppColors.textMuted),
          const SizedBox(height: 16),
          const Text('No alarms yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('Tap + to set your first wake-up alarm.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 20),
          FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Set alarm')),
        ],
      ),
    );
  }
}
