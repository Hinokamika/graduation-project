import 'package:final_project/components/enhanced_button.dart';
import 'package:final_project/components/enhanced_card.dart';
import 'package:final_project/features/auth/auth_options_page.dart';
import 'package:final_project/features/auth/login_page.dart';
import 'package:final_project/services/plan_service.dart';
import 'package:final_project/utils/app_colors.dart';
import 'package:final_project/utils/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PlanResultPage extends StatefulWidget {
  final Map<String, dynamic> survey;
  final Map<String, dynamic> plan;

  const PlanResultPage({super.key, required this.survey, required this.plan});

  @override
  State<PlanResultPage> createState() => _PlanResultPageState();
}

class _PlanResultPageState extends State<PlanResultPage> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: FaIcon(
            FontAwesomeIcons.arrowLeft,
            color: AppColors.getTextPrimary(context),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Your Personalized Plan',
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.getTextPrimary(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Plan Overview
                    _buildOverviewSection(plan),
                    const SizedBox(height: 24),

                    // BMI Analysis & Nutrition
                    _buildBMIAndNutritionSection(plan),
                    const SizedBox(height: 24),

                    // Daily Plan Tabs
                    _buildDailyPlanSection(plan),
                    const SizedBox(height: 24),

                    // Grocery List
                    _buildGroceryListSection(plan),
                    const SizedBox(height: 24),

                    // Lifestyle & Recovery
                    _buildLifestyleSection(plan),
                    const SizedBox(height: 24),

                    // Safety Notes
                    _buildSafetyNotesSection(plan),
                  ],
                ),
              ),
            ),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Future<void> _onSave() async {
    setState(() => _saving = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        final goLogin = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Sign in required'),
            content: const Text('Please sign in to save your plan.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Not now'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sign in'),
              ),
            ],
          ),
        );
        if (goLogin == true && mounted) {
          final signedIn = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const LoginPage(returnOnSuccess: true)),
          );
          if (signedIn == true && mounted &&
              Supabase.instance.client.auth.currentUser != null) {
            await PlanService().saveChildTables(
              survey: widget.survey,
              plan: widget.plan,
            );
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Plan saved to your profile.')),
            );
            Navigator.pushNamed(context, '/home');
          }
        }
        return;
      }

      await PlanService().saveChildTables(
        survey: widget.survey,
        plan: widget.plan,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan saved to your profile.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildOverviewSection(Map<String, dynamic> plan) {
    final overview = plan['plan_overview']?.toString();
    if (overview == null || overview.isEmpty) return const SizedBox();

    return EnhancedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.fileLines,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Plan Overview',
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.getTextPrimary(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            overview,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.getTextSecondary(context),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBMIAndNutritionSection(Map<String, dynamic> plan) {
    final bmiValue = plan['bmi_value'];
    final bmiCategory = plan['bmi_category']?.toString();
    final bmiAnalysis = plan['bmi_analysis']?.toString();
    final macros = plan['calorie_and_macros'] as Map<String, dynamic>?;

    if (bmiValue == null && macros == null) return const SizedBox();

    return EnhancedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.heartRate.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.heart,
                  color: AppColors.heartRate,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Health & Nutrition',
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.getTextPrimary(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // BMI Section
          if (bmiValue != null) ...[
            _buildInfoRow(
              'BMI',
              '$bmiValue (${bmiCategory ?? 'Unknown'})',
              FontAwesomeIcons.user,
            ),
            if (bmiAnalysis != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.info.withOpacity(0.2)),
                ),
                child: Text(
                  bmiAnalysis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.getTextSecondary(context),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ],

          // Macros Section
          if (macros != null) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Daily Nutrition Target',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.getTextPrimary(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildNutritionCard(
                    'Calories',
                    '${macros['calories']}',
                    'kcal',
                    AppColors.calories,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNutritionCard(
                    'Protein',
                    '${macros['protein_g']}',
                    'g',
                    AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildNutritionCard(
                    'Carbs',
                    '${macros['carbs_g']}',
                    'g',
                    AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNutritionCard(
                    'Fat',
                    '${macros['fat_g']}',
                    'g',
                    AppColors.warning,
                  ),
                ),
              ],
            ),
            // Sugar (optional, only if provided by response)
            if (macros['sugar_g'] != null ||
                macros['sugars_g'] != null ||
                macros['sugar'] != null ||
                macros['sugars'] != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildNutritionCard(
                      'Sugar',
                      '${macros['sugar_g'] ?? macros['sugars_g'] ?? macros['sugar'] ?? macros['sugars']}',
                      'g',
                      AppColors.info,
                    ),
                  ),
                ],
              ),
            ],
            if (macros['hydration_l_min'] != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                'Daily Hydration',
                '${macros['hydration_l_min']}L minimum',
                FontAwesomeIcons.droplet,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildDailyPlanSection(Map<String, dynamic> plan) {
    final days = plan['days'] as List<dynamic>?;
    if (days == null || days.isEmpty) return const SizedBox();

    return EnhancedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.steps.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.calendar,
                  color: AppColors.steps,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '7-Day Plan',
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.getTextPrimary(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Show first 3 days as preview
          for (int i = 0; i < days.length.clamp(0, 6); i++) ...[
            _buildDayCard(days[i] as Map<String, dynamic>),
            if (i < days.length.clamp(0, 6) - 1) const SizedBox(height: 16),
          ],

          if (days.length > 6) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.getBorder(context)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGroceryListSection(Map<String, dynamic> plan) {
    final groceryList = plan['grocery_list'] as List<dynamic>?;
    if (groceryList == null || groceryList.isEmpty) return const SizedBox();

    return EnhancedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.wellness.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.cartShopping,
                  color: AppColors.wellness,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Shopping List',
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.getTextPrimary(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: groceryList
                .map(
                  (item) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.wellness.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.wellness.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      item.toString(),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.wellness,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLifestyleSection(Map<String, dynamic> plan) {
    final lifestyle = plan['lifestyle'] as Map<String, dynamic>?;
    if (lifestyle == null) return const SizedBox();

    return EnhancedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.sleep.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.moon,
                  color: AppColors.sleep,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Lifestyle & Recovery',
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.getTextPrimary(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (lifestyle['sleep'] != null)
            _buildInfoRow(
              'Sleep',
              lifestyle['sleep'].toString(),
              FontAwesomeIcons.moon,
            ),

          if (lifestyle['recovery'] != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              'Recovery',
              lifestyle['recovery'].toString(),
              FontAwesomeIcons.heart,
            ),
          ],

          if (lifestyle['steps_or_activity'] != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              'Activity',
              lifestyle['steps_or_activity'].toString(),
              FontAwesomeIcons.userGroup,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSafetyNotesSection(Map<String, dynamic> plan) {
    final safetyNotes = plan['safety_notes']?.toString();
    if (safetyNotes == null || safetyNotes.isEmpty) return const SizedBox();

    return EnhancedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.triangleExclamation,
                  color: AppColors.warning,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Important Notes',
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.getTextPrimary(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.warning.withOpacity(0.2)),
            ),
            child: Text(
              safetyNotes,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.getTextSecondary(context),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          Expanded(
            child: EnhancedButton(
              text: 'Back',
              onPressed: _saving ? null : () => Navigator.of(context).pop(),
              isOutlined: true,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: EnhancedButton(
              text: _saving ? 'Saving...' : 'Save Plan',
              onPressed: _saving ? null : _onSave,
              icon: FontAwesomeIcons.check,
              isLoading: _saving,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.getTextSecondary(context)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.getTextSecondary(context),
                ),
              ),
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.getTextPrimary(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionCard(
    String label,
    String value,
    String unit,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              text: value,
              style: AppTextStyles.titleMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
              children: [
                TextSpan(
                  text: ' $unit',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: color.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(Map<String, dynamic> dayData) {
    final dayName = dayData['day']?.toString() ?? '';
    final meals = dayData['meals'] as List<dynamic>? ?? [];
    final snacks = dayData['snacks'] as List<dynamic>? ?? [];
    final training = dayData['training'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.getBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dayName,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Meals
          if (meals.isNotEmpty) ...[
            _buildDaySection(
              'Meals',
              meals
                  .map(
                    (m) => '${m['name']}: ${(m['items'] as List).join(', ')}',
                  )
                  .toList(),
            ),
            if (snacks.isNotEmpty || training.isNotEmpty)
              const SizedBox(height: 8),
          ],

          // Snacks
          if (snacks.isNotEmpty) ...[
            _buildDaySection(
              'Snacks',
              snacks.map((s) => s.toString()).toList(),
            ),
            if (training.isNotEmpty) const SizedBox(height: 8),
          ],

          // Training
          if (training.isNotEmpty)
            _buildDaySection(
              'Training',
              training
                  .map(
                    (t) =>
                        '${t['focus'] ?? ''}: ${(t['items'] as List? ?? []).join(', ')}',
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildDaySection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.getTextSecondary(context),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(left: 8, top: 2),
            child: Text(
              '• $item',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.getTextPrimary(context),
                height: 1.3,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
