import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color indigo = Color(0xFF5C6BC0);
  static const Color deepIndigo = Color(0xFF3949AB);
  static const Color purple = Color(0xFF7E57C2);
  static const Color teal = Color(0xFF26A69A);
  static const Color amber = Color(0xFFFFC107);
  static const Color slateBg = Color(0xFFF3F4F6);

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: deepIndigo,
      brightness: Brightness.light,
      primary: deepIndigo,
      secondary: teal,
      surface: Colors.white,
      background: slateBg,
    );

    final textTheme = TextTheme(
      displayLarge: GoogleFonts.nunito(
        fontSize: 44,
        fontWeight: FontWeight.w800,
      ),
      headlineLarge: GoogleFonts.nunito(
        fontSize: 28,
        fontWeight: FontWeight.w800,
      ),
      headlineMedium: GoogleFonts.nunito(
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w700),
      bodyLarge: GoogleFonts.inter(fontSize: 16, height: 1.4),
      bodyMedium: GoogleFonts.inter(fontSize: 14, height: 1.4),
      labelLarge: GoogleFonts.inter(fontWeight: FontWeight.w700),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: slateBg,
      appBarTheme: AppBarTheme(
        backgroundColor: deepIndigo,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
        centerTitle: true,
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 6,
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: deepIndigo, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: deepIndigo,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 3,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: deepIndigo,
        behavior: SnackBarBehavior.floating,
        contentTextStyle: GoogleFonts.inter(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
