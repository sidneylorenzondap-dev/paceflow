import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Neo-Brutalist Colors
  static const Color primaryColor = Color(0xFFCCFF00); // Neon Yellow-Green
  static const Color backgroundColor = Color(0xFF0E0E10); // Dark Background
  static const Color surfaceColor = Color(0xFF18181C); // Card Background
  static const Color onBackgroundColor = Colors.white; // White text
  static const Color secondaryTextColor = Color(0xFF8E8E93); // Grey text
  static const Color accentColor = Color(0xFFFC4C02); // Bright Orange
  static const Color brutalistBorder = Colors.black; // Heavy strokes

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundColor,
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        surface: surfaceColor,
        background: backgroundColor,
        onBackground: onBackgroundColor,
        secondary: accentColor,
      ),
      textTheme: GoogleFonts.geistTextTheme(
        ThemeData(brightness: Brightness.dark).textTheme,
      ).copyWith(
        displayLarge: GoogleFonts.unbounded(
          fontWeight: FontWeight.w900, // Black
          color: onBackgroundColor,
        ),
        displayMedium: GoogleFonts.unbounded(
          fontWeight: FontWeight.w900, // Black
          color: onBackgroundColor,
        ),
        headlineLarge: GoogleFonts.unbounded(
          fontWeight: FontWeight.w800, // ExtraBold
          color: onBackgroundColor,
        ),
        titleLarge: GoogleFonts.unbounded(
          fontWeight: FontWeight.w800, // ExtraBold
          color: onBackgroundColor,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          textStyle: GoogleFonts.unbounded(
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Colors.black, width: 2), // Brutalist button border
          ),
          elevation: 0, // Shadows handled manually by NeoBrutalist container
        ),
      ),
    );
  }
}
