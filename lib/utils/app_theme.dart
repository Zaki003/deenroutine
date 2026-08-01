import 'package:flutter/material.dart';

const Color kBrandGreen = Color(0xFF2E7D32);

class AppTheme {
  static ThemeData get light => ThemeData(
        colorSchemeSeed: kBrandGreen,
        brightness: Brightness.light,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7FAF7),
      );

  static ThemeData get dark => ThemeData(
        colorSchemeSeed: kBrandGreen,
        brightness: Brightness.dark,
        useMaterial3: true,
      );
}