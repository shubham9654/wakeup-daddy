import 'package:alarm/alarm.dart';
import 'package:flutter/foundation.dart';

import '../data/models/alarm_model.dart';

/// Wraps the native `alarm` plugin and translates our [AlarmModel] domain
/// objects into the plugin's [AlarmSettings].
///
/// Responsibilities:
///  * scheduling / cancelling exact alarms
///  * gradually increasing volume (fade) and loud enforced playback
///  * vibration (delegated to the plugin) and full-screen ring intent
///  * anti-cheat warning if the user force-kills the app while an alarm is set
class AlarmService {
  AlarmService._();
  static final AlarmService instance = AlarmService._();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await Alarm.init();
    _initialized = true;
  }

  /// Stream of currently ringing alarms. The UI listens to this to push the
  /// full-screen ring experience.
  Stream<AlarmSettings?> get ringingStream =>
      Alarm.ringing.map((set) => set.alarms.isEmpty ? null : set.alarms.first);

  AlarmSettings _toSettings(AlarmModel a, {DateTime? overrideTime}) {
    final fireAt = overrideTime ?? a.nextOccurrence();

    final volume = a.gradualVolume
        ? VolumeSettings.fade(
            fadeDuration: Duration(seconds: a.gradualSeconds),
            volume: a.maxVolume,
            volumeEnforced: true,
          )
        : VolumeSettings.fixed(volume: a.maxVolume, volumeEnforced: true);

    final hasMission = a.mission.type.name != 'none';

    return AlarmSettings(
      id: a.id,
      dateTime: fireAt,
      assetAudioPath: a.sound.asset,
      volumeSettings: volume,
      loopAudio: true,
      vibrate: a.vibrate,
      warningNotificationOnKill: true, // anti-cheat: detect force close
      androidFullScreenIntent: true,
      androidStopAlarmOnTermination: false, // keep ringing if app dies
      notificationSettings: NotificationSettings(
        title: a.label.isEmpty ? 'WakeDaddy' : a.label,
        body: _bodyFor(a),
        // A stop button instantly stops the alarm. Only offer it when there's
        // no mission — otherwise tapping the notification must open the app so
        // the mission can't be skipped from the shade.
        stopButton: hasMission ? null : 'Dismiss',
      ),
      payload: a.id.toString(),
    );
  }

  String _bodyFor(AlarmModel a) {
    if (a.mission.type.name == 'none') return 'Tap to dismiss your alarm.';
    return 'Complete your "${a.mission.type.label}" mission to switch it off.';
  }

  /// Schedule (or reschedule) an alarm at its next occurrence.
  Future<void> schedule(AlarmModel a) async {
    await init();
    if (!a.enabled) {
      await cancel(a.id);
      return;
    }
    try {
      await Alarm.set(alarmSettings: _toSettings(a));
    } catch (e) {
      debugPrint('AlarmService.schedule failed: $e');
    }
  }

  /// Snooze: re-arm the same alarm a few minutes from now.
  Future<void> snooze(AlarmModel a) async {
    await init();
    final next = DateTime.now().add(Duration(minutes: a.snoozeMinutes));
    await Alarm.set(alarmSettings: _toSettings(a, overrideTime: next));
  }

  /// Fully stop a ringing alarm and, if it repeats, schedule the next day.
  Future<void> dismiss(AlarmModel a) async {
    await init();
    await Alarm.stop(a.id);
    if (!a.isOneShot && a.enabled) {
      // schedule next matching weekday (strictly after now)
      final next = a.nextOccurrence(DateTime.now().add(const Duration(minutes: 1)));
      await Alarm.set(alarmSettings: _toSettings(a, overrideTime: next));
    }
  }

  Future<void> cancel(int id) async {
    await init();
    await Alarm.stop(id);
  }

  Future<bool> isRinging(int id) => Alarm.isRinging(id);

  /// Re-sync all stored alarms with the OS scheduler (called on boot/launch).
  Future<void> rescheduleAll(List<AlarmModel> alarms) async {
    await init();
    for (final a in alarms.where((x) => x.enabled)) {
      await schedule(a);
    }
  }
}
