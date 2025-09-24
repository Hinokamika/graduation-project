import 'package:final_project/components/buildDropdown.dart';
import 'package:final_project/components/buildTextField.dart';
import 'package:final_project/components/enhanced_button.dart';
import 'package:final_project/components/enhanced_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:final_project/utils/app_colors.dart';
import 'package:final_project/utils/text_styles.dart';
import 'package:final_project/services/user_service.dart';
import 'package:final_project/features/auth/auth_options_page.dart';

class SurveyPage extends StatefulWidget {
  const SurveyPage({super.key});

  @override
  State<SurveyPage> createState() => _SurveyPageState();
}

class _SurveyPageState extends State<SurveyPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  String? _selectedGender;
  String? _selectedActivityLevel;
  String? _selectedDietType;
  final List<String> _healthConditions = [];

  final List<String> _activityLevels = [
    'Sedentary (little to no exercise)',
    'Lightly active (light exercise 1-3 days/week)',
    'Moderately active (moderate exercise 3-5 days/week)',
    'Very active (hard exercise 6-7 days/week)',
  ];

  final List<String> _dietTypes = [
    'Balanced',
    'Low Carb',
    'High Protein',
    'Vegetarian',
    'Vegan',
    'Keto',
    'Mediterranean',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: Theme.of(context).brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: Icon(
            CupertinoIcons.back,
            color: AppColors.getTextPrimary(context),
            size: 22,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Health Profile',
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.getTextPrimary(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Enhanced Header Section
              EnhancedCard(
                showShadow: false,
                margin: const EdgeInsets.only(bottom: 32),
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
                          child: const Icon(
                            Icons.person_outline,
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
                                'Tell us about yourself',
                                style: AppTextStyles.primaryTitle(context),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'This information helps us personalize your healthcare experience.',
                                style: AppTextStyles.secondaryBody(context),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Personal Information Section
              EnhancedCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Personal Information'),
                    const SizedBox(height: 20),

                    buildTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.person_outline,
                      validator: (value) {
                        if (value?.isEmpty ?? true)
                          return 'Please enter your name';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: buildTextField(
                            controller: _ageController,
                            label: 'Age',
                            icon: Icons.cake_outlined,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value?.isEmpty ?? true) return 'Required';
                              final age = int.tryParse(value!);
                              if (age == null || age < 1 || age > 120) {
                                return 'Enter valid age';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: buildDropdown(
                            value: _selectedGender,
                            label: 'Gender',
                            icon: Icons.wc_outlined,
                            items: [
                              'Male',
                              'Female',
                              'Other',
                              'Prefer not to say',
                            ],
                            onChanged: (value) =>
                                setState(() => _selectedGender = value),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Health Metrics Section
              EnhancedCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Health Metrics'),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: buildTextField(
                            controller: _heightController,
                            label: 'Height (cm)',
                            icon: Icons.height,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true) return 'Required';
                              final height = double.tryParse(value!);
                              if (height == null ||
                                  height < 50 ||
                                  height > 300) {
                                return 'Enter valid height';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: buildTextField(
                            controller: _weightController,
                            label: 'Weight (kg)',
                            icon: Icons.monitor_weight_outlined,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true) return 'Required';
                              final weight = double.tryParse(value!);
                              if (weight == null ||
                                  weight < 20 ||
                                  weight > 500) {
                                return 'Enter valid weight';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    buildDropdown(
                      value: _selectedActivityLevel,
                      label: 'Activity Level',
                      icon: Icons.directions_run,
                      items: _activityLevels,
                      onChanged: (value) =>
                          setState(() => _selectedActivityLevel = value),
                    ),
                    const SizedBox(height: 20),

                    buildDropdown(
                      value: _selectedDietType,
                      label: 'Diet Type',
                      icon: Icons.restaurant_menu,
                      items: _dietTypes,
                      onChanged: (value) =>
                          setState(() => _selectedDietType = value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Enhanced Continue Button
              EnhancedButton(
                text: 'Continue',
                onPressed: _submitSurvey,
                width: double.infinity,
                icon: Icons.arrow_forward,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.getTextPrimary(context),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _submitSurvey() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedGender == null || _selectedActivityLevel == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all required fields')),
        );
        return;
      }

      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saving your information...')),
      );

      try {
        // Prepare survey data
        final surveyData = {
          'name': _nameController.text.trim(),
          'age': int.tryParse(_ageController.text.trim()),
          'gender': _selectedGender,
          'height': double.tryParse(_heightController.text.trim()),
          'weight': double.tryParse(_weightController.text.trim()),
          'activity_level': _selectedActivityLevel,
          'diet_type': _selectedDietType,
          'created_at': DateTime.now().toIso8601String(),
        };

        // Save survey data using UserService
        final userService = UserService();
        await userService.saveSurveyData(surveyData);

        // Hide loading indicator
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        }

        // Show success toast then navigate
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Profile saved. Continue to sign in or create account.',
              ),
              backgroundColor: Colors.green,
              duration: Duration(milliseconds: 1200),
            ),
          );

          await Future.delayed(const Duration(milliseconds: 900));

          if (!mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AuthOptionsPage()),
          );
        }
      } catch (e) {
        // Hide loading indicator
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        }

        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving survey data: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }
}
