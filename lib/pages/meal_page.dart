import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/cupertino.dart';
import 'package:final_project/utils/app_colors.dart';
import 'package:final_project/utils/text_styles.dart';

class MealPage extends StatelessWidget {
  const MealPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.divider.withValues(alpha: 0.5),
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
                      color: AppColors.textSecondary,
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
                  CupertinoIcons.heart_fill,
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
                  value: '1,650',
                  target: '2,200',
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildNutritionStatCard(
                  title: 'Protein',
                  value: '68g',
                  target: '90g',
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
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
    final valueNum = double.tryParse(value) ?? 0;
    final targetNum = double.tryParse(target) ?? 1;
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
              color: AppColors.textSecondary,
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
            backgroundColor: AppColors.divider,
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
        Text(
          "Today's Nutrition",
          style: AppTextStyles.subtitle,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.divider.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildMacroRow(
                title: 'Carbohydrates',
                value: '210g',
                target: '275g',
                color: AppColors.info,
                progress: 0.76,
              ),
              const SizedBox(height: 16),
              _buildMacroRow(
                title: 'Protein',
                value: '68g',
                target: '90g',
                color: AppColors.accent,
                progress: 0.76,
              ),
              const SizedBox(height: 16),
              _buildMacroRow(
                title: 'Fat',
                value: '45g',
                target: '73g',
                color: AppColors.warning,
                progress: 0.62,
              ),
              const SizedBox(height: 16),
              _buildMacroRow(
                title: 'Fiber',
                value: '18g',
                target: '25g',
                color: AppColors.success,
                progress: 0.72,
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
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            '$value / $target',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          flex: 2,
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.divider,
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
        Text(
          "Today's Meals",
          style: AppTextStyles.subtitle,
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
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
              const Divider(height: 1, color: AppColors.divider),
              _buildMealItem(
                mealType: 'Lunch',
                time: '12:30 PM',
                name: 'Grilled Chicken Salad',
                calories: '450 cal',
                completed: true,
                color: AppColors.success,
              ),
              const Divider(height: 1, color: AppColors.divider),
              _buildMealItem(
                mealType: 'Snack',
                time: '3:00 PM',
                name: 'Greek Yogurt with Nuts',
                calories: '180 cal',
                completed: true,
                color: AppColors.success,
              ),
              const Divider(height: 1, color: AppColors.divider),
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
          color: completed ? color.withValues(alpha: 0.1) : AppColors.divider.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(
          completed ? CupertinoIcons.check_mark : CupertinoIcons.circle,
          color: completed ? color : AppColors.textLight,
          size: 20,
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mealType,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            name,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      subtitle: Text(
        time,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textLight,
        ),
      ),
      trailing: Text(
        calories,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMealPlans() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meal Plans',
          style: AppTextStyles.subtitle,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMealPlanCard(
                title: 'Weight Loss',
                duration: '4 weeks',
                calories: '1,800 cal/day',
                color: AppColors.accent,
                icon: Icons.trending_down,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMealPlanCard(
                title: 'Muscle Gain',
                duration: '6 weeks',
                calories: '2,500 cal/day',
                color: AppColors.warning,
                icon: Icons.fitness_center,
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
                icon: Icons.balance,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMealPlanCard(
                title: 'Vegetarian',
                duration: 'Ongoing',
                calories: '2,000 cal/day',
                color: AppColors.healthPrimary,
                icon: Icons.eco,
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
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            duration,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
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
        Text(
          'Water Intake',
          style: AppTextStyles.subtitle,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
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
                      color: AppColors.textPrimary,
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
                backgroundColor: AppColors.divider,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.healthPrimary),
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
        Text(
          'Nutrition Tips',
          style: AppTextStyles.subtitle,
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
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
                icon: CupertinoIcons.lightbulb,
                title: 'Stay Hydrated',
                description: 'Drink at least 8 glasses of water daily for optimal body function.',
                color: AppColors.info,
              ),
              const Divider(height: 1, color: AppColors.divider),
              _buildTipItem(
                icon: CupertinoIcons.heart_fill,
                title: 'Eat More Fruits',
                description: 'Aim for 5 servings of fruits and vegetables daily.',
                color: AppColors.success,
              ),
              const Divider(height: 1, color: AppColors.divider),
              _buildTipItem(
                icon: CupertinoIcons.moon,
                title: 'Don\'t Skip Meals',
                description: 'Regular meals help maintain stable blood sugar levels.',
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
        child: Icon(
          icon,
          color: color,
          size: 20,
        ),
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
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
