import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:final_project/utils/app_colors.dart';
import 'package:final_project/utils/text_styles.dart';
import 'package:final_project/services/health_service.dart';
import 'package:final_project/services/nutrition_intake_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:final_project/services/user_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:final_project/services/calorie_analysis_service.dart';
import 'package:final_project/utils/nutrition_calculator.dart';
import 'package:final_project/services/nutrition_service.dart';
import 'package:final_project/features/nutrition/nutrition_history_page.dart';

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
  double _sugarG = 0;

  double _targetKcal = 0;
  double _targetCarbs = 0;
  double _targetProtein = 0;
  double _targetFat = 0;
  double _targetSugar = 0;

  bool _analyzingPhoto = false;
  CalorieAnalysisResult? _lastAnalysis;
  XFile? _selectedImage;

  bool _loadingPlan = true;
  String? _planError;
  List<_MealDay> _mealDays = const [];
  int _selectedDayIndex = 1;
  Timer? _midnightTimer;
  String? _loadedDateKey;

  @override
  void initState() {
    super.initState();
    _loadTodayNutrition();
    _loadTargetsFromProfile();
    _loadCalorieTarget();
    _loadGoalPrefs();
    _loadMealPlan();
    _scheduleMidnightReset();
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
    // Accepts JSON string or List. Normalizes each entry to a Map.
    dynamic raw = value;
    if (raw is String) {
      try {
        raw = jsonDecode(raw);
      } catch (_) {
        raw = [];
      }
    }
    if (raw is! List) return [];
    // Map entries can be Map or String. Convert strings to a map with a name.
    return raw.map<Map<String, dynamic>>((e) {
      if (e is Map) return Map<String, dynamic>.from(e);
      return {'name': e.toString()};
    }).toList();
  }

  List<String> _parseSnacks(dynamic value) {
    // Snacks are typically a list of strings. Be defensive and normalize.
    dynamic raw = value;
    if (raw is String) {
      try {
        raw = jsonDecode(raw);
      } catch (_) {
        raw = [];
      }
    }
    if (raw is! List) return [];
    return raw.map((e) => e.toString()).toList();
  }

  Future<void> _loadTodayNutrition() async {
    try {
      // Track current date key for day-change detection
      final now = DateTime.now();
      final key =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      _loadedDateKey = key;
      final map = await HealthService().fetchTodayNutrition();
      // Merge with any user-logged intake stored in Supabase
      final intake = await NutritionIntakeService().getTodayTotals();
      map['energy_kcal'] =
          (map['energy_kcal'] ?? 0).toDouble() + (intake['energy_kcal'] ?? 0.0);
      map['carbs_g'] =
          (map['carbs_g'] ?? 0).toDouble() + (intake['carbs_g'] ?? 0.0);
      map['protein_g'] =
          (map['protein_g'] ?? 0).toDouble() + (intake['protein_g'] ?? 0.0);
      map['fat_g'] = (map['fat_g'] ?? 0).toDouble() + (intake['fat_g'] ?? 0.0);
      map['sugar_g'] =
          (map['sugar_g'] ?? 0).toDouble() + (intake['sugar_g'] ?? 0.0);
      if (!mounted) return;
      setState(() {
        _energyKcal = (map['energy_kcal'] ?? 0).toDouble();
        _carbsG = (map['carbs_g'] ?? 0).toDouble();
        _proteinG = (map['protein_g'] ?? 0).toDouble();
        _fatG = (map['fat_g'] ?? 0).toDouble();
        _sugarG = (map['sugar_g'] ?? 0).toDouble();
      });
    } catch (_) {}
  }

  void _scheduleMidnightReset() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));
    final duration = nextMidnight.difference(now);
    _midnightTimer = Timer(duration, () async {
      if (!mounted) return;
      setState(() {
        _energyKcal = 0;
        _carbsG = 0;
        _proteinG = 0;
        _fatG = 0;
        _sugarG = 0;
      });
      await _loadTodayNutrition();
      // Schedule for the next day
      _scheduleMidnightReset();
    });
  }

  Future<void> _loadTargetsFromProfile() async {
    try {
      // 1. Try to load from Nutrition History (Supabase) - Persisted goals
      final history = await NutritionService().getGoalHistory();
      if (history.isNotEmpty) {
        final latest = history.first;
        if (mounted) {
          setState(() {
            _targetKcal = (latest['calories_target'] ?? 0).toDouble();
            _targetCarbs = (latest['carbs_g'] ?? 0).toDouble();
            _targetProtein = (latest['protein_g'] ?? 0).toDouble();
            _targetFat = (latest['fat_g'] ?? 0).toDouble();
            _targetSugar = (latest['sugar_g'] ?? 0).toDouble();
          });

          // Sync to in-memory cache
          final us = UserService();
          await us.setCaloriesTarget(_targetKcal.toInt());
          if (latest['goal'] != null) await us.setNutritionGoal(latest['goal']);
          if (latest['delta_percent'] != null) {
            await us.setNutritionGoalDelta(latest['delta_percent']);
          }
          return;
        }
      }

      // 2. Fallback: Calculate from Profile (if no history exists)
      final profile = await UserService().getUserProfile();
      if (!mounted) return;

      // Get nutrition goal and delta from UserService (defaults if not set)
      final goal = await UserService().getNutritionGoal();
      final delta = await UserService().getNutritionGoalDelta();

      // Compute targets using NutritionCalculator
      final t = NutritionCalculator.computeTargetsFromSurvey(
        profile ?? {},
        goal: goal,
        deltaPercent: delta,
      );

      setState(() {
        _targetCarbs = (t['carbs_g'] ?? 0).toDouble();
        _targetProtein = (t['protein_g'] ?? 0).toDouble();
        _targetFat = (t['fat_g'] ?? 0).toDouble();
        _targetKcal = (t['energy_kcal'] ?? 0).toDouble();
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
              Row(
                children: [
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
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _showNutritionGoalDialog,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                    ),
                    icon: const Icon(FontAwesomeIcons.sliders, size: 14),
                    label: const Text('Set Goal'),
                  ),
                ],
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
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildMacroCard(
              icon: FontAwesomeIcons.droplet,
              label: 'Fat',
              value: _fatG.toStringAsFixed(0),
              target: _targetFat.toStringAsFixed(0),
              unit: 'g',
              color: AppColors.warning,
              isDark: isDark,
            ),
            const SizedBox(width: 12),
            _buildMacroCard(
              icon: FontAwesomeIcons.cubes,
              label: 'Sugar',
              value: _sugarG.toStringAsFixed(0),
              target: _targetSugar.toStringAsFixed(0),
              unit: 'g',
              color: AppColors.info,
              isDark: isDark,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NutritionHistoryPage()),
              );
            },
            icon: const Icon(FontAwesomeIcons.clockRotateLeft, size: 14),
            label: const Text('Show History'),
          ),
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
          ...day.snacks.map((snack) => _buildSnackItem(snack, isDark)),
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
                  item['name']?.toString() ??
                      item['title']?.toString() ??
                      'Food item',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                // Show calories if present; otherwise show items/description when available
                if (item['calories'] != null)
                  Text(
                    '${item['calories']} kcal',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 11,
                    ),
                  )
                else if (item['items'] is List &&
                    (item['items'] as List).isNotEmpty)
                  Text(
                    (item['items'] as List).map((e) => e.toString()).join(', '),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                else if (item['description'] != null)
                  Text(
                    item['description'].toString(),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSnackItem(String snack, bool isDark) {
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
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              FontAwesomeIcons.apple,
              color: AppColors.warning,
              size: 14,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              snack,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
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
                      onPressed: _analyzingPhoto
                          ? null
                          : () => _analyzeImageFromDialog(context),
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
                      onPressed: () => _deleteImageFromDialog(context),
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
        Navigator.pop(context); // Close preview modal
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
            duration: const Duration(seconds: 2),
          ),
        );
        // Show analysis details modal
        await _showAnalysisDetailsDialog(result);
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

  Future<void> _analyzeImageFromDialog(BuildContext dialogContext) async {
    if (_selectedImage == null) return;
    // Start analyzing and close the preview dialog immediately so
    // the main page can show the loading animation/state.
    setState(() => _analyzingPhoto = true);
    // Close the preview dialog now to reveal the loading state on the page
    if (Navigator.of(dialogContext).canPop()) {
      Navigator.of(dialogContext).pop();
    }
    final bytes = await _selectedImage!.readAsBytes();
    try {
      final result = await CalorieAnalysisService.analyzeImageBytes(bytes);
      if (!mounted) return;
      setState(() {
        _lastAnalysis = result;
        _analyzingPhoto = false;
      });
      if (result.success) {
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
            duration: const Duration(seconds: 2),
          ),
        );
        await _showAnalysisDetailsDialog(result);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _analyzingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(FontAwesomeIcons.exclamation, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Analysis failed')),
            ],
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _deleteImageFromDialog(BuildContext dialogContext) {
    setState(() {
      _selectedImage = null;
    });
    Navigator.of(dialogContext).pop();
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

  Future<void> _showAnalysisDetailsDialog(CalorieAnalysisResult result) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            'Meal Analysis',
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Summary
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            FontAwesomeIcons.fire,
                            color: AppColors.success,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${result.totalKcal.toStringAsFixed(0)} kcal total',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Macros
                if (result.carbsG != null ||
                    result.proteinG != null ||
                    result.fatG != null ||
                    result.sugarG != null ||
                    result.fiberG != null ||
                    result.sodiumMg != null ||
                    result.saturatedFatG != null) ...[
                  Text(
                    'Estimated Macros',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      if (result.carbsG != null)
                        _macroChip(
                          FontAwesomeIcons.leaf,
                          'Carbs',
                          result.carbsG!,
                          AppColors.primary,
                        ),
                      if (result.proteinG != null)
                        _macroChip(
                          FontAwesomeIcons.bolt,
                          'Protein',
                          result.proteinG!,
                          AppColors.accent,
                        ),
                      if (result.fatG != null)
                        _macroChip(
                          FontAwesomeIcons.droplet,
                          'Fat',
                          result.fatG!,
                          AppColors.warning,
                        ),
                      if (result.sugarG != null)
                        _macroChip(
                          FontAwesomeIcons.cubes,
                          'Sugar',
                          result.sugarG!,
                          AppColors.info,
                        ),
                      if (result.fiberG != null)
                        _macroChip(
                          FontAwesomeIcons.leaf,
                          'Fiber',
                          result.fiberG!,
                          AppColors.success,
                        ),
                      if (result.saturatedFatG != null)
                        _macroChip(
                          FontAwesomeIcons.egg,
                          'Sat. Fat',
                          result.saturatedFatG!,
                          AppColors.error,
                        ),
                      if (result.sodiumMg != null)
                        _macroChip(
                          FontAwesomeIcons.water,
                          'Sodium',
                          result.sodiumMg!,
                          AppColors.calories,
                          unit: 'mg',
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // Food items
                if (result.items.isNotEmpty) ...[
                  Text(
                    'Detected Items',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...result.items.map(
                    (it) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.getBorder(context)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                FontAwesomeIcons.utensils,
                                size: 14,
                                color: AppColors.accent,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  it.name,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              Text(
                                '${it.calories.toStringAsFixed(0)} kcal',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                          if ((it.portionSize ?? '').isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Portion: ${it.portionSize}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                          if (it.macros != null) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                if (it.macros!.carbsG != null)
                                  _macroChip(
                                    FontAwesomeIcons.leaf,
                                    'Carbs',
                                    it.macros!.carbsG!,
                                    AppColors.primary,
                                  ),
                                if (it.macros!.proteinG != null)
                                  _macroChip(
                                    FontAwesomeIcons.bolt,
                                    'Protein',
                                    it.macros!.proteinG!,
                                    AppColors.accent,
                                  ),
                                if (it.macros!.fatG != null)
                                  _macroChip(
                                    FontAwesomeIcons.droplet,
                                    'Fat',
                                    it.macros!.fatG!,
                                    AppColors.warning,
                                  ),
                                if (it.macros!.sugarG != null)
                                  _macroChip(
                                    FontAwesomeIcons.cubes,
                                    'Sugar',
                                    it.macros!.sugarG!,
                                    AppColors.info,
                                  ),
                                if (it.macros!.fiberG != null)
                                  _macroChip(
                                    FontAwesomeIcons.leaf,
                                    'Fiber',
                                    it.macros!.fiberG!,
                                    AppColors.success,
                                  ),
                                if (it.macros!.saturatedFatG != null)
                                  _macroChip(
                                    FontAwesomeIcons.egg,
                                    'Sat. Fat',
                                    it.macros!.saturatedFatG!,
                                    AppColors.error,
                                  ),
                                if (it.macros!.sodiumMg != null)
                                  _macroChip(
                                    FontAwesomeIcons.water,
                                    'Sodium',
                                    it.macros!.sodiumMg!,
                                    AppColors.calories,
                                    unit: 'mg',
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
          actions: [
            if (result.success)
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await NutritionIntakeService().addEntry(
                      energyKcal: result.totalKcal,
                      carbsG: result.carbsG,
                      proteinG: result.proteinG,
                      fatG: result.fatG,
                      sugarG: result.sugarG,
                      source: 'ai_analysis',
                      metadata: {
                        'reasoning': result.reasoning,
                        if ((result.confidenceLevel ?? '').isNotEmpty)
                          'confidence_level': result.confidenceLevel,
                        if (result.mealQuality != null)
                          'meal_quality': {
                            if (result.mealQuality!.balanceScore != null)
                              'balance_score': result.mealQuality!.balanceScore,
                            if ((result.mealQuality!.notes ?? '').isNotEmpty)
                              'notes': result.mealQuality!.notes,
                          },
                        'macros': {
                          if (result.carbsG != null) 'carbs_g': result.carbsG,
                          if (result.proteinG != null)
                            'protein_g': result.proteinG,
                          if (result.fatG != null) 'fat_g': result.fatG,
                          if (result.sugarG != null) 'sugar_g': result.sugarG,
                          if (result.fiberG != null) 'fiber_g': result.fiberG,
                          if (result.saturatedFatG != null)
                            'saturated_fat_g': result.saturatedFatG,
                          if (result.sodiumMg != null)
                            'sodium_mg': result.sodiumMg,
                        },
                        'items': result.items
                            .map(
                              (e) => {
                                'name': e.name,
                                'calories': e.calories,
                                if ((e.portionSize ?? '').isNotEmpty)
                                  'portion_size': e.portionSize,
                                if (e.macros != null)
                                  'macros': {
                                    if (e.macros!.carbsG != null)
                                      'carbs_g': e.macros!.carbsG,
                                    if (e.macros!.proteinG != null)
                                      'protein_g': e.macros!.proteinG,
                                    if (e.macros!.fatG != null)
                                      'fat_g': e.macros!.fatG,
                                    if (e.macros!.sugarG != null)
                                      'sugar_g': e.macros!.sugarG,
                                    if (e.macros!.fiberG != null)
                                      'fiber_g': e.macros!.fiberG,
                                    if (e.macros!.saturatedFatG != null)
                                      'saturated_fat_g':
                                          e.macros!.saturatedFatG,
                                    if (e.macros!.sodiumMg != null)
                                      'sodium_mg': e.macros!.sodiumMg,
                                  },
                              },
                            )
                            .toList(),
                      },
                    );
                    // Refresh today totals in UI
                    await _loadTodayNutrition();
                    if (!mounted) return;
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Added to Today\'s Intake')),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                },
                icon: const Icon(FontAwesomeIcons.plus),
                label: const Text("Add to Today's Intake"),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _macroChip(
    IconData icon,
    String label,
    double value,
    Color color, {
    String unit = 'g',
    int decimals = 0,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: ${value.toStringAsFixed(decimals)}$unit',
            style: AppTextStyles.bodySmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Future<void> _showNutritionGoalDialog() async {
    final us = UserService();
    final currentGoal = await us.getNutritionGoal();
    final currentDelta = await us.getNutritionGoalDelta();
    final currentKcal = await us.getCaloriesTarget();

    String goal = currentGoal; // 'lose' | 'maintain' | 'gain'
    int delta = currentDelta; // 10/15/20
    final kcController = TextEditingController(text: currentKcal.toString());
    // Pre-fill macros with current targets
    final carbsController = TextEditingController(
      text: _targetCarbs.toStringAsFixed(0),
    );
    final proteinController = TextEditingController(
      text: _targetProtein.toStringAsFixed(0),
    );
    final fatController = TextEditingController(
      text: _targetFat.toStringAsFixed(0),
    );
    final sugarController = TextEditingController(
      text: _targetSugar.toStringAsFixed(0),
    );

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: Text(
                'Nutrition Goal',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Calories
                    TextField(
                      controller: kcController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(FontAwesomeIcons.fire, size: 14),
                        labelText: 'Daily Calories Target (kcal)',
                        hintText: 'e.g., 2200',
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Macros
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: carbsController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(
                                FontAwesomeIcons.breadSlice,
                                size: 14,
                              ),
                              labelText: 'Carbs (g)',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: proteinController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(FontAwesomeIcons.egg, size: 14),
                              labelText: 'Protein (g)',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: fatController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(FontAwesomeIcons.droplet, size: 14),
                        labelText: 'Fat (g)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: sugarController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(FontAwesomeIcons.cubes, size: 14),
                        labelText: 'Sugar (g)',
                      ),
                    ),
                    // (Show History moved out of modal to main page under macros)
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await us.setNutritionGoal(goal);
                    await us.setNutritionGoalDelta(delta);
                    final kcal = int.tryParse(kcController.text.trim());
                    if (kcal != null && kcal > 0) {
                      await us.setCaloriesTarget(kcal);
                    }
                    // Persist to Supabase history
                    final carbs = double.tryParse(carbsController.text.trim());
                    final protein = double.tryParse(
                      proteinController.text.trim(),
                    );
                    final fat = double.tryParse(fatController.text.trim());
                    try {
                      await NutritionService().saveGoalEntry(
                        goal: goal,
                        deltaPercent: delta,
                        caloriesTarget: kcal,
                        carbsG: carbs,
                        proteinG: protein,
                        fatG: fat,
                        sugarG: double.tryParse(sugarController.text.trim()),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                    if (!mounted) return;
                    Navigator.of(context).pop();
                    // Refresh targets
                    await _loadTargetsFromProfile();
                    await _loadCalorieTarget();
                    // Update on-screen targets with manual macros if provided
                    setState(() {
                      if (carbs != null) _targetCarbs = carbs;
                      if (protein != null) _targetProtein = protein;
                      if (fat != null) _targetFat = fat;
                      if (kcal != null) _targetKcal = kcal.toDouble();
                      final sugar = double.tryParse(
                        sugarController.text.trim(),
                      );
                      if (sugar != null) _targetSugar = sugar;
                    });
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nutrition goal saved')),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteImage() {
    // Legacy path: if invoked without dialog context, just clear selection.
    setState(() {
      _selectedImage = null;
    });
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    super.dispose();
  }
}

class _MealDay {
  final int? id;
  final int dayIndex;
  final String dayLabel;
  final List<Map<String, dynamic>> meals;
  final List<String> snacks;

  _MealDay({
    this.id,
    required this.dayIndex,
    required this.dayLabel,
    required this.meals,
    required this.snacks,
  });
}
