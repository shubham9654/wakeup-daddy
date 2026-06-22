import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Accountability Mode — if the user doesn't dismiss within the grace window,
/// notify a chosen buddy so they can nudge them awake.
///
/// On-device we use an SMS deep-link (no server required). A production build
/// would route this through the WakeDaddy cloud (FCM push to the buddy's app)
/// so it works even if the sleeper's screen is locked — see [sendViaCloud].
class AccountabilityService {
  AccountabilityService._();
  static final AccountabilityService instance = AccountabilityService._();

  Future<void> notifyBuddy({
    required String contact,
    required String sleeperName,
    required String alarmLabel,
  }) async {
    if (contact.trim().isEmpty) return;
    final body = Uri.encodeComponent(
        '$sleeperName ignored their "$alarmLabel" alarm on WakeDaddy. '
        'Give them a call to make sure they\'re up! ⏰');

    // SMS deep link works on both Android and iOS.
    final sms = Uri.parse('sms:$contact?body=$body');
    try {
      if (await canLaunchUrl(sms)) {
        await launchUrl(sms);
        return;
      }
    } catch (e) {
      debugPrint('Accountability SMS failed: $e');
    }
    await sendViaCloud(contact: contact, message: body);
  }

  /// Placeholder for the cloud path (FCM push). Wired up once Firebase is
  /// configured — see lib/services/cloud_backup_service.dart.
  Future<void> sendViaCloud(
      {required String contact, required String message}) async {
    debugPrint('[cloud] would push accountability alert to $contact');
  }
}
