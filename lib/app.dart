import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/permissions.dart';
import 'core/theme.dart';
import 'features/ring/ring_screen.dart';
import 'features/shell/main_shell.dart';
import 'services/alarm_service.dart';
import 'state/providers.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class WakeDaddyApp extends ConsumerStatefulWidget {
  const WakeDaddyApp({super.key});

  @override
  ConsumerState<WakeDaddyApp> createState() => _WakeDaddyAppState();
}

class _WakeDaddyAppState extends ConsumerState<WakeDaddyApp> {
  StreamSubscription<AlarmSettings?>? _ringSub;
  bool _ringScreenOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Re-arm any stored alarms with the OS after launch/boot.
      ref.read(alarmsProvider.notifier).rescheduleAll();
      // No onboarding — make sure alarm permissions are requested once.
      Permissions.requestEssential();
    });

    _ringSub = AlarmService.instance.ringingStream.listen((settings) {
      if (settings != null && !_ringScreenOpen) {
        _openRing(settings.id);
      }
    });
  }

  Future<void> _openRing(int alarmId) async {
    final alarm = ref.read(alarmsProvider.notifier).byId(alarmId);
    if (alarm == null) return;

    // On a cold start triggered by the alarm, the Navigator may not be mounted
    // yet — wait for it before pushing the ring screen.
    final nav = navigatorKey.currentState;
    if (nav == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openRing(alarmId));
      return;
    }

    _ringScreenOpen = true;
    await nav.push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => RingScreen(alarm: alarm),
      ),
    );
    _ringScreenOpen = false;
  }

  @override
  void dispose() {
    _ringSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wakeup Daddy',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: AppTheme.dark,
      home: const MainShell(),
    );
  }
}
