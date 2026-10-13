import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const primary = Color(0xFF2563EB);
  static const accent = Color(0xFF06B6D4);
  static const dark = Color(0xFF0F172A);
  static const background = Color(0xFFF8FAFC);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [dark, Color(0xFF1E3A8A), primary],
  );
}