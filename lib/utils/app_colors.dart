import 'package:flutter/material.dart';

// Healthcare App Color Palette - Minimalist Design
class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF2C3E50); // Deep slate blue-gray
  static const Color primaryLight = Color(0xFF34495E); // Lighter slate
  static const Color accent = Color(0xFF3498DB); // Clean blue accent

  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF); // Pure white
  static const Color background = Color(0xFFFAFAFA); // Off-white background
  static const Color surface = Color(0xFFF8F9FA); // Card surfaces
  static const Color divider = Color(0xFFE9ECEF); // Subtle dividers

  // Text Colors
  static const Color textPrimary = Color(0xFF2C3E50); // Primary text
  static const Color textSecondary = Color(0xFF6C757D); // Secondary text
  static const Color textLight = Color(0xFF8E9BAE); // Light text/hints

  // Status Colors
  static const Color success = Color(0xFF27AE60); // Success green
  static const Color warning = Color(0xFFF39C12); // Warning orange
  static const Color error = Color(0xFFE74C3C); // Error red
  static const Color info = Color(0xFF3498DB); // Info blue

  // Healthcare Specific
  static const Color healthPrimary = Color(0xFF5DADE2); // Calming blue
  static const Color healthSecondary = Color(0xFFAED6F1); // Light health blue
  static const Color wellness = Color(0xFF58D68D); // Wellness green

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, healthPrimary],
  );
}

// Legacy colors for backward compatibility
const black = AppColors.textPrimary;
const primaryBlue = AppColors.accent;
const secondaryBlue = AppColors.healthPrimary;
const lightPeach = AppColors.surface;
