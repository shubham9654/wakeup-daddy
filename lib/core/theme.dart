import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// WakeDaddy brand palette — dark, high-contrast, made to be readable at 6 AM.
class AppColors {
  static const Color bg = Color(0xFF0B0E14);
  static const Color surface = Color(0xFF151A23);
  static const Color surfaceAlt = Color(0xFF1E2530);
  static const Color primary = Color(0xFF6C5CE7); // electric indigo
  static const Color accent = Color(0xFF9B8CFF); // soft violet
  static const Color success = Color(0xFF2DD4A7);
  static const Color warning = Color(0xFFF5D547); // clean yellow (no orange)
  static const Color danger = Color(0xFFFF5A6A);
  static const Color textPrimary = Color(0xFFF4F6FB);
  static const Color textMuted = Color(0xFF8089A0);

  /// Brand gradient used on hero cards and primary actions.
  static const LinearGradient brandGradient = LinearGradient(
    colors: [primary, accent],
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
              ? AppColors.primary
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
    );
  }
}
