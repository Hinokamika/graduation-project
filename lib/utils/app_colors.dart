import 'package:flutter/material.dart';

// Enhanced Healthcare App Color Palette - Modern Design System
class AppColors {
  // Primary Colors - Enhanced for both themes
  static const Color primary = Color(0xFF2563EB); // Modern blue
  static const Color primaryLight = Color(0xFF3B82F6); // Lighter blue
  static const Color accent = Color(0xFF1D4ED8); // Deeper blue accent

  // Light Theme Colors
  static const Color lightBackground = Color(
    0xFFF8FAFE,
  ); // Soft blue-tinted white
  static const Color lightSurface = Color(0xFFFFFFFF); // Pure white
  static const Color lightCard = Color(0xFFFFFFFF); // White cards
  static const Color lightDivider = Color(0xFFE2E8F0); // Subtle dividers
  static const Color lightTextPrimary = Color(0xFF1A1A1A); // Near black
  static const Color lightTextSecondary = Color(0xFF374151); // Dark gray
  static const Color lightTextTertiary = Color(0xFF6B7280); // Medium gray
  static const Color lightBorder = Color(0xFFE2E8F0); // Light border

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF0A0A0A); // Pure black
  static const Color darkSurface = Color(0xFF1C1C1E); // iOS-style surface
  static const Color darkCard = Color(0xFF1C1C1E); // Dark cards
  static const Color darkDivider = Color(0xFF38383A); // Dark dividers
  static const Color darkTextPrimary = Color(0xFFF2F2F7); // Near white
  static const Color darkTextSecondary = Color(0xFFE5E5E7); // Light gray
  static const Color darkTextTertiary = Color(0xFFA1A1A6); // Medium gray
  static const Color darkBorder = Color(0xFF38383A); // Dark border

  // Legacy/Backward Compatibility Colors
  static const Color white = lightSurface;
  static const Color background = lightBackground;
  static const Color surface = lightSurface;
  static const Color divider = lightDivider;
  static const Color textPrimary = lightTextPrimary;
  static const Color textSecondary = lightTextSecondary;
  static const Color textLight = lightTextTertiary;

  // Status Colors - Enhanced with better contrast
  static const Color success = Color(0xFF059669); // Success green
  static const Color successLight = Color(0xFF10B981); // Lighter success
  static const Color warning = Color(0xFFD97706); // Warning orange
  static const Color warningLight = Color(0xFFF59E0B); // Lighter warning
  static const Color error = Color(0xFFDC2626); // Error red
  static const Color errorLight = Color(0xFFEF4444); // Lighter error
  static const Color info = Color(0xFF2563EB); // Info blue
  static const Color infoLight = Color(0xFF3B82F6); // Lighter info

  // Healthcare Specific Colors
  static const Color healthPrimary = Color(0xFF3B82F6); // Medical blue
  static const Color healthSecondary = Color(0xFF93C5FD); // Light health blue
  static const Color wellness = Color(0xFF10B981); // Wellness green
  static const Color wellnessLight = Color(0xFF34D399); // Light wellness
  static const Color heartRate = Color(0xFFEF4444); // Heart rate red
  static const Color steps = Color(0xFF8B5CF6); // Steps purple
  static const Color calories = Color(0xFFF59E0B); // Calories orange
  static const Color sleep = Color(0xFF6366F1); // Sleep indigo

  // Interactive States
  static const Color hover = Color(0xFFF1F5F9); // Light hover
  static const Color hoverDark = Color(0xFF2A2A2C); // Dark hover
  static const Color pressed = Color(0xFFE2E8F0); // Light pressed
  static const Color pressedDark = Color(0xFF3A3A3C); // Dark pressed
  static const Color focus = Color(0xFF3B82F6); // Focus blue
  static const Color focusDark = Color(0xFF60A5FA); // Dark focus

  // Gradients - Enhanced for modern look
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
    stops: [0.0, 1.0],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, healthPrimary],
    stops: [0.0, 1.0],
  );

  static const LinearGradient wellnessGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [wellness, wellnessLight],
    stops: [0.0, 1.0],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
    stops: [0.0, 1.0],
  );

  static const LinearGradient cardGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1C1C1E), Color(0xFF1A1A1C)],
    stops: [0.0, 1.0],
  );

  // Theme-aware color methods
  static Color getTextPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextPrimary
        : lightTextPrimary;
  }

  static Color getTextSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextSecondary
        : lightTextSecondary;
  }

  static Color getTextTertiary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextTertiary
        : lightTextTertiary;
  }

  static Color getBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBackground
        : lightBackground;
  }

  static Color getSurface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSurface
        : lightSurface;
  }

  static Color getDivider(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkDivider
        : lightDivider;
  }

  static Color getBorder(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBorder
        : lightBorder;
  }

  static Color getHover(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? hoverDark : hover;
  }

  static Color getPressed(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? pressedDark
        : pressed;
  }

  // Icon-specific theme-aware methods
  static Color getIconPrimary(BuildContext context) {
    return primary; // Primary color works well in both themes
  }

  static Color getIconSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextSecondary
        : lightTextSecondary;
  }

  static Color getIconTertiary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextTertiary
        : lightTextTertiary;
  }

  // Enhanced status colors for better dark mode visibility
  static Color getSuccessColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? successLight
        : success;
  }

  static Color getWarningColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? warningLight
        : warning;
  }

  static Color getErrorColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? errorLight : error;
  }

  static Color getInfoColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? infoLight : info;
  }
}

// Legacy colors for backward compatibility
const black = AppColors.lightTextPrimary;
const primaryBlue = AppColors.primary;
const secondaryBlue = AppColors.healthPrimary;
const lightPeach = AppColors.lightBackground;
