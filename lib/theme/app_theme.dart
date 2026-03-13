import 'package:flutter/material.dart';

class AppTheme {
  // Gemini-inspired colors
  static const Color primaryDark = Color(0xFF1E1E2E);
  static const Color surface = Color(0xFF2D2D3A);
  static const Color surfaceLight = Color(0xFF3D3D4A);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA0A0B0);
  static const Color accentBlue = Color(0xFF00A8E8);
  static const Color accentBlueDark = Color(0xFF0078D4);
  static const Color success = Color(0xFF00C853);
  static const Color error = Color(0xFFFF5252);
  static const Color userBubble = Color(0xFF0078D4);
  static const Color aiBubble = Color(0xFF2D2D3A);
  static const Color divider = Color(0xFF3D3D4A);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: primaryDark,
      primaryColor: accentBlue,
      colorScheme: const ColorScheme.dark(
        primary: accentBlue,
        secondary: accentBlueDark,
        surface: surface,
        error: error,
        onPrimary: textPrimary,
        onSecondary: textPrimary,
        onSurface: textPrimary,
        onError: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryDark,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: accentBlue,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: divider, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: accentBlue, width: 2),
        ),
        hintStyle: const TextStyle(color: textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentBlue,
          foregroundColor: textPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentBlue,
        ),
      ),
      iconTheme: const IconThemeData(
        color: textSecondary,
      ),
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surface,
        contentTextStyle: const TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      primaryColor: accentBlue,
      colorScheme: const ColorScheme.light(
        primary: accentBlue,
        secondary: accentBlueDark,
        surface: Color(0xFFF5F5F5),
        error: error,
        onPrimary: textPrimary,
        onSecondary: textPrimary,
        onSurface: primaryDark,
        onError: textPrimary,
      ),
    );
  }
}
