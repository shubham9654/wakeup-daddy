import 'dart:convert';

import 'package:hive_ce_flutter/hive_flutter.dart';

import 'models/alarm_model.dart';
import 'models/sleep_log.dart';
import 'models/wake_event.dart';

/// Thin persistence layer over Hive CE. Everything is stored as JSON strings
/// so we never need generated TypeAdapters — the models own their (de)serialization.
class Storage {
  static const _alarmsBox = 'alarms';
  static const _sleepBox = 'sleep_logs';
  static const _wakeBox = 'wake_events';
  static const _settingsBox = 'settings';

  late final Box<String> alarms;
  late final Box<String> sleepLogs;
  late final Box<String> wakeEvents;
  late final Box settings;

  static final Storage instance = Storage._();
  Storage._();

  Future<void> init() async {
    await Hive.initFlutter();
    alarms = await Hive.openBox<String>(_alarmsBox);
    sleepLogs = await Hive.openBox<String>(_sleepBox);
    wakeEvents = await Hive.openBox<String>(_wakeBox);
    settings = await Hive.openBox(_settingsBox);
  }

  // ---- Alarms ----
  List<AlarmModel> readAlarms() {
    return alarms.values
        .map((s) => AlarmModel.fromJson(jsonDecode(s)))
        .toList()
      ..sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
  }

  Future<void> writeAlarm(AlarmModel a) =>
      alarms.put(a.id.toString(), jsonEncode(a.toJson()));

  Future<void> deleteAlarm(int id) => alarms.delete(id.toString());

  // ---- Sleep logs ----
  List<SleepLog> readSleepLogs() => sleepLogs.values
      .map((s) => SleepLog.fromJson(jsonDecode(s)))
      .toList()
    ..sort((a, b) => b.wakeAt.compareTo(a.wakeAt));

  Future<void> writeSleepLog(SleepLog log) =>
      sleepLogs.put(log.id, jsonEncode(log.toJson()));

  // ---- Wake events ----
  List<WakeEvent> readWakeEvents() => wakeEvents.values
      .map((s) => WakeEvent.fromJson(jsonDecode(s)))
      .toList()
    ..sort((a, b) => b.dismissedAt.compareTo(a.dismissedAt));

  Future<void> writeWakeEvent(WakeEvent e) =>
      wakeEvents.put(e.id, jsonEncode(e.toJson()));

  // ---- Settings (key/value) ----
  T? getSetting<T>(String key, [T? fallback]) =>
      (settings.get(key) as T?) ?? fallback;

  Future<void> setSetting(String key, dynamic value) =>
      settings.put(key, value);
}
