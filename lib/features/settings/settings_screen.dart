import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../data/models/alarm_model.dart';
import '../../data/models/enums.dart';
import '../../data/models/mission_config.dart';
import '../../data/storage.dart';
import '../../services/alarm_service.dart';
import '../../services/anticheat_service.dart';
import '../../services/cloud_backup_service.dart';
import '../../state/providers.dart';
import '../premium/paywall_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final premium = ref.watch(isPremiumProvider);
    final tier = ref.watch(premiumProvider);
    final cloud = CloudBackupService.instance;
    final events = AntiCheatService.instance.recentEvents();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.pad, 4, AppSpacing.pad, 32),
        children: [
          // Subscription status
          Card(
            child: ListTile(
              leading: Icon(
                  premium ? Icons.workspace_premium : Icons.lock_open,
                  color: premium ? AppColors.warning : AppColors.textMuted),
              title: Text(premium
                  ? '${tier.name[0].toUpperCase()}${tier.name.substring(1)} plan active'
                  : 'Free plan'),
              subtitle: Text(premium
                  ? 'All features unlocked'
                  : 'Upgrade to unlock premium features'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PaywallScreen())),
            ),
          ),

          _header('Profile'),
          _textSetting('Your name', 'user_name', 'Used in accountability alerts'),
          const SizedBox(height: 10),
          _textSetting('Penalty charity', 'penalty_charity', 'Where penalties are donated'),

          _header('Cloud backup & sync'),
          Card(
            child: SwitchListTile(
              value: cloud.isSignedIn,
              activeThumbColor: AppColors.primary,
              title: const Text('Cloud alarm backup'),
              subtitle: Text(cloud.isSignedIn
                  ? 'Alarms auto-sync on every change'
                  : 'Sign in to back up your alarms'),
              onChanged: (v) async {
                if (v) {
                  await cloud.signIn();
                  await cloud.backup(ref.read(alarmsProvider));
                }
                setState(() {});
              },
            ),
          ),
          if (cloud.isSignedIn) ...[
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: const Icon(Icons.cloud_download),
                title: const Text('Restore from cloud'),
                onTap: () async {
                  final restored = await cloud.restore();
                  for (final a in restored) {
                    await ref.read(alarmsProvider.notifier).save(a);
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Restored ${restored.length} alarms')));
                  }
                },
              ),
            ),
          ],

          _header('Anti-cheat log'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: events.isEmpty
                  ? const Text('No suspicious events detected. 🛡️',
                      style: TextStyle(color: AppColors.textMuted))
                  : Column(
                      children: events.take(10).map((e) {
                        final parts = e.split('|');
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.warning_amber,
                              color: AppColors.warning),
                          title: Text(parts.length > 2 ? parts[2] : e),
                          subtitle: Text(parts.first),
                        );
                      }).toList(),
                    ),
            ),
          ),

          _header('Developer / testing'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.play_circle_outline),
              title: const Text('Test alarm in 5 seconds'),
              subtitle: const Text('Preview the ring + mission flow now'),
              onTap: _testAlarm,
            ),
          ),

          const SizedBox(height: 24),
          const Center(
            child: Text('WakeDaddy v1.0.0',
                style: TextStyle(color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }

  Widget _header(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
        child: Text(text.toUpperCase(),
            style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2)),
      );

  Widget _textSetting(String label, String key, String hint) {
    final controller = TextEditingController(
        text: Storage.instance.getSetting<String>(key, '') ?? '');
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            helperText: hint,
            border: InputBorder.none,
          ),
          onChanged: (v) => Storage.instance.setSetting(key, v),
        ),
      ),
    );
  }

  Future<void> _testAlarm() async {
    final now = DateTime.now().add(const Duration(seconds: 5));
    final test = AlarmModel(
      id: Fmt.newAlarmId(),
      label: 'Test alarm',
      hour: now.hour,
      minute: now.minute,
      mission: const MissionConfig(type: MissionType.math),
      ephemeral: true,
      createdAt: DateTime.now(),
    );
    // Schedule directly via the plugin for an exact 5s preview.
    await AlarmService.instance.init();
    await Alarm.set(
      alarmSettings: AlarmSettings(
        id: test.id,
        dateTime: now,
        assetAudioPath: test.sound.asset,
        volumeSettings: VolumeSettings.fade(
            fadeDuration: const Duration(seconds: 5), volumeEnforced: true),
        notificationSettings: const NotificationSettings(
          title: 'WakeDaddy test',
          body: 'Complete the mission to dismiss',
        ),
      ),
    );
    // Register so the ring listener can resolve it.
    await ref.read(alarmsProvider.notifier).save(test);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Test alarm will ring in 5 seconds…')));
    }
  }
}
