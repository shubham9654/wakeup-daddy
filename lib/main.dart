import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/permissions.dart';
import 'data/storage.dart';
import 'services/alarm_service.dart';
import 'services/anticheat_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Storage.instance.init();
  await AlarmService.instance.init();

  // Fire-and-forget: ask for the baseline permissions an alarm app needs.
  Permissions.requestEssential();

  // Anti-cheat heartbeat (detect shutdown / force-close).
  AntiCheatService.instance.start();

  runApp(const ProviderScope(child: WakeDaddyApp()));
}
