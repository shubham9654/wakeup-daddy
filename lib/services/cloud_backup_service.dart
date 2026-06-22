import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../data/models/alarm_model.dart';
import '../data/storage.dart';

/// Cloud alarm backup & cross-device sync.
///
/// The interface is Firebase-shaped (Auth uid + a `users/{uid}/alarms` doc).
/// To keep the project building without a `google-services.json`, the default
/// implementation serialises a backup snapshot locally and logs where the
/// Firestore write would go. Swap [_LocalCloud] for a `FirebaseCloud` impl
/// once you've run `flutterfire configure`.
abstract class CloudBackupService {
  static CloudBackupService instance = _LocalCloud();

  bool get isSignedIn;
  Future<void> signIn();
  Future<void> backup(List<AlarmModel> alarms);
  Future<List<AlarmModel>> restore();
}

class _LocalCloud implements CloudBackupService {
  static const _kSnapshot = 'cloud_backup_snapshot';
  static const _kSignedIn = 'cloud_signed_in';

  @override
  bool get isSignedIn =>
      Storage.instance.getSetting<bool>(_kSignedIn, false) ?? false;

  @override
  Future<void> signIn() async {
    await Storage.instance.setSetting(_kSignedIn, true);
    debugPrint('[cloud] anonymous sign-in (stub). Configure Firebase Auth.');
  }

  @override
  Future<void> backup(List<AlarmModel> alarms) async {
    final snapshot = jsonEncode(alarms.map((a) => a.toJson()).toList());
    await Storage.instance.setSetting(_kSnapshot, snapshot);
    debugPrint('[cloud] backed up ${alarms.length} alarms (local snapshot). '
        'Would write to Firestore users/{uid}/alarms.');
  }

  @override
  Future<List<AlarmModel>> restore() async {
    final raw = Storage.instance.getSetting<String>(_kSnapshot);
    if (raw == null) return [];
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return list.map(AlarmModel.fromJson).toList();
  }
}
