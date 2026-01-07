// lib/core/constants/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  AppColors._(); // Private constructor to prevent instantiation if you want to use static members only

  // Primary Colors
  static const Color primary = Color(0xFF6A1B9A); // Example: A deep purple
  static const Color primaryLight = Color(0xFF9C4DCC);
  static const Color primaryDark = Color(0xFF38006B);

  // Accent Colors (Optional, can be same as primary or different)
  static const Color accent = Color(0xFFF50057); // Example: A bright pink

  // Text Colors
  static const Color textDark = Color(0xFF212121);    // For dark text on light backgrounds
  static const Color textMedium = Color(0xFF757575);  // For secondary text
  static const Color textLight = Color(0xFF9E9E9E);   // For lighter text or hints
  static const Color textOnPrimary = Colors.white;     // Text color for on top of primary color
  static const Color textOnAccent = Colors.white;      // Text color for on top of accent color

  // Background Colors
  static const Color background = Colors.white;
  static const Color scaffoldBackground = Color(0xFFF5F5F5); // A very light grey for general screen backgrounds

  // Status/Semantic Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Neutral Colors
  static const Color greyLight = Color(0xFFE0E0E0);
  static const Color greyMedium = Color(0xFF9E9E9E);
  static const Color greyDark = Color(0xFF424242);
  static const Color divider = Color(0xFFBDBDBD);

  // Specific UI element colors (if needed)
  static const Color cardBackground = Colors.white;
  static const Color inputBackground = Color(0xFFFAFAFA);
  static const Color iconColor = Color(0xFF757575);
}