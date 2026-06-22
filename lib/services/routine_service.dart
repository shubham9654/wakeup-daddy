import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Catalogue of automatable morning-routine steps.
enum RoutineAction {
  meditation('Open meditation app', 'self_improvement'),
  motivation('Play motivational audio', 'campaign'),
  goals('Read daily goals aloud', 'checklist'),
  weather('Show today\'s weather', 'wb_sunny'),
  news('Open news briefing', 'newspaper');

  const RoutineAction(this.label, this.iconName);
  final String label;
  final String iconName;
}

/// Runs the user's "Morning Routine Automation" after an alarm is dismissed.
class RoutineService {
  RoutineService._();
  static final RoutineService instance = RoutineService._();

  final _player = AudioPlayer();

  Future<void> run(List<RoutineAction> actions, {List<String> goals = const []}) async {
    for (final action in actions) {
      try {
        await _runOne(action, goals);
      } catch (e) {
        debugPrint('Routine step ${action.name} failed: $e');
      }
    }
  }

  Future<void> _runOne(RoutineAction action, List<String> goals) async {
    switch (action) {
      case RoutineAction.meditation:
        // Try popular meditation apps via deep link, else fall back to store.
        await _tryLaunch(['headspace://', 'calm://'],
            fallback: 'https://www.headspace.com/');
        break;
      case RoutineAction.motivation:
        await _player.play(AssetSource('audio/gentle.wav'));
        break;
      case RoutineAction.goals:
        // The UI layer reads these aloud via TTS; here we just surface them.
        debugPrint('Daily goals: ${goals.join(', ')}');
        break;
      case RoutineAction.weather:
        await _tryLaunch(['https://weather.com/']);
        break;
      case RoutineAction.news:
        await _tryLaunch(['https://news.google.com/']);
        break;
    }
  }

  Future<void> _tryLaunch(List<String> uris, {String? fallback}) async {
    for (final u in uris) {
      final uri = Uri.parse(u);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }
    if (fallback != null) {
      await launchUrl(Uri.parse(fallback), mode: LaunchMode.externalApplication);
    }
  }
}
