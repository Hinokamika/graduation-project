import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:final_project/utils/app_colors.dart';
import 'package:final_project/utils/text_styles.dart';
import 'package:final_project/services/health_service.dart';
import 'package:final_project/services/user_service.dart';
import 'package:final_project/utils/nutrition_calculator.dart';

class MealPage extends StatefulWidget {
  const MealPage({super.key});

  @override
  State<MealPage> createState() => _MealPageState();
}

class _MealPageState extends State<MealPage> {
  double _energyKcal = 0;
  double _carbsG = 0;
  double _proteinG = 0;
  double _fatG = 0;

  // Simple daily targets (can be made dynamic later)
  double _targetKcal = 2200;
  double _targetCarbs = 275;
  double _targetProtein = 90;
  double _targetFat = 73;
  bool _targetsFromProfile = false;
  String _goal = 'maintain';
  int _goalDelta = 15; // percent
  Map<String, dynamic>? _survey;

  @override
  void initState() {
    super.initState();
    _loadTodayNutrition();
    _loadTargetsFromProfile();
    _loadGoalPrefs();
  }

  Future<void> _loadTodayNutrition() async {
    try {
      final map = await HealthService().fetchTodayNutrition();
      if (!mounted) return;
      setState(() {
        _energyKcal = (map['energy_kcal'] ?? 0).toDouble();
        _carbsG = (map['carbs_g'] ?? 0).toDouble();
        _proteinG = (map['protein_g'] ?? 0).toDouble();
        _fatG = (map['fat_g'] ?? 0).toDouble();
      });
    } catch (_) {
      // leave defaults
    }
  }

  Future<void> _loadTargetsFromProfile() async {
    try {
      final profile = await UserService().getUserProfile();
      final survey = (profile?['survey_data'] is Map)
          ? Map<String, dynamic>.from(profile!['survey_data'] as Map)
          : null;
      if (survey == null) return;
      _survey = survey;

      final targets = NutritionCalculator.computeTargetsFromSurvey(
        survey,
        goal: _goal,
        deltaPercent: _goalDelta,
      );
      if (!mounted) return;
      setState(() {
        _targetsFromProfile = true;
        _targetKcal = (targets['energy_kcal'] ?? _targetKcal).toDouble();
        _targetProtein = (targets['protein_g'] ?? _targetProtein).toDouble();
        _targetFat = (targets['fat_g'] ?? _targetFat).toDouble();
        _targetCarbs = (targets['carbs_g'] ?? _targetCarbs).toDouble();
      });
    } catch (_) {
      // ignore errors and keep defaults
    }
  }

