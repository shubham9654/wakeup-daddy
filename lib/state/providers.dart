import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/alarm_model.dart';
import '../data/models/enums.dart';
import '../data/models/sleep_log.dart';
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

/// Premium / subscription state (revenue model).
class PremiumNotifier extends Notifier<PlanTier> {
  static const _key = 'plan_tier';

  @override
  PlanTier build() {
    final name = Storage.instance.getSetting<String>(_key, PlanTier.free.name);
    return PlanTier.values.byName(name ?? 'free');
  }

  Future<void> setTier(PlanTier tier) async {
    await Storage.instance.setSetting(_key, tier.name);
    state = tier;
  }

  bool get isPremium => state != PlanTier.free;
}

final premiumProvider =
    NotifierProvider<PremiumNotifier, PlanTier>(PremiumNotifier.new);

/// Convenience boolean.
final isPremiumProvider = Provider<bool>((ref) {
  return ref.watch(premiumProvider) != PlanTier.free;
});
