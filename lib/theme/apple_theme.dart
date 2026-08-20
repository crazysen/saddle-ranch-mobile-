import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppleColors {
  /// Pure White / Light Canvas `#FBFBFD`
  static const scaffoldBackground = Color(0xFFFBFBFD);
  static const pureWhite = Color(0xFFFFFFFF);
  static const surface = Color(0xFFFFFFFF);
  static const background = Color(0xFFFBFBFD);

  /// Light Slate Surface Cards `#FFFFFF` / `#F4F4F6`
  static const cardSurface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF4F4F6);

  /// Subtle 1px Border `#E5E7EB`
  static const cardBorder = Color(0xFFE5E7EB);
  static const border = Color(0xFFE5E7EB);
  static const borderMuted = Color(0xFFE5E7EB);

  /// Saddle Ranch Vibrant Amber / Orange Primary Accent `#F59E0B`
  static const primaryAccent = Color(0xFFF59E0B);
  static const primary = Color(0xFFF59E0B);
  static const amber = Color(0xFFF59E0B);
  static const amberSoft = Color(0xFFF59E0B);
  static const secondary = Color(0xFFFFC174);

  /// Deep Cast-Iron Charcoal Text Primary `#1F2937`
  static const textPrimary = Color(0xFF1F2937);
  static const primaryText = Color(0xFF1F2937);
  static const cream = Color(0xFF1F2937);

  /// UI & Body Text `#374151`
  static const textBody = Color(0xFF374151);

  /// Muted Text `#6B7280` / `#8E8E93`
  static const mutedText = Color(0xFF6B7280);
  static const secondaryText = Color(0xFF6B7280);
  static const sfGrey = Color(0xFF6B7280);
  static const muted = Color(0xFF6B7280);
  static const mutedDark = Color(0xFF6B7280);

  /// On Primary
  static const onAmber = Color(0xFFFFFFFF);

  /// Feedback colors
  static const danger = Color(0xFFF43F5E);
  static const error = Color(0xFFF43F5E);
  static const success = Color(0xFF10B981);

  /// Ambient Shadow
  static List<BoxShadow> get ambientShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];
}

typedef AppColors = AppleColors;

/// Main Light Theme adapted with Saddle Ranch Brand Colors (Domine + WorkSans)
final ThemeData saddleRanchTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: const Color(0xFFFBFBFD),
  primaryColor: const Color(0xFFF59E0B),
  cardColor: Colors.white,
  colorScheme: const ColorScheme.light(
    primary: Color(0xFFF59E0B),
    onPrimary: Colors.white,
    secondary: Color(0xFFFFC174),
    onSecondary: Color(0xFF472A00),
    surface: Colors.white,
    onSurface: Color(0xFF1F2937),
    surfaceContainerHighest: Color(0xFFF4F4F6),
    outline: Color(0xFFE5E7EB),
    error: Color(0xFFF43F5E),
  ),
  textTheme: TextTheme(
    displayLarge: GoogleFonts.domine(
      color: const Color(0xFF1F2937),
      fontWeight: FontWeight.bold,
      fontSize: 28,
    ),
    headlineMedium: GoogleFonts.domine(
      color: const Color(0xFF1F2937),
      fontWeight: FontWeight.bold,
      fontSize: 20,
    ),
    titleLarge: GoogleFonts.domine(
      color: const Color(0xFF1F2937),
      fontWeight: FontWeight.bold,
      fontSize: 18,
    ),
    titleMedium: GoogleFonts.domine(
      color: const Color(0xFF1F2937),
      fontWeight: FontWeight.w700,
      fontSize: 15,
    ),
    bodyLarge: GoogleFonts.workSans(
      color: const Color(0xFF374151),
      fontSize: 16,
    ),
    bodyMedium: GoogleFonts.workSans(
      color: const Color(0xFF4B5563),
      fontSize: 14,
    ),
    bodySmall: GoogleFonts.workSans(
      color: const Color(0xFF6B7280),
      fontSize: 12,
    ),
    labelLarge: GoogleFonts.workSans(
      color: Colors.white,
      fontWeight: FontWeight.w900,
      fontSize: 14,
      letterSpacing: 0.8,
    ),
    labelMedium: GoogleFonts.workSans(
      color: const Color(0xFF6B7280),
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.white.withValues(alpha: 0.95),
    foregroundColor: const Color(0xFF1F2937),
    surfaceTintColor: Colors.white,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: GoogleFonts.domine(
      color: const Color(0xFF1F2937),
      fontWeight: FontWeight.bold,
      fontSize: 18,
    ),
    iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
  ),
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFF59E0B),
      foregroundColor: Colors.white,
      elevation: 0,
      textStyle: GoogleFonts.workSans(
        fontWeight: FontWeight.w700,
        fontSize: 15,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    hintStyle: GoogleFonts.workSans(
      color: const Color(0xFF9CA3AF),
      fontSize: 14,
    ),
    labelStyle: GoogleFonts.workSans(
      color: const Color(0xFF6B7280),
      fontSize: 14,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFF59E0B), width: 1.5),
    ),
  ),
);

class AppleTheme {
  static void hapticFeedback() {
    HapticFeedback.lightImpact();
  }

  static ThemeData get light => saddleRanchTheme;
  static ThemeData get dark => saddleRanchTheme;
}
