import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:final_project/utils/app_colors.dart';
import 'package:final_project/utils/text_styles.dart';
import 'package:final_project/components/enhanced_card.dart';
import 'package:final_project/components/enhanced_button.dart';
import 'package:final_project/components/enhanced_states.dart';
import 'package:final_project/components/buildTextField.dart';
import 'package:final_project/components/buildDropdown.dart';
import 'package:final_project/config/theme_controller.dart';

/// Demo page showcasing enhanced UI components in both light and dark themes
class UIComponentsDemo extends StatefulWidget {
  const UIComponentsDemo({super.key});

  @override
  State<UIComponentsDemo> createState() => _UIComponentsDemoState();
}

class _UIComponentsDemoState extends State<UIComponentsDemo> {
  final _textController = TextEditingController();
  String? _selectedValue;
  bool _isLoading = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            CupertinoIcons.back,
            color: AppColors.getTextPrimary(context),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'UI Components Demo',
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.getTextPrimary(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? CupertinoIcons.sun_max
                  : CupertinoIcons.moon,
              color: AppColors.getTextPrimary(context),
            ),
            onPressed: () {
              ThemeController.instance.toggle();
            },
            tooltip: 'Toggle Theme',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            _buildSection(
              'Welcome to Enhanced UI',
              'Showcasing modern components with perfect light/dark mode support',
              child: Column(
                children: [
                  // Theme Toggle Card
                  EnhancedCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Theme.of(context).brightness == Brightness.dark
                                    ? CupertinoIcons.moon_fill
                                    : CupertinoIcons.sun_max_fill,
                                color: AppColors.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${Theme.of(context).brightness == Brightness.dark ? 'Dark' : 'Light'} Theme Active',
                                    style: AppTextStyles.titleLarge.copyWith(
                                      color: AppColors.getTextPrimary(context),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tap the theme button to switch modes',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.getTextSecondary(
                                        context,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Metric Cards Section
            _buildSection(
              'Health Metrics',
              'Beautiful cards for displaying health data',
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: MetricCard(
                          title: 'Heart Rate',
                          value: '72',
                          unit: 'bpm',
                          icon: CupertinoIcons.heart_fill,
                          iconColor: AppColors.heartRate,
                          subtitle: 'Resting',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: MetricCard(
                          title: 'Steps',
                          value: '8,247',
                          icon: CupertinoIcons.person_fill,
                          iconColor: AppColors.steps,
                          subtitle: '2,753 to go',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: MetricCard(
                          title: 'Calories',
                          value: '1,247',
                          unit: 'kcal',
                          icon: CupertinoIcons.flame_fill,
                          iconColor: AppColors.calories,
                          subtitle: 'Burned today',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: MetricCard(
                          title: 'Sleep',
                          value: '7h 23m',
                          icon: CupertinoIcons.moon_fill,
                          iconColor: AppColors.sleep,
                          subtitle: 'Last night',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Buttons Section
            _buildSection(
              'Enhanced Buttons',
              'Modern button components with loading states',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  EnhancedButton(
                    text: 'Primary Button',
                    onPressed: () => _toggleLoading(),
                    icon: CupertinoIcons.heart_fill,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 16),
                  EnhancedButton(
                    text: 'Outlined Button',
                    onPressed: () => _showSnackBar('Outlined button pressed!'),
                    icon: CupertinoIcons.star,
                    isOutlined: true,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: SmallButton(
                          text: 'Small',
                          onPressed: () =>
                              _showSnackBar('Small button pressed!'),
                          icon: CupertinoIcons.add,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SmallButton(
                          text: 'Outlined',
                          onPressed: () =>
                              _showSnackBar('Small outlined pressed!'),
                          icon: CupertinoIcons.minus,
                          isOutlined: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SmallButton(
                          text: 'Success',
                          onPressed: () => _showSnackBar('Success pressed!'),
                          backgroundColor: AppColors.success,
                          icon: CupertinoIcons.checkmark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Form Components Section
            _buildSection(
              'Form Components',
              'Enhanced text fields and dropdowns',
              child: Column(
                children: [
                  buildTextField(
                    controller: _textController,
                    label: 'Enhanced Text Field',
                    icon: CupertinoIcons.person,
                    hintText: 'Enter your name...',
                  ),
                  const SizedBox(height: 16),
                  buildDropdown(
                    value: _selectedValue,
                    label: 'Enhanced Dropdown',
                    icon: CupertinoIcons.list_bullet,
                    items: const [
                      'Option 1',
                      'Option 2',
                      'Option 3',
                      'Very Long Option That Tests Overflow Handling',
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedValue = value),
                    hintText: 'Select an option...',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Loading States Section
            _buildSection(
              'Loading & States',
              'Beautiful loading and empty state components',
              child: Column(
                children: [
                  Container(
                    height: 120,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.getSurface(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.getBorder(context)),
                    ),
                    child: const EnhancedLoading(
                      message: 'Loading your data...',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 200,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.getSurface(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.getBorder(context)),
                    ),
                    child: EnhancedEmptyState(
                      icon: CupertinoIcons.heart,
                      title: 'No Data Yet',
                      subtitle:
                          'Start tracking your health to see insights here',
                      action: SmallButton(
                        text: 'Get Started',
                        onPressed: () => _showSnackBar('Get started pressed!'),
                        backgroundColor: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Error State Section
            _buildSection(
              'Error States',
              'Error handling with theme-aware styling',
              child: Column(
                children: [
                  Container(
                    height: 200,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.getSurface(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.getBorder(context)),
                    ),
                    child: EnhancedErrorState(
                      title: 'Connection Error',
                      subtitle:
                          'Unable to connect to server. Please check your internet connection.',
                      onRetry: () => _showSnackBar('Retry pressed!'),
                      retryText: 'Try Again',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Shimmer Loading Section
            _buildSection(
              'Shimmer Effects',
              'Elegant loading placeholders',
              child: Column(
                children: [
                  EnhancedCard(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const ShimmerBox(
                              width: 48,
                              height: 48,
                              borderRadius: 24,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const ShimmerBox(
                                    width: double.infinity,
                                    height: 16,
                                  ),
                                  const SizedBox(height: 8),
                                  ShimmerBox(
                                    width:
                                        MediaQuery.of(context).size.width * 0.6,
                                    height: 14,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const ShimmerBox(width: double.infinity, height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String subtitle, {required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.getTextPrimary(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.getTextSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }

  void _toggleLoading() {
    setState(() => _isLoading = !_isLoading);
    if (_isLoading) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _isLoading = false);
          _showSnackBar('Action completed!');
        }
      });
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
