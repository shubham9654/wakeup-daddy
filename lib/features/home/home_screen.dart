import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../data/models/alarm_model.dart';
import '../../state/providers.dart';
import '../coach/coach_screen.dart';
import '../edit/edit_alarm_screen.dart';
import '../premium/paywall_screen.dart';
import '../settings/settings_screen.dart';
import 'widgets/alarm_tile.dart';
import 'widgets/next_alarm_banner.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarms = ref.watch(alarmsProvider);
    final premium = ref.watch(isPremiumProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Wake'),
            Text('Daddy',
                style: TextStyle(
                    color: AppColors.accent, fontWeight: FontWeight.w800)),
          ],
        ),
        actions: [
          _NavIcon(
            icon: Icons.insights_outlined,
            tooltip: 'Sleep coach',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CoachScreen())),
          ),
          _NavIcon(
            icon: premium ? Icons.workspace_premium : Icons.bolt_outlined,
            tooltip: premium ? 'Premium active' : 'Go premium',
            color: premium ? AppColors.warning : null,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PaywallScreen())),
          ),
          _NavIcon(
            icon: Icons.settings_outlined,
            tooltip: 'Settings',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, null),
        icon: const Icon(Icons.add),
        label: const Text('New alarm'),
      ),
      body: alarms.isEmpty
          ? _EmptyState(onAdd: () => _openEditor(context, null))
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pad, 4, AppSpacing.pad, 110),
              children: [
                NextAlarmBanner(alarms: alarms),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 12),
                  child: Text(
                    'YOUR ALARMS',
                    style: TextStyle(
                      letterSpacing: 1.5,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                for (final a in alarms)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.gap),
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
    );
  }

  void _openEditor(BuildContext context, AlarmModel? alarm) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditAlarmScreen(existing: alarm)),
    );
  }
}

/// A soft, tappable circular icon button for the app bar.
class _NavIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color? color;
  final VoidCallback onTap;
  const _NavIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.only(left: 6),
        child: Material(
          color: AppColors.surface,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(9),
              child: Icon(icon, size: 20, color: color ?? AppColors.textPrimary),
            ),
          ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bedtime, size: 96, color: AppColors.primary),
            const SizedBox(height: 24),
            Text('No alarms yet',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text(
              'Add your first alarm and pick a wake-up mission that actually gets you out of bed.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_alarm),
              label: const Text('Create alarm'),
            ),
            const SizedBox(height: 16),
            Text('Today is ${DateFormat('EEEE, d MMM').format(DateTime.now())}',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