  Future<void> _loadGoalPrefs() async {
    try {
      final svc = UserService();
      final g = await svc.getNutritionGoal();
      final d = await svc.getNutritionGoalDelta();
      if (!mounted) return;
      setState(() {
        _goal = g;
        _goalDelta = d;
      });
      // Recompute if survey loaded
      if (_survey != null) {
        final targets = NutritionCalculator.computeTargetsFromSurvey(
          _survey!,
          goal: _goal,
          deltaPercent: _goalDelta,
        );
        if (!mounted) return;
        setState(() {
          _targetsFromProfile = true;
          _targetKcal = (targets['energy_kcal'] ?? _targetKcal).toDouble();
          _targetProtein = (targets['protein_g'] ?? _targetProtein).toDouble();
          _targetFat = (targets['fat_g'] ?? _targetFat).toDouble();
          _targetCarbs = (targets['carbs_g'] ?? _targetCarbs).toDouble();
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: 32),

            // Daily Nutrition Summary
            _buildDailyNutrition(),
            const SizedBox(height: 32),

            // Today's Meals
            _buildTodaysMeals(),
            const SizedBox(height: 32),

            // Meal Plans
            _buildMealPlans(),
            const SizedBox(height: 32),

            // Water Intake
            _buildWaterIntake(),
            const SizedBox(height: 32),

            // Nutrition Tips
            _buildNutritionTips(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black45
                : AppColors.divider.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nutrition',
                    style: AppTextStyles.heading2.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    'Fuel Your Body Right',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  FontAwesomeIcons.solidHeart,
                  color: AppColors.success,
                  size: 26,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildNutritionStatCard(
                  title: 'Calories',
                  value: _energyKcal.toStringAsFixed(0),
                  target: _targetKcal.toStringAsFixed(0),
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildNutritionStatCard(
                  title: 'Protein',
                  value: '${_proteinG.toStringAsFixed(0)}g',
                  target: '${_targetProtein.toStringAsFixed(0)}g',
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildNutritionStatCard({
    required String title,
    required String value,
    required String target,
    required Color color,
  }) {
    final valueNum =
        double.tryParse(value.replaceAll(RegExp(r'[^0-9\.]'), '')) ?? 0;
    final targetNum =
        double.tryParse(target.replaceAll(RegExp(r'[^0-9\.]'), '')) ?? 1;
    final progress = valueNum / targetNum;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$value / $target',
            style: AppTextStyles.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Theme.of(context).dividerColor,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyNutrition() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Today's Nutrition", style: AppTextStyles.subtitle),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black45
                    : AppColors.divider.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildMacroRow(
                title: 'Carbohydrates',
                value: '${_carbsG.toStringAsFixed(0)}g',
                target: '${_targetCarbs.toStringAsFixed(0)}g',
                color: AppColors.info,
                progress: (_targetCarbs == 0)
                    ? 0.0
                    : (_carbsG / _targetCarbs).clamp(0.0, 1.0),
              ),
              const SizedBox(height: 16),
              _buildMacroRow(
                title: 'Protein',
                value: '${_proteinG.toStringAsFixed(0)}g',
                target: '${_targetProtein.toStringAsFixed(0)}g',
                color: AppColors.accent,
                progress: (_targetProtein == 0)
                    ? 0.0
                    : (_proteinG / _targetProtein).clamp(0.0, 1.0),
              ),
              const SizedBox(height: 16),
              _buildMacroRow(
                title: 'Fat',
                value: '${_fatG.toStringAsFixed(0)}g',
                target: '${_targetFat.toStringAsFixed(0)}g',
                color: AppColors.warning,
                progress: (_targetFat == 0)
                    ? 0.0
                    : (_fatG / _targetFat).clamp(0.0, 1.0),
              ),
              const SizedBox(height: 16),
              _buildMacroRow(
                title: 'Fiber',
                value: '—',
                target: '25g',
                color: AppColors.success,
                progress: 0.0,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMacroRow({
    required String title,
    required String value,
    required String target,
    required Color color,
    required double progress,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            '$value / $target',
            style: AppTextStyles.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          flex: 2,
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Theme.of(context).dividerColor,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildTodaysMeals() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Today's Meals", style: AppTextStyles.subtitle),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Theme.of(context).brightness == Brightness.dark
                ? Border.all(color: Theme.of(context).dividerColor)
                : null,
            boxShadow: Theme.of(context).brightness == Brightness.dark
                ? []
                : [
                    BoxShadow(
                      color: AppColors.divider.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            children: [
              _buildMealItem(
                mealType: 'Breakfast',
                time: '8:00 AM',
                name: 'Oatmeal with Berries',
                calories: '320 cal',
                completed: true,
                color: AppColors.success,
              ),
              Divider(height: 1, color: Theme.of(context).dividerColor),
              _buildMealItem(
                mealType: 'Lunch',
                time: '12:30 PM',
                name: 'Grilled Chicken Salad',
                calories: '450 cal',
                completed: true,
                color: AppColors.success,
              ),
              Divider(height: 1, color: Theme.of(context).dividerColor),
              _buildMealItem(
                mealType: 'Snack',
                time: '3:00 PM',
                name: 'Greek Yogurt with Nuts',
                calories: '180 cal',
                completed: true,
                color: AppColors.success,
              ),
              Divider(height: 1, color: Theme.of(context).dividerColor),
              _buildMealItem(
                mealType: 'Dinner',
                time: '7:00 PM',
                name: 'Salmon with Vegetables',
                calories: '520 cal',
                completed: false,
                color: AppColors.warning,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMealItem({
    required String mealType,
    required String time,
    required String name,
    required String calories,
    required bool completed,
    required Color color,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: completed
              ? color.withValues(alpha: 0.1)
              : Theme.of(context).dividerColor.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(
          completed ? FontAwesomeIcons.check : FontAwesomeIcons.circle,
          color: completed
              ? color
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          size: 20,
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mealType,
            style: AppTextStyles.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          Text(
            name,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
      subtitle: Text(
        time,
        style: AppTextStyles.bodySmall.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      trailing: Text(
        calories,
        style: AppTextStyles.bodySmall.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMealPlans() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Meal Plans', style: AppTextStyles.subtitle),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMealPlanCard(
                title: 'Weight Loss',
                duration: '4 weeks',
                calories: '1,800 cal/day',
                color: AppColors.accent,
                icon: FontAwesomeIcons.arrowTrendDown,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMealPlanCard(
                title: 'Muscle Gain',
                duration: '6 weeks',
                calories: '2,500 cal/day',
                color: AppColors.warning,
                icon: FontAwesomeIcons.dumbbell,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMealPlanCard(
                title: 'Balanced',
                duration: 'Ongoing',
                calories: '2,200 cal/day',
                color: AppColors.success,
                icon: FontAwesomeIcons.scaleBalanced,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMealPlanCard(
                title: 'Vegetarian',
                duration: 'Ongoing',
                calories: '2,000 cal/day',
                color: AppColors.healthPrimary,
                icon: FontAwesomeIcons.leaf,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMealPlanCard({
    required String title,
    required String duration,
    required String calories,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.divider.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            duration,
            style: AppTextStyles.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            calories,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterIntake() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Water Intake', style: AppTextStyles.subtitle),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Theme.of(context).brightness == Brightness.dark
                ? Border.all(color: Theme.of(context).dividerColor)
                : null,
            boxShadow: Theme.of(context).brightness == Brightness.dark
                ? []
                : [
                    BoxShadow(
                      color: AppColors.divider.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Daily Goal: 2.5L',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    '1.8L / 2.5L',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.healthPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: 0.72,
                backgroundColor: Theme.of(context).dividerColor,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.healthPrimary,
                ),
                borderRadius: BorderRadius.circular(8),
                minHeight: 12,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildWaterButton('250ml'),
                  _buildWaterButton('500ml'),
                  _buildWaterButton('750ml'),
                  _buildWaterButton('1L'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWaterButton(String amount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.healthPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        amount,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.healthPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildNutritionTips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nutrition Tips', style: AppTextStyles.subtitle),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Theme.of(context).brightness == Brightness.dark
                ? Border.all(color: Theme.of(context).dividerColor)
                : null,
            boxShadow: Theme.of(context).brightness == Brightness.dark
                ? []
                : [
                    BoxShadow(
                      color: AppColors.divider.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            children: [
              _buildTipItem(
                icon: FontAwesomeIcons.lightbulb,
                title: 'Stay Hydrated',
                description:
                    'Drink at least 8 glasses of water daily for optimal body function.',
                color: AppColors.info,
              ),
              Divider(height: 1, color: Theme.of(context).dividerColor),
              _buildTipItem(
                icon: FontAwesomeIcons.solidHeart,
                title: 'Eat More Fruits',
                description:
                    'Aim for 5 servings of fruits and vegetables daily.',
                color: AppColors.success,
              ),
              Divider(height: 1, color: Theme.of(context).dividerColor),
              _buildTipItem(
                icon: FontAwesomeIcons.moon,
                title: 'Don\'t Skip Meals',
                description:
                    'Regular meals help maintain stable blood sugar levels.',
                color: AppColors.warning,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTipItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        description,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
      ),
    );
  }

  // Widget _buildGoalSelector() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         'Goal',
  //         style: AppTextStyles.bodySmall.copyWith(
  //           color: AppColors.textSecondary,
  //         ),
  //       ),
  //       const SizedBox(height: 8),
  //       Row(
  //         children: [
  //           _goalChip('Lose'),
  //           const SizedBox(width: 8),
  //           _goalChip('Maintain'),
  //           const SizedBox(width: 8),
  //           _goalChip('Gain'),
  //           const Spacer(),
  //           if (_goal.toLowerCase() != 'maintain') _deltaChips(),
  //         ],
  //       ),
  //     ],
  //   );
  // }

  // Widget _goalChip(String label) {
  //   final v = label.toLowerCase();
  //   final selected = _goal == v;
  //   return ChoiceChip(
  //     label: Text(label),
  //     selected: selected,
  //     onSelected: (s) async {
  //       if (!s) return;
  //       setState(() => _goal = v);
  //       await UserService().setNutritionGoal(v);
  //       if (_survey != null) {
  //         final targets = NutritionCalculator.computeTargetsFromSurvey(
  //           _survey!,
  //           goal: _goal,
  //           deltaPercent: _goalDelta,
  //         );
  //         if (!mounted) return;
  //         setState(() {
  //           _targetsFromProfile = true;
  //           _targetKcal = (targets['energy_kcal'] ?? _targetKcal).toDouble();
  //           _targetProtein = (targets['protein_g'] ?? _targetProtein)
  //               .toDouble();
  //           _targetFat = (targets['fat_g'] ?? _targetFat).toDouble();
  //           _targetCarbs = (targets['carbs_g'] ?? _targetCarbs).toDouble();
  //         });
  //       }
  //     },
  //   );
  // }

  // Widget _deltaChips() {
  //   Widget chip(int p) => Padding(
  //     padding: const EdgeInsets.only(left: 4),
  //     child: ChoiceChip(
  //       label: Text('$p%'),
  //       selected: _goalDelta == p,
  //       onSelected: (s) async {
  //         if (!s) return;
  //         setState(() => _goalDelta = p);
  //         await UserService().setNutritionGoalDelta(p);
  //         if (_survey != null) {
  //           final targets = NutritionCalculator.computeTargetsFromSurvey(
  //             _survey!,
  //             goal: _goal,
  //             deltaPercent: _goalDelta,
  //           );
  //           if (!mounted) return;
  //           setState(() {
  //             _targetsFromProfile = true;
  //             _targetKcal = (targets['energy_kcal'] ?? _targetKcal).toDouble();
  //             _targetProtein = (targets['protein_g'] ?? _targetProtein)
  //                 .toDouble();
  //             _targetFat = (targets['fat_g'] ?? _targetFat).toDouble();
  //             _targetCarbs = (targets['carbs_g'] ?? _targetCarbs).toDouble();
  //           });
  //         }
  //       },
  //     ),
  //   );
  //   return Row(children: [chip(10), chip(15), chip(20)]);
  // }
}
