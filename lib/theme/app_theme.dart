import 'package:flutter/material.dart';

class AppTheme {
  // Deep violet/purple dark theme
  static const Color primaryDark = Color(0xFF090910);
  static const Color surface = Color(0xFF12121C);
  static const Color surfaceLight = Color(0xFF1C1C2A);
  static const Color textPrimary = Color(0xFFF0F0FF);
  static const Color textSecondary = Color(0xFF8B8BA8);
  static const Color accentBlue = Color(0xFFA78BFA); // violet-400
  static const Color accentBlueDark = Color(0xFF7C3AED); // violet-600
  static const Color accentGlow = Color(0xFF7C3AED);
  static const Color userBubble = Color(0xFF6D28D9); // deep violet
  static const Color aiBubble = Color(0xFF12121C); // same as surface
  static const Color divider = Color(0xFF2A2A3E);
  static const Color success = Color(0xFF34D399); // emerald
  static const Color error = Color(0xFFF87171); // red-400

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: primaryDark,
      primaryColor: accentBlue,
      highlightColor: Color(0x1AA78BFA),
      splashColor: Color(0x0FA78BFA),
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
        surfaceTintColor: Colors.transparent,
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
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: divider, width: 1),
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
          foregroundColor: Colors.white,
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
        backgroundColor: surfaceLight,
        contentTextStyle: const TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: divider),
        ),
      ),
      dialogTheme: const DialogTheme(
        backgroundColor: surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
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
