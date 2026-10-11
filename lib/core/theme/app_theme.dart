import 'package:flutter/material.dart';

class SahaayTheme {
  // Brand / Alert colors
  static const Color sosRed = Color(0xFFD32F2F);
  static const Color sosRedDark = Color(0xFFB71C1C);
  static const Color alertOrange = Color(0xFFE65100);
  static const Color calmingGreen = Color(0xFF2E7D32);
  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color neutralDark = Color(0xFF1E293B);
  static const Color neutralLight = Color(0xFFF8FAFC);
  static const Color cardBorder = Color(0xFFCBD5E1);

  // Elder-friendly Theme: High contrast, large text styles, minimum 56px touch targets
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        error: sosRed,
        surface: neutralLight,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: neutralLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: neutralDark,
        elevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: neutralDark,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 56), // Large touch target
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 54),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          side: const BorderSide(width: 2, color: primaryBlue),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: cardBorder, width: 1.2),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: neutralDark,
          height: 1.2,
        ),
        headlineMedium: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: neutralDark,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: neutralDark,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: neutralDark,
        ),
        bodyLarge: TextStyle(
          fontSize: 18,
          color: neutralDark,
          height: 1.4,
        ),
        bodyMedium: TextStyle(
          fontSize: 16,
          color: Color(0xFF475569),
          height: 1.4,
        ),
      ),
    );
  }
}
