import 'package:flutter/material.dart';

class VwishColors {
  // Backgrounds
  static const Color background = Color(0xFF07080C);
  static const Color surface = Color(0xFF0F1118);
  static const Color surfaceElevated = Color(0xFF181B26);
  static const Color surfaceElevatedHigher = Color(0xFF222636);
  static const Color overlayDark = Color(0xD907080C); // 85% opacity
  static const Color cardGlass = Color(0xCC12141F);

  // Borders
  static const Color border = Color(0xFF262A3B);
  static const Color borderBright = Color(0xFF3B415C);

  // Primary & Accent
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color cyan = Color(0xFF06B6D4);
  static const Color purple = Color(0xFF8B5CF6);

  // Status & Boost
  static const Color boostBand = Color(0xFFF59E0B); // Amber for 100-300%
  static const Color boostBandHigh = Color(0xFFEF4444); // Red for 250-300%
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA0A6BC);
  static const Color textMuted = Color(0xFF6B728D);

  // Buffer
  static const Color bufferTrack = Color(0x664A5173);
  static const Color trackBackground = Color(0x33353A52);
}

class VwishTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: VwishColors.background,
      colorScheme: const ColorScheme.dark(
        primary: VwishColors.primary,
        secondary: VwishColors.cyan,
        surface: VwishColors.surface,
        error: VwishColors.error,
        onPrimary: Colors.white,
        onSurface: VwishColors.textPrimary,
      ),
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: VwishColors.textPrimary,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: VwishColors.textPrimary,
          letterSpacing: -0.3,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: VwishColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: VwishColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: VwishColors.textSecondary,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: VwishColors.textMuted,
        ),
      ),
      iconTheme: const IconThemeData(
        color: VwishColors.textPrimary,
        size: 20,
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: VwishColors.primary,
        inactiveTrackColor: VwishColors.trackBackground,
        thumbColor: Colors.white,
        trackHeight: 3.0,
      ),
    );
  }
}
