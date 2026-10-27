import 'package:flutter/material.dart';

ThemeData buildMobileTheme() {
  const seed = Color(0xFF5A2A83);
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light),
    fontFamily: 'Roboto',
    scaffoldBackgroundColor: const Color(0xFFF8F7FA),
    inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
  );
}
