import 'package:flutter/material.dart';
import 'app_colors.dart';

// Enhanced Text Styles with Theme Support
class AppTextStyles {
  // Display Text Styles - Large headings
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 1.25,
  );

  static const TextStyle displaySmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.3,
  );

  // Headline Styles - Section headings
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.3,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.4,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.4,
  );

  // Title Styles - Card/component titles
  static const TextStyle titleLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.4,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.4,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.3,
  );

  // Body Text Styles - Main content
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.3,
    letterSpacing: 0,
  );

  // Label Styles - Form labels, captions
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: 0.1,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: 0.1,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: 0.1,
  );

  // Interactive Elements
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.2,
  );

  static const TextStyle buttonLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.2,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
    height: 1.1,
  );

  // Input/Form Elements
  static const TextStyle input = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0,
  );

  static const TextStyle hint = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0,
  );

  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: 0.1,
  );

  // Navigation & Tab Styles
  static const TextStyle tabActive = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.2,
  );

  static const TextStyle tabInactive = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    height: 1.2,
  );

  static const TextStyle navigation = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.2,
  );

  // Healthcare Specific Styles
  static const TextStyle metric = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.1,
  );

  static const TextStyle metricLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.2,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.3,
  );

  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.4,
  );

  // Legacy styles for backward compatibility (updated to use new system)
  static const TextStyle title = displayLarge;
  static const TextStyle subtitle = headlineMedium;
  static const TextStyle heading1 = displayLarge;
  static const TextStyle heading2 = displayMedium;
  static const TextStyle heading3 = headlineLarge;

  // Theme-aware color methods
  static TextStyle withPrimaryColor(BuildContext context, TextStyle style) {
    return style.copyWith(color: AppColors.getTextPrimary(context));
  }

  static TextStyle withSecondaryColor(BuildContext context, TextStyle style) {
    return style.copyWith(color: AppColors.getTextSecondary(context));
  }

  static TextStyle withTertiaryColor(BuildContext context, TextStyle style) {
    return style.copyWith(color: AppColors.getTextTertiary(context));
  }

  static TextStyle withAccentColor(BuildContext context, TextStyle style) {
    return style.copyWith(color: AppColors.primary);
  }

  static TextStyle withErrorColor(BuildContext context, TextStyle style) {
    return style.copyWith(color: AppColors.error);
  }

  static TextStyle withSuccessColor(BuildContext context, TextStyle style) {
    return style.copyWith(color: AppColors.success);
  }

  static TextStyle withWarningColor(BuildContext context, TextStyle style) {
    return style.copyWith(color: AppColors.warning);
  }

  // Convenience methods for common combinations
  static TextStyle primaryTitle(BuildContext context) {
    return withPrimaryColor(context, displayLarge);
  }

  static TextStyle secondaryTitle(BuildContext context) {
    return withSecondaryColor(context, headlineMedium);
  }

  static TextStyle primaryBody(BuildContext context) {
    return withPrimaryColor(context, bodyLarge);
  }

  static TextStyle secondaryBody(BuildContext context) {
    return withSecondaryColor(context, bodyMedium);
  }

  static TextStyle primaryLabel(BuildContext context) {
    return withPrimaryColor(context, labelLarge);
  }

  static TextStyle secondaryLabel(BuildContext context) {
    return withTertiaryColor(context, labelMedium);
  }
}
