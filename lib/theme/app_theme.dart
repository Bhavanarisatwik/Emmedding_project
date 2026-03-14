import 'package:flutter/material.dart';

class AppTheme {
  // Google Gemini dark theme
  static const Color primaryDark = Color(0xFF131314);   // deep charcoal
  static const Color surface = Color(0xFF1C1E21);        // slightly elevated
  static const Color surfaceLight = Color(0xFF28292C);   // modals/sheets
  static const Color textPrimary = Color(0xFFE8EAED);    // off-white
  static const Color textSecondary = Color(0xFF9AA0A6);  // muted gray
  static const Color accentBlue = Color(0xFFE8EAED);     // off-white
  static const Color accentBlueDark = Color(0xFFBDC1C6); // cool light gray
  static const Color accentGlow = Color(0xFFE8EAED);
  static const Color userBubble = Color(0xFF303134);     // dark gray pill
  static const Color aiBubble = Color(0x00000000);       // fully transparent (borderless)
  static const Color divider = Color(0xFF3C4043);
  static const Color success = Color(0xFF34D399);
  static const Color error = Color(0xFFF87171);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: primaryDark,
      primaryColor: accentBlue,
      highlightColor: Color(0x14E8EAED),
      splashColor: Color(0x0AE8EAED),
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
          borderRadius: BorderRadius.circular(50),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: const BorderSide(color: divider, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: const BorderSide(color: accentBlue, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentBlue,
          foregroundColor: primaryDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const StadiumBorder(),
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
