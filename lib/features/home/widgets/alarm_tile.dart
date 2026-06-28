import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../core/utils.dart';
import '../../../core/wallpapers.dart';
import '../../../core/widgets/premium_switch.dart';
import '../../../data/models/alarm_model.dart';
import '../../../data/models/enums.dart';

class AlarmTile extends StatelessWidget {
  final AlarmModel alarm;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  const AlarmTile({
    super.key,
    required this.alarm,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final on = alarm.enabled;
    final timeColor = on ? AppColors.textPrimary : AppColors.textMuted;
    // Highlight enabled alarms with a subtle primary-tinted background + border.
    final cardColor =
        on ? Color.lerp(AppColors.surface, AppColors.primary, .12)! : AppColors.surface;
    final borderColor =
        on ? AppColors.primary.withValues(alpha: .45) : Colors.transparent;

    return Dismissible(
      key: ValueKey(alarm.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 28),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: .85),
          borderRadius: BorderRadius.circular(AppSpacing.card),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => onDelete(),
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppSpacing.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.card),
          onTap: onTap,
          onLongPress: () => _showActions(context),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.card),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            padding: const EdgeInsets.fromLTRB(22, 18, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ---- Time (left) + toggle (right) ----
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            Fmt.time(alarm.hour, alarm.minute)
                                .replaceAll(RegExp(r' (AM|PM)'), ''),
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                              color: timeColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            alarm.hour < 12 ? 'AM' : 'PM',
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    PremiumSwitch(value: on, onChanged: onToggle),
                  ],
                ),
                const SizedBox(height: 6),
                // ---- Wallpaper swatch + label ----
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            WallpaperView(Wallpapers.byIndex(alarm.wallpaper)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        alarm.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                            fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // ---- Chips (left) + delete (right), space-between ----
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _chip(Icons.repeat, Fmt.repeatLabel(alarm)),
                          if (alarm.mission.type != MissionType.none)
                            _chip(Icons.flag, alarm.mission.type.label,
                                color: AppColors.accent),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        if (await _confirmDelete(context)) onDelete();
                      },
                      icon: const Icon(Icons.delete_outline,
                          size: 20, color: AppColors.textMuted),
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Delete alarm',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label,
      {Color color = AppColors.textMuted}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete alarm?'),
            content: Text(
                '"${alarm.label}" at ${Fmt.time(alarm.hour, alarm.minute)}'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
              FilledButton(
                  style:
                      FilledButton.styleFrom(backgroundColor: AppColors.danger),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete')),
            ],
          ),
        ) ??
        false;
  }

  /// Long-press menu: clear, explicit Edit / Delete actions.
  void _showActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: .4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit alarm'),
              onTap: () {
                Navigator.pop(sheetContext);
                onTap();
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline, color: AppColors.danger),
              title: const Text('Delete alarm',
                  style: TextStyle(color: AppColors.danger)),
              onTap: () async {
                Navigator.pop(sheetContext);
                if (await _confirmDelete(context)) onDelete();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
