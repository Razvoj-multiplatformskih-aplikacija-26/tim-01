import 'package:flutter/material.dart';

ThemeData buildBackofficeTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF243B6B)),
    fontFamily: 'Roboto',
    scaffoldBackgroundColor: const Color(0xFFF4F6FA),
    inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
  );
}
