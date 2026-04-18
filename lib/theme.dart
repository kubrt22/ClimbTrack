import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryCoral = Color(0xFFF45B69);
  static const Color darkCharcoal = Color(0xFF333232);
  static const Color creamWhite = Color(0xFFFBF9F1);
  static const Color black = Color(0xFF151515);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryCoral,
        brightness: Brightness.light,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryCoral,
        brightness: Brightness.dark,
      ),
    );
  }
}
