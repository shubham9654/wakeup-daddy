import 'dart:async';

import 'package:flutter/widgets.dart';

import '../data/storage.dart';

/// Anti-Cheat System.
///
/// Detects the classic ways people defeat a forced alarm:
///   1. **Force-closing the app** — the native `alarm` plugin keeps a
///      "warning notification on kill" so audio survives a swipe-away; on top
///      of that we record an app-lifecycle log here.
///   2. **Phone shutdown / reboot** — `RECEIVE_BOOT_COMPLETED` + the alarm
///      plugin's BootReceiver re-arm alarms after a reboot. We also stamp the
///      last-seen time so a suspicious gap can be flagged the next morning.
///
/// Detected events are stored so the morning summary can call out cheating
/// attempts (and, with Penalty Mode on, trigger the donation).
class AntiCheatService with WidgetsBindingObserver {
  AntiCheatService._();
  static final AntiCheatService instance = AntiCheatService._();

  static const _kLastSeen = 'anticheat_last_seen';
  static const _kEvents = 'anticheat_events';

  Timer? _heartbeat;

  void start() {
    WidgetsBinding.instance.addObserver(this);
    // Heartbeat so a missing gap (shutdown/kill) is detectable on next launch.
    _heartbeat = Timer.periodic(const Duration(seconds: 30), (_) {
      Storage.instance.setSetting(_kLastSeen, DateTime.now().toIso8601String());
    });
    _checkColdStartGap();
  }

  void stop() {
    WidgetsBinding.instance.removeObserver(this);
    _heartbeat?.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      _record('app_killed', 'App was force-closed / detached');
    }
    if (state == AppLifecycleState.paused) {
      Storage.instance.setSetting(_kLastSeen, DateTime.now().toIso8601String());
    }
  }

  void _checkColdStartGap() {
    final raw = Storage.instance.getSetting<String>(_kLastSeen);
    if (raw == null) return;
    final last = DateTime.tryParse(raw);
    if (last == null) return;
    final gap = DateTime.now().difference(last);
    // A gap far longer than our heartbeat while an alarm was pending suggests
    // a shutdown or kill.
    if (gap > const Duration(minutes: 2)) {
      _record('cold_start_gap',
          'App was not running for ${gap.inMinutes} min (possible shutdown)');
    }
  }

  void _record(String type, String detail) {
    debugPrint('[anti-cheat] $type: $detail');
    final events = List<String>.from(
        Storage.instance.getSetting<List>(_kEvents)?.cast<String>() ?? const []);
    events.add('${DateTime.now().toIso8601String()}|$type|$detail');
    // keep last 50
    if (events.length > 50) events.removeRange(0, events.length - 50);
    Storage.instance.setSetting(_kEvents, events);
  }

  List<String> recentEvents() =>
      (Storage.instance.getSetting<List>(_kEvents)?.cast<String>() ?? const [])
          .reversed
          .toList();
}
