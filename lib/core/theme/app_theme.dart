import 'package:flutter/material.dart';

class AppTheme {
  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xff05070d),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xff7c3aed),
      brightness: Brightness.dark,
      surface: const Color(0xff0b1020),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xff05070d),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),

    // Flutter SDK mới dùng CardThemeData thay vì CardTheme.
    cardTheme: CardThemeData(
      color: Colors.white.withOpacity(0.05),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withOpacity(0.06),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xffa78bfa)),
      ),
    ),
  );
}
