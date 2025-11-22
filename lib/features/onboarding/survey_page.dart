import 'package:final_project/components/buildDropdown.dart';
import 'package:final_project/components/buildTextField.dart';
import 'package:final_project/components/enhanced_button.dart';
import 'package:final_project/components/enhanced_card.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/services.dart';
import 'package:final_project/utils/app_colors.dart';
import 'package:final_project/utils/text_styles.dart';
import 'package:final_project/services/user_service.dart';
import 'package:final_project/features/plan/plan_loading_page.dart';

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

  final List<String> _activityLevels = ['beginner', 'intermediate', 'advanced'];

  final List<Map<String, String>> _dietTypes = [
    {'label': 'Lose Weight', 'value': 'lost_weight'},
    {'label': 'Maintain Weight', 'value': 'maintain_weight'},
    {'label': 'Gain Weight', 'value': 'gain_weight'},
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
          icon: FaIcon(
            FontAwesomeIcons.arrowLeft,
            color: AppColors.getTextPrimary(context),
            size: 20,
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
                          child: const FaIcon(
                            FontAwesomeIcons.user,
                            color: AppColors.primary,
                            size: 22,
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
                      icon: FontAwesomeIcons.user,
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
                            icon: FontAwesomeIcons.cakeCandles,
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
                            icon: FontAwesomeIcons.venusMars,
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
                            icon: FontAwesomeIcons.rulerVertical,
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
                            icon: FontAwesomeIcons.weightScale,
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
                      icon: FontAwesomeIcons.personRunning,
                      items: _activityLevels,
                      onChanged: (value) =>
                          setState(() => _selectedActivityLevel = value),
                    ),
                    const SizedBox(height: 20),

                    buildDropdown(
                      value: _selectedDietType != null
                          ? _dietTypes.firstWhere(
                              (diet) => diet['value'] == _selectedDietType,
                              orElse: () => {'label': '', 'value': ''},
                            )['label']
                          : null,
                      label: 'Diet Type',
                      icon: FontAwesomeIcons.utensils,
                      items: _dietTypes.map((diet) => diet['label']!).toList(),
                      onChanged: (value) {
                        final selected = _dietTypes.firstWhere(
                          (diet) => diet['label'] == value,
                          orElse: () => {'label': '', 'value': ''},
                        );
                        setState(() => _selectedDietType = selected['value']);
                      },
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
                icon: FontAwesomeIcons.arrowRight,
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
        const SnackBar(content: Text('Processing your information...')),
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

        // Save survey data locally/Supabase (non-blocking for API)
        final userService = UserService();
        await userService.saveSurveyData(surveyData);

        // Hide loading indicator
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        }

        // Navigate to loading page to generate plan
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PlanLoadingPage(survey: surveyData),
          ),
        );
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
