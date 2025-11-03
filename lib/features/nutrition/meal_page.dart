import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:final_project/utils/app_colors.dart';
import 'package:final_project/utils/text_styles.dart';
import 'package:final_project/services/health_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:final_project/services/user_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:final_project/services/calorie_analysis_service.dart';
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

  double _targetKcal = 2200;
  double _targetCarbs = 275;
  double _targetProtein = 90;
  double _targetFat = 73;

  bool _analyzingPhoto = false;
  CalorieAnalysisResult? _lastAnalysis;
  XFile? _selectedImage;

  bool _loadingPlan = true;
  String? _planError;
  List<_MealDay> _mealDays = const [];
  int _selectedDayIndex = 1;

  @override
  void initState() {
    super.initState();
    _loadTodayNutrition();
    _loadTargetsFromProfile();
    _loadCalorieTarget();
    _loadGoalPrefs();
    _loadMealPlan();
  }

  Future<void> _loadCalorieTarget() async {
    try {
      final t = await UserService().getCaloriesTarget();
      if (!mounted) return;
      setState(() => _targetKcal = t.toDouble());
    } catch (_) {}
  }

  Future<void> _loadMealPlan() async {
    setState(() {
      _loadingPlan = true;
      _planError = null;
    });
    try {
      final client = Supabase.instance.client;
      final uid = client.auth.currentUser?.id;
      dynamic rows;
      try {
        if (uid != null) {
          rows = await client
              .from('meal_plan')
              .select('id, user_id, day_index, day_label, meals, snacks')
              .eq('user_id', uid)
              .order('day_index', ascending: true);
        }
        rows ??= await client
            .from('meal_plan')
            .select('id, user_id, day_index, day_label, meals, snacks')
            .order('day_index', ascending: true);
      } on PostgrestException catch (e) {
        throw Exception(e.message);
      }

      final list = (rows is List)
          ? rows
                .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
                .toList()
          : <Map<String, dynamic>>[];

      final days =
          list
              .map(
                (m) => _MealDay(
                  id: m['id'],
                  dayIndex: (m['day_index'] is int)
                      ? m['day_index'] as int
                      : int.tryParse('${m['day_index']}') ?? 1,
                  dayLabel: (m['day_label'] ?? 'Day 1').toString(),
                  meals: _parseMeals(m['meals']),
                  snacks: _parseSnacks(m['snacks']),
                ),
              )
              .toList()
            ..sort((a, b) => a.dayIndex.compareTo(b.dayIndex));

      if (!mounted) return;
      setState(() {
        _mealDays = days;
        if (days.isNotEmpty && _selectedDayIndex > days.length) {
          _selectedDayIndex = 1;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _planError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingPlan = false);
    }
  }

  List<Map<String, dynamic>> _parseMeals(dynamic value) {
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) return List<Map<String, dynamic>>.from(decoded);
      } catch (_) {}
      return [];
    }
    if (value is List) return List<Map<String, dynamic>>.from(value);
    return [];
  }

  List<Map<String, dynamic>> _parseSnacks(dynamic value) {
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) return List<Map<String, dynamic>>.from(decoded);
      } catch (_) {}
      return [];
    }
    if (value is List) return List<Map<String, dynamic>>.from(value);
    return [];
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
    } catch (_) {}
  }

  Future<void> _loadTargetsFromProfile() async {
    try {
      final profile = await UserService().getUserProfile();
      if (!mounted) return;

      // Get nutrition goal delta from UserService
      final delta = await UserService().getNutritionGoalDelta();

      // Compute targets using NutritionCalculator
      final targets = NutritionCalculator.computeTargetsFromSurvey(
        profile ?? {},
      );

      // Apply delta adjustment
      final adjustmentFactor = (100 + delta) / 100.0;

      setState(() {
        _targetCarbs = (targets['carbs'] ?? 0) * adjustmentFactor;
        _targetProtein = (targets['protein'] ?? 0) * adjustmentFactor;
        _targetFat = (targets['fat'] ?? 0) * adjustmentFactor;
        _targetKcal = (targets['calories'] ?? 0) * adjustmentFactor;
      });
    } catch (e) {
      debugPrint('Error loading targets: $e');
    }
  }

  Future<void> _loadGoalPrefs() async {
    try {
      await UserService().getNutritionGoal();
      await UserService().getNutritionGoalDelta();
      // These are already loaded via _loadTargetsFromProfile()
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([_loadTodayNutrition(), _loadMealPlan()]);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(isDark),
              const SizedBox(height: 24),

              // Daily Summary
              _buildDailySummary(isDark),
              const SizedBox(height: 24),

              // Nutrition Breakdown
              _buildNutritionBreakdown(isDark),
              const SizedBox(height: 24),

              // Photo Analysis
              _buildPhotoAnalysis(isDark),
              const SizedBox(height: 24),

              // Meal Plan Section
              _buildMealPlanSection(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nutrition Tracker',
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Track your daily meals & calories',
              style: AppTextStyles.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
          ),
          child: const Icon(
            FontAwesomeIcons.utensils,
            color: AppColors.accent,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildDailySummary(bool isDark) {
    final calorieProgress = (_energyKcal / _targetKcal * 100).clamp(0, 100);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withValues(alpha: 0.1),
            AppColors.primary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Theme.of(context).dividerColor : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today\'s Intake',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${calorieProgress.toStringAsFixed(0)}%',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: calorieProgress / 100,
              minHeight: 10,
              backgroundColor: isDark
                  ? const Color(0xFF2C2C2E)
                  : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation(AppColors.accent),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_energyKcal.toStringAsFixed(0)} / ${_targetKcal.toStringAsFixed(0)} kcal',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _energyKcal < _targetKcal
                    ? '${(_targetKcal - _energyKcal).toStringAsFixed(0)} left'
                    : '+${(_energyKcal - _targetKcal).toStringAsFixed(0)} over',
                style: AppTextStyles.bodySmall.copyWith(
                  color: _energyKcal < _targetKcal
                      ? AppColors.success
                      : AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionBreakdown(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Macronutrients',
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildMacroCard(
              icon: FontAwesomeIcons.leaf,
              label: 'Carbs',
              value: _carbsG.toStringAsFixed(0),
              target: _targetCarbs.toStringAsFixed(0),
              unit: 'g',
              color: AppColors.primary,
              isDark: isDark,
            ),
            const SizedBox(width: 12),
            _buildMacroCard(
              icon: FontAwesomeIcons.bolt,
              label: 'Protein',
              value: _proteinG.toStringAsFixed(0),
              target: _targetProtein.toStringAsFixed(0),
              unit: 'g',
              color: AppColors.accent,
              isDark: isDark,
            ),
            const SizedBox(width: 12),
            _buildMacroCard(
              icon: FontAwesomeIcons.droplet,
              label: 'Fat',
              value: _fatG.toStringAsFixed(0),
              target: _targetFat.toStringAsFixed(0),
              unit: 'g',
              color: AppColors.warning,
              isDark: isDark,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMacroCard({
    required IconData icon,
    required String label,
    required String value,
    required String target,
    required String unit,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Theme.of(context).dividerColor
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$value$unit',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'Goal: $target$unit',
              style: AppTextStyles.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoAnalysis(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Theme.of(context).dividerColor
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        FontAwesomeIcons.camera,
                        color: AppColors.success,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Analyze Food',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            'Take a photo to estimate calories',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _analyzingPhoto ? null : _pickFromGallery,
                icon: _analyzingPhoto
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(FontAwesomeIcons.image),
                label: Text(_analyzingPhoto ? 'Analyzing...' : 'Gallery'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
          if (_lastAnalysis != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analysis Result',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_lastAnalysis!.totalKcal.toStringAsFixed(0)} kcal detected',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMealPlanSection(bool isDark) {
    if (_loadingPlan) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_planError != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(FontAwesomeIcons.exclamation, color: AppColors.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _planError ?? 'Error loading meal plan',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
              ),
            ),
          ],
        ),
      );
    }

    if (_mealDays.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Theme.of(context).dividerColor
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          children: [
            Icon(
              FontAwesomeIcons.utensils,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No Meal Plan',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a meal plan to see recommendations',
              style: AppTextStyles.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    final selectedDay = _selectedDayIndex <= _mealDays.length
        ? _mealDays[_selectedDayIndex - 1]
        : _mealDays.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Meal Plan',
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(_mealDays.length, (i) {
              final day = _mealDays[i];
              final isSelected = _selectedDayIndex == day.dayIndex;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedDayIndex = day.dayIndex),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.accent
                          : (isDark ? const Color(0xFF2C2C2E) : Colors.white),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.accent
                            : (isDark
                                  ? Theme.of(context).dividerColor
                                  : const Color(0xFFE2E8F0)),
                      ),
                    ),
                    child: Text(
                      day.dayLabel,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 16),
        _buildMealItems(selectedDay, isDark),
      ],
    );
  }

  Widget _buildMealItems(_MealDay day, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (day.meals.isNotEmpty) ...[
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  FontAwesomeIcons.bowlFood,
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Meals',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...day.meals.map((meal) => _buildMealItem(meal, isDark)),
          const SizedBox(height: 16),
        ],
        if (day.snacks.isNotEmpty) ...[
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  FontAwesomeIcons.apple,
                  color: AppColors.warning,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Snacks',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...day.snacks.map((snack) => _buildMealItem(snack, isDark)),
        ],
      ],
    );
  }

  Widget _buildMealItem(Map<String, dynamic> item, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? Theme.of(context).dividerColor
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              FontAwesomeIcons.leaf,
              color: AppColors.accent,
              size: 14,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name']?.toString() ?? 'Food item',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (item['calories'] != null)
                  Text(
                    '${item['calories']} kcal',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            FontAwesomeIcons.chevronRight,
            size: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _selectedImage = image);

    if (!mounted) return;
    _showImagePreviewModal();
  }

  void _showImagePreviewModal() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image Preview
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(_selectedImage!.path),
                    height: 300,
                    width: double.maxFinite,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _analyzingPhoto ? null : _analyzeImage,
                      icon: _analyzingPhoto
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(FontAwesomeIcons.magnifyingGlass),
                      label: Text(_analyzingPhoto ? 'Analyzing...' : 'Analyze'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _deleteImage,
                      icon: const Icon(FontAwesomeIcons.trash),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    final bytes = await _selectedImage!.readAsBytes();
    setState(() => _analyzingPhoto = true);

    try {
      final result = await CalorieAnalysisService.analyzeImageBytes(bytes);
      if (!mounted) return;

      setState(() {
        _lastAnalysis = result;
        _analyzingPhoto = false;
      });

      if (result.success) {
        Navigator.pop(context); // Close modal
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(FontAwesomeIcons.check, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${result.totalKcal.toStringAsFixed(0)} kcal analyzed',
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _analyzingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(FontAwesomeIcons.exclamation, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(child: Text('Analysis failed')),
            ],
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _deleteImage() {
    setState(() {
      _selectedImage = null;
    });
    Navigator.pop(context); // Close modal
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(FontAwesomeIcons.check, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text('Photo deleted')),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class _MealDay {
  final int? id;
  final int dayIndex;
  final String dayLabel;
  final List<Map<String, dynamic>> meals;
  final List<Map<String, dynamic>> snacks;

  _MealDay({
    this.id,
    required this.dayIndex,
    required this.dayLabel,
    required this.meals,
    required this.snacks,
  });
}
