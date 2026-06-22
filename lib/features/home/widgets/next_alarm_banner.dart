import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../core/utils.dart';
import '../../../data/models/alarm_model.dart';

/// Hero card showing the soonest upcoming alarm and a friendly countdown.
class NextAlarmBanner extends StatelessWidget {
  final List<AlarmModel> alarms;
  const NextAlarmBanner({super.key, required this.alarms});

  @override
  Widget build(BuildContext context) {
    final enabled = alarms.where((a) => a.enabled).toList();
    if (enabled.isEmpty) {
      return _shell(
        title: 'No alarms armed',
        big: 'You\'re off the clock',
        sub: 'Toggle an alarm on to sleep easy.',
        muted: true,
      );
    }
    enabled.sort((a, b) => a.nextOccurrence().compareTo(b.nextOccurrence()));
    final next = enabled.first;
    final at = next.nextOccurrence();
    return _shell(
      title: 'NEXT ALARM · ${next.label}',
      big: Fmt.time(next.hour, next.minute),
      sub: 'Rings ${Fmt.untilNext(at)}',
      muted: false,
    );
  }

  Widget _shell({
    required String title,
    required String big,
    required String sub,
    required bool muted,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: muted ? null : AppColors.brandGradient,
        color: muted ? AppColors.surface : null,
        borderRadius: BorderRadius.circular(28),
        boxShadow: muted
            ? null
            : [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: .35),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(muted ? Icons.bedtime_outlined : Icons.alarm,
                  size: 16,
                  color: muted
                      ? AppColors.textMuted
                      : Colors.white.withValues(alpha: .9)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    letterSpacing: 1.5,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: muted
                        ? AppColors.textMuted
                        : Colors.white.withValues(alpha: .9),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            big,
            style: TextStyle(
              // A clock value gets the big treatment; a sentence (muted state)
              // is sized down so it doesn't overflow / shout.
              fontSize: muted ? 24 : 40,
              fontWeight: muted ? FontWeight.w700 : FontWeight.w900,
              letterSpacing: muted ? -0.5 : -1,
              color: muted ? AppColors.textPrimary : Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: muted
                  ? AppColors.textMuted
                  : Colors.white.withValues(alpha: .9),
            ),
          ),
        ],
      ),
    );
  }
}
