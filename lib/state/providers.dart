import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/alarm_model.dart';
import '../data/models/sleep_log.dart';
import '../data/models/wake_event.dart';
import '../data/storage.dart';
import '../services/alarm_service.dart';
import '../services/cloud_backup_service.dart';

/// Holds and persists the list of alarms, and keeps the OS scheduler in sync.
class AlarmsNotifier extends Notifier<List<AlarmModel>> {
  @override
  List<AlarmModel> build() => Storage.instance.readAlarms();

  Future<void> _persistAndReschedule(AlarmModel a) async {
    await Storage.instance.writeAlarm(a);
    await AlarmService.instance.schedule(a);
    state = Storage.instance.readAlarms();
    _autoBackup();
  }

  Future<void> save(AlarmModel a) => _persistAndReschedule(a);

  Future<void> toggle(int id, bool enabled) async {
    final a = state.firstWhere((x) => x.id == id);
    await _persistAndReschedule(a.copyWith(enabled: enabled));
  }

  Future<void> remove(int id) async {
    await AlarmService.instance.cancel(id);
    await Storage.instance.deleteAlarm(id);
    state = Storage.instance.readAlarms();
    _autoBackup();
  }

  /// Reschedule everything (call on app launch / boot).
  Future<void> rescheduleAll() => AlarmService.instance.rescheduleAll(state);

  AlarmModel? byId(int id) {
    for (final a in state) {
      if (a.id == id) return a;
    }
    return null;
  }

  void _autoBackup() {
    if (CloudBackupService.instance.isSignedIn) {
      CloudBackupService.instance.backup(state);
    }
  }
}

final alarmsProvider =
    NotifierProvider<AlarmsNotifier, List<AlarmModel>>(AlarmsNotifier.new);

/// Sleep history for the AI coach.
class SleepLogsNotifier extends Notifier<List<SleepLog>> {
  @override
  List<SleepLog> build() => Storage.instance.readSleepLogs();

  Future<void> add(SleepLog log) async {
    await Storage.instance.writeSleepLog(log);
    state = Storage.instance.readSleepLogs();
  }
}

final sleepLogsProvider =
    NotifierProvider<SleepLogsNotifier, List<SleepLog>>(SleepLogsNotifier.new);

/// Recorded alarm dismissals — the source of truth for the Report tab.
class WakeEventsNotifier extends Notifier<List<WakeEvent>> {
  @override
  List<WakeEvent> build() => Storage.instance.readWakeEvents();

  Future<void> add(WakeEvent e) async {
    await Storage.instance.writeWakeEvent(e);
    state = Storage.instance.readWakeEvents();
  }
}

final wakeEventsProvider =
    NotifierProvider<WakeEventsNotifier, List<WakeEvent>>(
        WakeEventsNotifier.new);

