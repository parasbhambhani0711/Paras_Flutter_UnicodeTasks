import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryNavy = Color(0xFF0F172A);
  static const Color brandRed = Color(0xFFDC2626);
  static const Color backgroundIvory = Color(0xFFFAFAF7);
  static const Color cardSurface = Colors.white;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundIvory,
      colorScheme: ColorScheme.fromSeed(
        seedColor: brandRed,
        primary: primaryNavy,
        secondary: brandRed,
        surface: cardSurface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryNavy,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: brandRed),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandRed,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: primaryNavy,
        selectedItemColor: brandRed,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
