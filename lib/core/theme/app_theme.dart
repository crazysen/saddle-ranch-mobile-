import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const background = Color(0xFFFFFFFF);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF7F7F8);
  static const border = Color(0xFFD6CFC6);
  static const borderMuted = Color(0xFFDCDCDC);
  static const amber = Color(0xFFF59E0B);
  static const amberSoft = Color(0xFF9A3412);
  static const cream = Color(0xFF111111);
  static const muted = Color(0xFF3F3F46);
  static const mutedDark = Color(0xFF52525B);
  static const onAmber = Color(0xFF3F2000);
  static const danger = Color(0xFFDC2626);
  static const success = Color(0xFF16A34A);
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
    );

    final poppinsText = GoogleFonts.poppinsTextTheme(base.textTheme).copyWith(
      bodyLarge: GoogleFonts.poppins(
        color: AppColors.cream,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
      bodyMedium: GoogleFonts.poppins(
        color: AppColors.cream,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
      bodySmall: GoogleFonts.poppins(
        color: AppColors.muted,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.35,
      ),
      titleLarge: GoogleFonts.poppins(
        color: AppColors.cream,
        fontSize: 22,
        fontWeight: FontWeight.w800,
      ),
      titleMedium: GoogleFonts.poppins(
        color: AppColors.cream,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      titleSmall: GoogleFonts.poppins(
        color: AppColors.cream,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      labelLarge: GoogleFonts.poppins(
        color: AppColors.cream,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );

    return base.copyWith(
      textTheme: poppinsText,
      primaryTextTheme: poppinsText,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.amber,
        onPrimary: AppColors.onAmber,
        secondary: AppColors.amberSoft,
        surface: AppColors.surface,
        onSurface: AppColors.cream,
        error: AppColors.danger,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.cream,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          color: AppColors.cream,
          fontWeight: FontWeight.w800,
          fontSize: 20,
        ),
        iconTheme: const IconThemeData(color: AppColors.cream),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceAlt,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderMuted),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.surfaceAlt,
        selectedColor: AppColors.amber,
        labelStyle: GoogleFonts.poppins(
          color: AppColors.cream,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        secondaryLabelStyle: GoogleFonts.poppins(
          color: AppColors.onAmber,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.amber,
          foregroundColor: AppColors.onAmber,
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            letterSpacing: 0.2,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceAlt,
        hintStyle: GoogleFonts.poppins(
          color: AppColors.mutedDark,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.poppins(
          color: AppColors.muted,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        helperStyle: GoogleFonts.poppins(
          color: AppColors.mutedDark,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.amber, width: 1.5),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.amber,
        unselectedItemColor: AppColors.muted,
        type: BottomNavigationBarType.fixed,
      ),
      dividerColor: AppColors.borderMuted,
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.cream,
        contentTextStyle: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        titleTextStyle: GoogleFonts.poppins(
          color: AppColors.cream,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
        contentTextStyle: GoogleFonts.poppins(
          color: AppColors.muted,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
      ),
    );
  }

  /// Kept for any old references; same as light.
  static ThemeData get dark => light;
}
