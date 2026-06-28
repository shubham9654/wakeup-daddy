import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// WakeDaddy brand palette — Alarmy-style: near-black canvas, a hot red for
/// primary actions, and a cyan accent for toggles/selection.
class AppColors {
  static const Color bg = Color(0xFF000000);
  static const Color surface = Color(0xFF1C1C1E);
  static const Color surfaceAlt = Color(0xFF2A2A2D);
  static const Color primary = Color(0xFFFB4E63); // brand red (the ONLY accent)
  static const Color accent = Color(0xFFFB4E63); // same red — no blue/cyan
  static const Color success = Color(0xFF2DD4A7); // semantic only (correct ✓)
  static const Color warning = Color(0xFFFB4E63); // unified to brand red
  static const Color danger = Color(0xFFFB4E63);
  static const Color textPrimary = Color(0xFFF7F8FA);
  static const Color textMuted = Color(0xFF8A8A8E);

  /// Brand gradient used on hero cards and primary actions — red shades only.
  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFFFB4E63), Color(0xFFFF5C72)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Spacing & shape tokens for a consistent, breathable layout.
class AppSpacing {
  static const double card = 24; // card corner radius
  static const double gap = 14; // default gap between cards
  static const double pad = 20; // screen padding
}

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.card)),
      ),
      switchTheme: SwitchThemeData(
        // White thumb in both states so it's always clearly visible; the track
        // carries the on/off colour (CRED-style smooth pill).
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.accent
              : AppColors.surfaceAlt,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? Colors.transparent
              : AppColors.textMuted.withValues(alpha: .45),
        ),
        trackOutlineWidth: const WidgetStatePropertyAll(1.5),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      // Force the clock/time picker onto the brand red (no default blue).
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.surface,
        dialHandColor: AppColors.primary,
        dialBackgroundColor: AppColors.surfaceAlt,
        hourMinuteColor: WidgetStateColor.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? AppColors.primary.withValues(alpha: .25)
                : AppColors.surfaceAlt),
        hourMinuteTextColor: AppColors.textPrimary,
        dayPeriodColor: WidgetStateColor.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? AppColors.primary.withValues(alpha: .25)
                : Colors.transparent),
        dayPeriodTextColor: AppColors.textPrimary,
        entryModeIconColor: AppColors.primary,
      ),
      datePickerTheme: const DatePickerThemeData(
        backgroundColor: AppColors.surface,
      ),
    );
  }
}
