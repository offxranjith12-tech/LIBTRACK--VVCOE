import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// VV College of Engineering brand colors
class AppColors {
  static const Color primaryRed = Color(0xFFB71C1C);
  static const Color darkRed = Color(0xFF7F0000);
  static const Color lightRed = Color(0xFFE57373);
  static const Color accentRed = Color(0xFFEF5350);
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF8F7FA);
  static const Color surfaceLight = Color(0xFFFFF5F5);
  static const Color textDark = Color(0xFF241010);
  static const Color textGrey = Color(0xFF6B6B6B);

  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);
  static const Color danger = Color(0xFFC62828);

  static const List<Color> heroGradient = [primaryRed, darkRed];
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryRed,
        brightness: Brightness.light,
        primary: AppColors.primaryRed,
        surface: AppColors.white,
      ),
      scaffoldBackgroundColor: AppColors.offWhite,
    );

    final textTheme = GoogleFonts.poppinsTextTheme(base.textTheme).copyWith(
      titleLarge: GoogleFonts.poppins(
          fontWeight: FontWeight.w700, fontSize: 22, color: AppColors.textDark),
      titleMedium: GoogleFonts.poppins(
          fontWeight: FontWeight.w600, fontSize: 17, color: AppColors.textDark),
      bodyMedium: GoogleFonts.poppins(fontSize: 14, color: AppColors.textGrey),
      bodySmall: GoogleFonts.poppins(fontSize: 12, color: AppColors.textGrey),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.offWhite,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.surfaceLight,
        labelStyle: textTheme.bodySmall,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryRed,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryRed,
          side: const BorderSide(color: AppColors.primaryRed, width: 1.4),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryRed, width: 1.6),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.white,
        indicatorColor: AppColors.primaryRed.withOpacity(0.12),
        elevation: 3,
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: DividerThemeData(color: Colors.grey.shade200, thickness: 1),
    );
  }

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryRed,
        brightness: Brightness.dark,
        primary: AppColors.accentRed,
      ),
      scaffoldBackgroundColor: const Color(0xFF161213),
    );
    final textTheme = GoogleFonts.poppinsTextTheme(base.textTheme).copyWith(
      titleLarge: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 22, color: Colors.white),
      titleMedium: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 17, color: Colors.white),
      bodyMedium: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFFC9C0C1)),
      bodySmall: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFFA79D9E)),
    );
    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF161213),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF221C1D),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Color(0xFF221C1D),
      ),
    );
  }
}
