import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/permissions.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../data/models/alarm_model.dart';
import '../../data/models/enums.dart';
import '../../data/models/mission_config.dart';
import '../../data/storage.dart';
import '../../services/alarm_service.dart';
import '../../state/providers.dart';
import '../coach/coach_screen.dart';

/// Fully local settings — no accounts, no network. Profile + alarm defaults +
/// permissions + a Buy-Me-a-Coffee support button.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const _coffeeUrl = 'https://buymeacoffee.com/shubhamsarkar';

  late final TextEditingController _name = TextEditingController(
      text: Storage.instance.getSetting<String>('user_name', '') ?? '');

  bool get _vibrate =>
      Storage.instance.getSetting<bool>('default_vibrate', true) ?? true;
  bool get _gentle =>
      Storage.instance.getSetting<bool>('default_gradual', true) ?? true;
  AlarmSoundType get _sound {
    final n = Storage.instance.getSetting<String>('default_sound', 'uplift');
    return AlarmSoundType.values.firstWhere((s) => s.name == n,
        orElse: () => AlarmSoundType.uplift);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            const Text('Settings',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),

            // ---- Profile ----
            _group([
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Your name',
                        style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    TextField(
                      controller: _name,
                      onChanged: (v) =>
                          Storage.instance.setSetting('user_name', v),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: 'Used in accountability alerts',
                      ),
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 22),

            // ---- Alarm defaults ----
            _sectionLabel('DEFAULTS FOR NEW ALARMS'),
            _group([
              ListTile(
                leading: const Icon(Icons.music_note, color: AppColors.accent),
                title: const Text('Default alarm sound'),
                subtitle: Text(_sound.label),
                trailing: const Icon(Icons.chevron_right),
                onTap: _pickSound,
              ),
              const _Line(),
              SwitchListTile(
                value: _vibrate,
                onChanged: (v) => setState(() =>
                    Storage.instance.setSetting('default_vibrate', v)),
                secondary:
                    const Icon(Icons.vibration, color: AppColors.accent),
                title: const Text('Vibrate by default'),
              ),
              const _Line(),
              SwitchListTile(
                value: _gentle,
                onChanged: (v) => setState(() =>
                    Storage.instance.setSetting('default_gradual', v)),
                secondary:
                    const Icon(Icons.trending_up, color: AppColors.accent),
                title: const Text('Gentle wake-up by default'),
                subtitle: const Text('Gradually increase volume'),
              ),
            ]),
            const SizedBox(height: 22),

            // ---- Sleep & permissions ----
            _sectionLabel('ALARM & SLEEP'),
            _group([
              ListTile(
                leading: const Icon(Icons.nightlight_round,
                    color: AppColors.accent),
                title: const Text('Sleep coach'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CoachScreen())),
              ),
              const _Line(),
              ListTile(
                leading:
                    const Icon(Icons.verified_user, color: AppColors.accent),
                title: const Text('Grant alarm permissions'),
                subtitle: const Text(
                    'Notifications, exact alarms, battery exemption'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await Permissions.requestEssential();
                  _toast('Permission requests sent');
                },
              ),
              const _Line(),
              ListTile(
                leading: const Icon(Icons.play_circle_outline,
                    color: AppColors.accent),
                title: const Text('Test alarm in 5 seconds'),
                subtitle: const Text('Preview the ring + mission flow'),
                onTap: _testAlarm,
              ),
            ]),
            const SizedBox(height: 22),

            // ---- About ----
            _sectionLabel('ABOUT'),
            _group([
              ListTile(
                leading:
                    const Icon(Icons.mail_outline, color: AppColors.accent),
                title: const Text('Send feedback'),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () => _launch(
                    'mailto:?subject=WakeDaddy%20feedback'),
              ),
              const _Line(),
              ListTile(
                leading: const Icon(Icons.info_outline, color: AppColors.accent),
                title: const Text('About WakeDaddy'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showAbout,
              ),
            ]),
            const SizedBox(height: 28),

            // ---- Buy me a coffee ----
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _launch(_coffeeUrl),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.local_cafe),
                label: const Text('Buy me a coffee',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 14),
            const Center(
              child: Text('WakeDaddy v1.0.0  •  100% local',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  // ---- helpers ----

  Widget _group(List<Widget> children) => Container(
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16)),
        child: Column(children: children),
      );

  Widget _sectionLabel(String t) => Padding(
        padding: const EdgeInsets.only(left: 6, bottom: 10),
        child: Text(t,
            style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1)),
      );

  void _toast(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m)));

  Future<void> _launch(String url) async {
    final ok = await launchUrl(Uri.parse(url),
        mode: LaunchMode.externalApplication);
    if (!ok) _toast('Could not open link');
  }

  void _pickSound() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 14),
            const Text('Default alarm sound',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            for (final s in AlarmSoundType.values)
              ListTile(
                title: Text(s.label),
                trailing: _sound == s
                    ? const Icon(Icons.check, color: AppColors.accent)
                    : null,
                onTap: () {
                  Storage.instance.setSetting('default_sound', s.name);
                  Navigator.pop(ctx);
                  setState(() {});
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'WakeDaddy',
      applicationVersion: 'v1.0.0',
      applicationLegalese:
          'A local-first alarm app. No accounts, no tracking, no network.',
      children: const [
        SizedBox(height: 12),
        Text('Wake-up missions, sleep coaching, and accountability — '
            'all stored privately on your device.'),
      ],
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
    await ref.read(alarmsProvider.notifier).save(test);
    if (mounted) _toast('Test alarm will ring in 5 seconds…');
  }
}

class _Line extends StatelessWidget {
  const _Line();
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, indent: 16, endIndent: 16);
}
