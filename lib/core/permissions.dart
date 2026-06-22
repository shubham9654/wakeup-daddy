import 'package:permission_handler/permission_handler.dart';

/// Centralised permission requests. We ask for the minimum needed for the
/// features the user has actually enabled, but [requestEssential] covers the
/// baseline an alarm app cannot work without.
class Permissions {
  static Future<void> requestEssential() async {
    await [
      Permission.notification,
      Permission.scheduleExactAlarm,
      Permission.ignoreBatteryOptimizations,
    ].request();
  }

  static Future<bool> camera() async =>
      (await Permission.camera.request()).isGranted;

  static Future<bool> activityRecognition() async =>
      (await Permission.activityRecognition.request()).isGranted;

  static Future<bool> notification() async =>
      (await Permission.notification.request()).isGranted;
}
