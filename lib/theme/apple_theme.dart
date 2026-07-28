import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppleColors {
  /// Pure iOS White / Light Canvas `#FBFBFD`
  static const scaffoldBackground = Color(0xFFFBFBFD);
  static const pureWhite = Color(0xFFFFFFFF);
  static const surface = Color(0xFFFFFFFF);
  static const background = Color(0xFFFBFBFD);

  /// Light Slate Surface Cards `#F4F4F6`
  static const cardSurface = Color(0xFFF4F4F6);
  static const surfaceAlt = Color(0xFFF4F4F6);

  /// Subtle 1px Border `#E5E5EA`
  static const cardBorder = Color(0xFFE5E5EA);
  static const border = Color(0xFFE5E5EA);
  static const borderMuted = Color(0xFFE5E5EA);

  /// Sizzling Orange Primary Accent `#FF6B00`
  static const primaryAccent = Color(0xFFFF6B00);
  static const primary = Color(0xFFFF6B00);
  static const amber = Color(0xFFFF6B00);
  static const amberSoft = Color(0xFFFF6B00);

  /// Deep Cast-Iron Text Primary `#09090B`
  static const textPrimary = Color(0xFF09090B);
  static const primaryText = Color(0xFF09090B);
  static const cream = Color(0xFF09090B);

  /// UI & Body Text `#18181B`
  static const textBody = Color(0xFF18181B);

  /// SF Grey Muted Text `#8E8E93`
  static const mutedText = Color(0xFF8E8E93);
  static const secondaryText = Color(0xFF8E8E93);
  static const sfGrey = Color(0xFF8E8E93);
  static const muted = Color(0xFF8E8E93);
  static const mutedDark = Color(0xFF8E8E93);

  /// On Primary
  static const onAmber = Color(0xFFFFFFFF);

  /// Feedback colors
  static const danger = Color(0xFFFF3B30);
  static const success = Color(0xFF34C759);

  /// Subtle Apple Ambient Shadow
  static List<BoxShadow> get ambientShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];
}

typedef AppColors = AppleColors;

class AppleTheme {
  /// Trigger light haptic impact feedback for Apple HIG interactions
  static void hapticFeedback() {
    HapticFeedback.lightImpact();
  }

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
    );

    final textTheme = TextTheme(
      displayLarge: GoogleFonts.domine(
        color: AppleColors.textPrimary,
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: GoogleFonts.domine(
        color: AppleColors.textPrimary,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
      displaySmall: GoogleFonts.domine(
        color: AppleColors.textPrimary,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      headlineLarge: GoogleFonts.domine(
        color: AppleColors.textPrimary,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: GoogleFonts.domine(
        color: AppleColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      headlineSmall: GoogleFonts.domine(
        color: AppleColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: GoogleFonts.domine(
        color: AppleColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      titleMedium: GoogleFonts.domine(
        color: AppleColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      titleSmall: GoogleFonts.domine(
        color: AppleColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: GoogleFonts.inter(
        color: AppleColors.textBody,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.inter(
        color: AppleColors.textBody,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
      bodySmall: GoogleFonts.inter(
        color: AppleColors.mutedText,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
      labelLarge: GoogleFonts.inter(
        color: AppleColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: GoogleFonts.inter(
        color: AppleColors.mutedText,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: GoogleFonts.inter(
        color: AppleColors.mutedText,
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      scaffoldBackgroundColor: AppleColors.scaffoldBackground,
      colorScheme: const ColorScheme.light(
        primary: AppleColors.primaryAccent,
        onPrimary: Colors.white,
        secondary: AppleColors.primaryAccent,
        surface: AppleColors.surface,
        onSurface: AppleColors.textPrimary,
        error: AppleColors.danger,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppleColors.pureWhite.withValues(alpha: 0.85),
        foregroundColor: AppleColors.textPrimary,
        surfaceTintColor: AppleColors.pureWhite,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.domine(
          color: AppleColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
        iconTheme: const IconThemeData(color: AppleColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppleColors.cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppleColors.cardBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppleColors.primaryAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppleColors.textPrimary,
          side: const BorderSide(color: AppleColors.cardBorder, width: 1),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppleColors.cardSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: GoogleFonts.inter(
          color: AppleColors.mutedText,
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.inter(
          color: AppleColors.mutedText,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        prefixIconColor: AppleColors.mutedText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppleColors.cardBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppleColors.cardBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppleColors.primaryAccent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppleColors.danger, width: 1),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppleColors.pureWhite,
        selectedItemColor: AppleColors.primaryAccent,
        unselectedItemColor: AppleColors.mutedText,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerColor: AppleColors.cardBorder,
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppleColors.textPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        contentTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
    );
  }

  static ThemeData get dark => light;
}
