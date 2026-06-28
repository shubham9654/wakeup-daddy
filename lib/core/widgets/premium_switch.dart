import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// A smooth, spring-animated pill toggle in the spirit of premium fintech apps.
/// White thumb that glides, track that fills with the brand gradient when on.
class PremiumSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const PremiumSwitch({super.key, required this.value, required this.onChanged});

  static const double _w = 54;
  static const double _h = 32;
  static const double _pad = 3;

  @override
  Widget build(BuildContext context) {
    final thumb = _h - _pad * 2;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        onChanged(!value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutBack,
        width: _w,
        height: _h,
        padding: const EdgeInsets.all(_pad),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_h),
          color: value ? AppColors.accent : AppColors.surfaceAlt,
          border: value
              ? null
              : Border.all(
                  color: AppColors.textMuted.withValues(alpha: .35), width: 1.5),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutBack,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: thumb,
            height: thumb,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .25),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
