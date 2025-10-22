import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:final_project/utils/app_colors.dart';
import 'package:final_project/utils/text_styles.dart';
import 'package:final_project/services/health_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:final_project/services/mongo_service.dart';
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

  // Meal plan (Supabase) state
  bool _loadingPlan = true;
  String? _planError;
  List<_MealDay> _mealDays = const [];
  int _selectedDayIndex = 1;

  @override
  void initState() {
    super.initState();
    _loadTodayNutrition();
    _loadTargetsFromProfile();
    _loadGoalPrefs();
    _loadMealPlan();
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
          ? rows.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList()
          : <Map<String, dynamic>>[];

      final days = list
          .map((m) => _MealDay(
                id: m['id'],
                dayIndex: (m['day_index'] is int)
                    ? m['day_index'] as int
                    : int.tryParse('${m['day_index']}') ?? 1,
                dayLabel: (m['day_label'] ?? 'Day ${m['day_index'] ?? 1}').toString(),
                meals: _normalizeFoodList(m['meals']),
                snacks: _normalizeFoodList(m['snacks']),
              ))
          .toList()
        ..sort((a, b) => a.dayIndex.compareTo(b.dayIndex));

      if (!mounted) return;
      setState(() {
        _mealDays = days;
        _selectedDayIndex = days.isNotEmpty ? days.first.dayIndex : 1;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _planError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingPlan = false);
    }
  }

  // Normalize meals/snacks payloads from Supabase into List<Map<String,dynamic>>.
  // Accepts JSON array, stringified JSON, or list of strings.
  List<Map<String, dynamic>> _normalizeFoodList(dynamic raw) {
    if (raw == null) return const [];
    dynamic value = raw;
    // If it's a JSON string, try to decode
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        value = decoded;
      } catch (_) {
        // Treat as a single name string
        return [
          {'name': value}
        ];
      }
    }
    if (value is List) {
      final out = <Map<String, dynamic>>[];
      for (final item in value) {
        if (item == null) continue;
        if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          // Support grouped shape: { name: 'Breakfast', items: ['Overnight oats'] }
          final maybeItems = map['items'];
          final groupName = map['name']?.toString();
          if (maybeItems is List && groupName != null && groupName.isNotEmpty) {
            for (final it in maybeItems) {
              if (it == null) continue;
              if (it is String) {
                out.add({'name': it, 'course_type': groupName.toLowerCase()});
              } else if (it is Map) {
                final inner = Map<String, dynamic>.from(it);
                inner['course_type'] = (inner['course_type'] ?? groupName).toString().toLowerCase();
                out.add(inner);
              } else {
                out.add({'name': it.toString(), 'course_type': groupName.toLowerCase()});
              }
            }
          } else {
            out.add(map);
          }
        } else if (item is String) {
          out.add({'name': item});
        } else {
          out.add({'name': item.toString()});
        }
      }
      return out;
    }
    if (value is Map) {
      return [Map<String, dynamic>.from(value)];
    }
    return const [];
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
    // Supabase-driven meal plan with simple day selector + update
    if (_loadingPlan) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Meal Plans'),
          SizedBox(height: 16),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }
    if (_planError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Meal Plans', style: AppTextStyles.subtitle),
          const SizedBox(height: 16),
          Text(_planError!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
        ],
      );
    }
    if (_mealDays.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Meal Plans', style: AppTextStyles.subtitle),
          const SizedBox(height: 8),
          Text(
            'No meal plan found. Use Update to pick meals from MongoDB.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              icon: const FaIcon(FontAwesomeIcons.penToSquare, size: 16),
              onPressed: _openMealUpdateModal,
              label: const Text('Update'),
            ),
          )
        ],
      );
    }

    final selected = _mealDays.firstWhere(
      (d) => d.dayIndex == _selectedDayIndex,
      orElse: () => _mealDays.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Meal Plan', style: AppTextStyles.subtitle),
            TextButton.icon(
              onPressed: _openMealUpdateModal,
              icon: const FaIcon(FontAwesomeIcons.penToSquare, size: 14),
              label: const Text('Update'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _mealDays
                .map((d) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(d.dayLabel),
                        selected: d.dayIndex == _selectedDayIndex,
                        onSelected: (_) => setState(() => _selectedDayIndex = d.dayIndex),
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.divider.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Meals', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              if (selected.meals.isEmpty)
                Text('No meals added for ${selected.dayLabel}.', style: AppTextStyles.bodySmall)
              else
                ...selected.meals.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          const FaIcon(FontAwesomeIcons.bowlFood, size: 14),
                          const SizedBox(width: 8),
                          Expanded(child: Text((e.value['name'] ?? 'Meal').toString())),
                          if ((e.value['course_type'] ?? '').toString().isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text((e.value['course_type']).toString(), style: AppTextStyles.bodySmall.copyWith(color: AppColors.accent)),
                            ),
                          IconButton(
                            tooltip: 'Delete',
                            icon: const FaIcon(FontAwesomeIcons.trashCan, size: 16),
                            color: AppColors.error,
                            onPressed: () => _deleteMealAt(isSnack: false, index: e.key),
                          )
                        ],
                      ),
                    )),
              const SizedBox(height: 12),
              Text('Snacks', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              if (selected.snacks.isEmpty)
                Text('No snacks added for ${selected.dayLabel}.', style: AppTextStyles.bodySmall)
              else
                ...selected.snacks.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          const FaIcon(FontAwesomeIcons.cookieBite, size: 14),
                          const SizedBox(width: 8),
                          Expanded(child: Text((e.value['name'] ?? 'Snack').toString())),
                          IconButton(
                            tooltip: 'Delete',
                            icon: const FaIcon(FontAwesomeIcons.trashCan, size: 16),
                            color: AppColors.error,
                            onPressed: () => _deleteMealAt(isSnack: true, index: e.key),
                          )
                        ],
                      ),
                    )),
            ],
          ),
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
    // Deprecated card UI – plan is now Supabase-driven above.
    return const SizedBox.shrink();
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

  // ---- Meal plan helpers ----
  Future<void> _openMealUpdateModal() async {
    if (!mounted) return;
    final result = await showModalBottomSheet<_MealUpdateResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _MealUpdateModal(dayLabel: _currentDayLabel()),
    );
    if (result == null) return;
    await _saveMealsForDay(result.meals, replace: result.replace);
  }

  String _currentDayLabel() {
    final d = _mealDays.firstWhere(
      (e) => e.dayIndex == _selectedDayIndex,
      orElse: () => _mealDays.first,
    );
    return d.dayLabel;
  }

  Future<void> _saveMealsForDay(List<Map<String, dynamic>> newMeals, {bool replace = false}) async {
    final client = Supabase.instance.client;
    final uid = client.auth.currentUser?.id;
    try {
      // Find existing row for the selected day
      dynamic row = await client
          .from('meal_plan')
          .select('id, user_id, day_index, day_label, meals, snacks')
          .eq('day_index', _selectedDayIndex)
          .maybeSingle();

      final isSnack = (Map<String, dynamic> m) =>
          (m['course_type']?.toString().toLowerCase() ?? '').contains('snack');

      final newMealList = newMeals.where((m) => !isSnack(m)).toList();
      final newSnackList = newMeals.where(isSnack).toList();

      if (row == null) {
        // Insert a new day
        await client.from('meal_plan').insert({
          'user_id': uid,
          'day_index': _selectedDayIndex,
          'day_label': _currentDayLabel(),
          'meals': newMealList,
          'snacks': newSnackList,
        });
      } else {
        final existing = Map<String, dynamic>.from(row as Map);
        final currentMeals = _normalizeFoodList(existing['meals']);
        final currentSnacks = _normalizeFoodList(existing['snacks']);

        final updatedMeals = replace ? newMealList : [...currentMeals, ...newMealList];
        final updatedSnacks = replace ? newSnackList : [...currentSnacks, ...newSnackList];

        await client
            .from('meal_plan')
            .update({'meals': updatedMeals, 'snacks': updatedSnacks, if (uid != null) 'user_id': uid})
            .eq('day_index', _selectedDayIndex);
      }
      await _loadMealPlan();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meal plan updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to update: $e')));
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _buildMealPlanSection() => _buildMealPlans();

  Future<void> _deleteMealAt({required bool isSnack, required int index}) async {
    final client = Supabase.instance.client;
    try {
      // Get current row for selected day
      final row = await client
          .from('meal_plan')
          .select('id, meals, snacks')
          .eq('day_index', _selectedDayIndex)
          .maybeSingle();
      if (row == null) return;
      final map = Map<String, dynamic>.from(row as Map);
      final meals = _normalizeFoodList(map['meals']);
      final snacks = _normalizeFoodList(map['snacks']);
      if (isSnack) {
        if (index >= 0 && index < snacks.length) snacks.removeAt(index);
      } else {
        if (index >= 0 && index < meals.length) meals.removeAt(index);
      }
      await client
          .from('meal_plan')
          .update({'meals': meals, 'snacks': snacks})
          .eq('day_index', _selectedDayIndex);
      await _loadMealPlan();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item removed')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
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

class _MealDay {
  final dynamic id;
  final int dayIndex;
  final String dayLabel;
  final List<Map<String, dynamic>> meals;
  final List<Map<String, dynamic>> snacks;
  const _MealDay({
    required this.id,
    required this.dayIndex,
    required this.dayLabel,
    required this.meals,
    required this.snacks,
  });
}

class _MealUpdateResult {
  final List<Map<String, dynamic>> meals;
  final bool replace;
  const _MealUpdateResult(this.meals, {this.replace = false});
}

class _MealUpdateModal extends StatefulWidget {
  final String dayLabel;
  const _MealUpdateModal({required this.dayLabel});
  @override
  State<_MealUpdateModal> createState() => _MealUpdateModalState();
}

class _MealUpdateModalState extends State<_MealUpdateModal> {
  final TextEditingController _search = TextEditingController();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = const [];
  final Set<int> _selected = {};
  bool _replace = false;
  String _course = 'All';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await MongoService.filterMeals(limit: 50);
      if (!mounted) return;
      setState(() => _items = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _applySearch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await MongoService.filterMeals(
        name: _search.text.trim().isEmpty ? null : _search.text.trim(),
        courseType: _course == 'All' ? null : _course,
        limit: 100,
      );
      if (!mounted) return;
      setState(() => _items = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      builder: (context, controller) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Text('Update ${widget.dayLabel}', style: AppTextStyles.subtitle),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    )
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _search,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _applySearch(),
                        decoration: const InputDecoration(
                          hintText: 'Search meals by name...',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _course,
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('All')),
                        DropdownMenuItem(value: 'breakfast', child: Text('Breakfast')),
                        DropdownMenuItem(value: 'lunch', child: Text('Lunch')),
                        DropdownMenuItem(value: 'dinner', child: Text('Dinner')),
                        DropdownMenuItem(value: 'snack', child: Text('Snack')),
                      ],
                      onChanged: (v) => setState(() => _course = v ?? 'All'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(onPressed: _applySearch, child: const Text('Search')),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(child: Text(_error!))
                        : ListView.separated(
                            controller: controller,
                            itemCount: _items.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (ctx, i) {
                              final m = _items[i];
                              final name = (m['name'] ?? 'Meal').toString();
                              final course = (m['course_type'] ?? '').toString();
                              final selected = _selected.contains(i);
                              return CheckboxListTile(
                                value: selected,
                                onChanged: (v) => setState(() {
                                  if (v == true) {
                                    _selected.add(i);
                                  } else {
                                    _selected.remove(i);
                                  }
                                }),
                                title: Text(name),
                                subtitle: course.isEmpty ? null : Text(course),
                              );
                            },
                          ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: _replace,
                            onChanged: (v) => setState(() => _replace = v),
                          ),
                          const SizedBox(width: 6),
                          const Text('Replace existing for this day'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _selected.isEmpty
                                ? null
                                : () {
                                    final meals = _selected.map((i) => _items[i]).toList(growable: false);
                                    Navigator.of(context).pop(_MealUpdateResult(meals, replace: _replace));
                                  },
                            child: const Text('Save'),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
