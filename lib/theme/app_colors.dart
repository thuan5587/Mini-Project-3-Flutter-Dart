import 'package:flutter/material.dart';

class AppColors {
  // Brand accents
  static const Color primary = Color(0xFF6366F1); // Indigo / Violet
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4338CA);
  static const Color accent = Color(0xFF10B981); // Emerald Teal
  static const Color secondary = Color(0xFFEC4899); // Pink Rose

  // Dark Theme Palette
  static const Color darkBg = Color(0xFF0F172A); // Slate 900
  static const Color darkCard = Color(0xFF1E293B); // Slate 800
  static const Color darkCardElevated = Color(0xFF26354A);
  static const Color darkBorder = Color(0xFF334155); // Slate 700
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  // Light Theme Palette
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightCard = Colors.white;
  static const Color lightCardElevated = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted = Color(0xFF94A3B8);

  // Status & Feedback
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF06B6D4);

  // Chart palette
  static const List<Color> donutPalette = [
    Color(0xFFEF4444), // Food
    Color(0xFF3B82F6), // Study
    Color(0xFF10B981), // Travel
    Color(0xFF8B5CF6), // Gear
    Color(0xFFF59E0B), // Entertainment
    Color(0xFF64748B), // Other
  ];
}