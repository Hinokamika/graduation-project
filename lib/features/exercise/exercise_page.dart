import 'package:flutter/material.dart';
import 'package:final_project/utils/app_colors.dart';
import 'package:final_project/utils/text_styles.dart';
import 'package:final_project/services/mongo_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:final_project/features/exercise/exercise_detail_page.dart';
import 'package:final_project/features/exercise/today_workout_detail_page.dart';
import 'package:final_project/features/exercise/exercise_list_page.dart';

class ExercisePage extends StatefulWidget {
  const ExercisePage({super.key});

  @override
  State<ExercisePage> createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage> {
  bool _loadingPlan = true;
  String? _planError;
  List<_PlanDay> _planDays = const [];
  int _currentDayIndex = 1; // 1-based

  @override
  void initState() {
    super.initState();
    _loadWorkoutPlan();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([_loadWorkoutPlan()]);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              const SizedBox(height: 32),

              // Today's Workout
              _buildTodaysWorkout(),
              const SizedBox(height: 32),

              // Weekly Progress
              _buildWeeklyProgress(),
              const SizedBox(height: 32),

              // Exercise Categories
              _buildExerciseCategories(),
              const SizedBox(height: 100), // Extra space for FAB
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'browse_exercises',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ExerciseListPage()),
              );
            },
            backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
            foregroundColor: AppColors.accent,
            child: const FaIcon(FontAwesomeIcons.magnifyingGlass, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
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
                    'Exercise',
                    style: AppTextStyles.heading2.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    'Stay Active, Stay Healthy',
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
                  color: AppColors.accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 17,
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.dumbbell,
                    color: AppColors.accent,
                    size: 26,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
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
            value,
            style: AppTextStyles.heading3.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(subtitle, style: AppTextStyles.bodySmall.copyWith(color: color)),
        ],
      ),
    );
  }

  String _formatInt(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idx = s.length - i;
      buf.write(s[i]);
      if (idx % 3 == 1 && i != s.length - 1) buf.write(',');
    }
    return buf.toString();
  }

  String _formatKcal(double v) {
    final rounded = v.round();
    return '${_formatInt(rounded)} kcal';
  }

  Future<void> _loadWorkoutPlan() async {
    setState(() {
      _loadingPlan = true;
      _planError = null;
    });
    try {
      final client = Supabase.instance.client;
      final uid = client.auth.currentUser?.id;
      if (uid == null) {
        setState(() {
          _planDays = const [];
          _planError = 'Please sign in to view your workout plan.';
        });
        return;
      }
      dynamic rows;
      try {
        rows = await client
            .from('workout_plan')
            .select(
              'id,exercise_name,description,difficulty_level,exercise_category,duration_minutes,repetitions,day,created_at,finished',
            )
            .eq('user_id', uid)
            .order('created_at', ascending: true);
      } on PostgrestException catch (e) {
        // Fallback when user_id column doesn't exist in workout_plan
        if (e.code == '42703' || (e.message).toString().contains('user_id')) {
          rows = await client
              .from('workout_plan')
              .select(
                'id,exercise_name,description,difficulty_level,exercise_category,duration_minutes,repetitions,day,created_at,finished',
              )
              .order('created_at', ascending: true);
        } else {
          rethrow;
        }
      }
      var list = (rows is List) ? rows.cast<Map>() : <Map>[];
      // If the filtered query returned no rows (e.g., user_id is NULL in DB),
      // try an unfiltered read so the app reflects Supabase data instead of falling back to Mongo.
      if (list.isEmpty) {
        final fallbackRows = await client
            .from('workout_plan')
            .select(
              'id,exercise_name,description,difficulty_level,exercise_category,duration_minutes,repetitions,day,created_at,finished',
            )
            .order('created_at', ascending: true);
        final listFallback = (fallbackRows is List)
            ? fallbackRows.cast<Map>()
            : <Map>[];
        if (listFallback.isNotEmpty) {
          list = listFallback;
        }
      }
      final byDay = <String, List<_PlanItem>>{};
      for (final raw in list) {
        final map = Map<String, dynamic>.from(raw);
        final dayLabel = (map['day'] ?? 'Day 1').toString();
        byDay.putIfAbsent(dayLabel, () => []);
        byDay[dayLabel]!.add(
          _PlanItem(
            id: (map['id'] is int)
                ? map['id'] as int
                : int.tryParse('${map['id']}'),
            name: (map['exercise_name'] ?? '').toString(),
            description: (map['description'] ?? '').toString(),
            difficulty: (map['difficulty_level'] ?? '').toString(),
            category: (map['exercise_category'] ?? '').toString(),
            durationMinutes: _safeInt(map['duration_minutes']),
            repetitions: (map['repetitions'] ?? '').toString(),
            finished: (map['finished'] is bool)
                ? (map['finished'] as bool)
                : null,
          ),
        );
      }
      List<_PlanDay> days = byDay.entries.map((e) {
        final label = e.key;
        final items = e.value;
        final finished =
            items.isNotEmpty && items.every((it) => it.finished == true);
        return _PlanDay(
          label: label,
          index: _dayIndexFromLabel(label),
          items: items,
          finished: finished,
        );
      }).toList()..sort((a, b) => a.index.compareTo(b.index));

      // Fallback: No plan found in Supabase → build a simple week plan from Mongo exercises
      if (days.isEmpty) {
        try {
          final fallback = await _buildFallbackPlanFromMongo();
          days = fallback;
        } catch (_) {
          // keep empty; error message below will handle
        }
      }

      // Determine current day from Supabase: the first unfinished day (start at Day 1),
      // only advance when a day is completed.
      int derivedIdx;
      final unfinished = days.where((d) => !d.finished).toList()
        ..sort((a, b) => a.index.compareTo(b.index));
      if (unfinished.isNotEmpty) {
        derivedIdx = unfinished.first.index;
      } else {
        derivedIdx = days.isNotEmpty ? days.first.index : 1;
      }

      if (!mounted) return;
      setState(() {
        _planDays = days;
        _currentDayIndex = derivedIdx;
      });
    } catch (e) {
      setState(() => _planError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingPlan = false);
    }
  }

  // Build 7-day fallback plan from MongoDB `exercises` collection
  Future<List<_PlanDay>> _buildFallbackPlanFromMongo() async {
    // Try to fetch a reasonable number of exercises and split across 7 days
    final ex = await MongoService.filterExercises(limit: 70);
    if (ex.isEmpty) return const [];
    final items = ex
        .map(
          (m) => _PlanItem(
            name: (m['name'] ?? 'Exercise').toString(),
            description: (m['type'] ?? '').toString(),
            difficulty: (m['level'] ?? '').toString(),
            category: (m['force'] ?? '').toString(),
            durationMinutes: null,
            repetitions: null,
          ),
        )
        .toList();

    const daysCount = 7;
    const perDay = 10; // show up to 10 per day
    final out = <_PlanDay>[];
    for (int d = 0; d < daysCount; d++) {
      final start = d * perDay;
      final end = (start + perDay).clamp(0, items.length);
      if (start >= items.length) break;
      final dayItems = items.sublist(start, end);
      out.add(
        _PlanDay(
          label: 'Day ${d + 1}',
          index: d + 1,
          items: dayItems,
          finished: false,
        ),
      );
    }
    return out;
  }

  // Safely coerce dynamic values to int?
  int? _safeInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) {
      // Extract first integer in the string (e.g., "45", "45 min")
      final m = RegExp(r"-?\d+").firstMatch(v);
      if (m != null) {
        return int.tryParse(m.group(0)!);
      }
      return int.tryParse(v);
    }
    return null;
  }

  int _dayIndexFromLabel(String label) {
    final m = RegExp(r'(\d+)').firstMatch(label);
    if (m != null) {
      return int.tryParse(m.group(1) ?? '1') ?? 1;
    }
    final lower = label.toLowerCase();
    const names = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    for (int i = 0; i < names.length; i++) {
      if (lower.contains(names[i])) return i + 1;
    }
    return 999;
  }

  // Get current weekday index (1=Monday, 7=Sunday)
  int _getCurrentWeekdayIndex() {
    final now = DateTime.now();
    return now.weekday; // DateTime.weekday: 1=Monday, 7=Sunday
  }

  // Convert day index to weekday name
  String _getWeekdayName(int index, {bool short = false}) {
    const shortNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const fullNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    if (index < 1 || index > 7) return short ? 'Mon' : 'Monday';
    return short ? shortNames[index - 1] : fullNames[index - 1];
  }

  _PlanDay? _getPlanDayByIndex(int idx) {
    for (final d in _planDays) {
      if (d.index == idx) return d;
    }
    return null;
  }

  Future<void> _completeToday() async {
    if (_planDays.isEmpty) return;
    try {
      await _setFinishedForDay(_currentDayIndex, true);
    } catch (e) {
      // ignore: avoid_print
      print('Failed to set finished on Supabase: $e');
    }
    if (!mounted) return;
    // Reload; _loadWorkoutPlan will move to the next unfinished day.
    await _loadWorkoutPlan();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            FaIcon(FontAwesomeIcons.circleCheck, color: Colors.white),
            SizedBox(width: 12),
            Text('Workout completed! Great job! 🎉'),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _setFinishedForDay(int index, bool value) async {
    final client = Supabase.instance.client;
    final uid = client.auth.currentUser?.id;
    final current =
        _getPlanDayByIndex(index) ??
        _planDays[(_currentDayIndex - 1).clamp(0, _planDays.length - 1)];
    final day = current.label;
    final ids = current.items
        .map((e) => e.id)
        .whereType<int>()
        .toList(growable: false);
    try {
      if (ids.isNotEmpty) {
        try {
          final inList = '(${ids.join(',')})';
          await client
              .from('workout_plan')
              .update({'finished': value})
              .filter('id', 'in', inList);
        } on PostgrestException catch (_) {
          // Fallback: use OR filter when 'in' helper isn't available
          final orExpr = ids.map((id) => 'id.eq.$id').join(',');
          await client
              .from('workout_plan')
              .update({'finished': value})
              .or(orExpr);
        }
      } else if (uid != null) {
        await client
            .from('workout_plan')
            .update({'finished': value})
            .eq('user_id', uid)
            .eq('day', day);
      } else {
        await client
            .from('workout_plan')
            .update({'finished': value})
            .eq('day', day);
      }
    } on PostgrestException catch (e) {
      // If user_id column doesn't exist, update by day only
      if (e.code == '42703' || (e.message).toString().contains('user_id')) {
        await client
            .from('workout_plan')
            .update({'finished': value})
            .eq('day', day);
      } else {
        // Surface error for easier diagnosis
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update finished: ${e.message}')),
          );
        }
        rethrow;
      }
    }
  }

  Widget _buildTodaysWorkout() {
    if (_loadingPlan) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Today's Workout", style: AppTextStyles.subtitle),
          const SizedBox(height: 16),
          const Center(child: CircularProgressIndicator()),
        ],
      );
    }
    if (_planError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Today's Workout", style: AppTextStyles.subtitle),
          const SizedBox(height: 16),
          _errorCard(_planError!),
        ],
      );
    }
    if (_planDays.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Today's Workout", style: AppTextStyles.subtitle),
          const SizedBox(height: 8),
          Text(
            'No workout plan found. Generate a plan from the Home tab to see exercises here.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      );
    }
    // Today's workout uses sequential day flow; show the plan's day label
    final day = _getPlanDayByIndex(_currentDayIndex);
    final dayLabel = day?.label ?? 'Day $_currentDayIndex';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Today's Workout", style: AppTextStyles.subtitle),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                dayLabel,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () async {
            final updated = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => TodayWorkoutDetailPage(dayLabel: dayLabel),
              ),
            );
            if (updated == true) {
              // Refresh plan to reflect updates from detail page
              await _loadWorkoutPlan();
            }
          },
          child: Container(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (day != null && day.items.isNotEmpty)
                  ...day.items.map(
                    (it) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildExerciseItem(
                        name: it.name,
                        sets:
                            (it.repetitions != null &&
                                it.repetitions!.isNotEmpty)
                            ? '${it.repetitions}'
                            : '',
                        completed: it.finished == true,
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No exercises scheduled for $dayLabel',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _completeToday,
                        child: Text(
                          'Mark Today Complete',
                          style: AppTextStyles.button,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseItem({
    required String name,
    required String sets,
    required bool completed,
  }) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: completed
                ? AppColors.success
                : Theme.of(context).dividerColor,
            shape: BoxShape.circle,
          ),
          child: completed
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6.0,
                    vertical: 5.0,
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.check,
                    color: Colors.white,
                    size: 14,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              decoration: completed ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
        Text(
          sets,
          style: AppTextStyles.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyProgress() {
    // Display only days that exist in the plan, and color by finished status.
    final days = [..._planDays]..sort((a, b) => a.index.compareTo(b.index));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Weekly Progress', style: AppTextStyles.subtitle),
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
                    'Workout Days',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  for (int idx = 0; idx < days.length; idx++) ...[
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (days[idx].index == _currentDayIndex) {
                            _completeToday();
                          }
                        },
                        child: _buildDayCard(
                          days[idx].label,
                          days[idx].finished,
                        ),
                      ),
                    ),
                    if (idx != days.length - 1) const SizedBox(width: 8),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDayCard(String day, bool completed, {bool isToday = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: completed
            ? AppColors.success.withValues(alpha: 0.1)
            : isToday
            ? AppColors.accent.withValues(alpha: 0.1)
            : Theme.of(context).dividerColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: isToday ? Border.all(color: AppColors.accent, width: 2) : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            day,
            style: AppTextStyles.bodySmall.copyWith(
              color: completed
                  ? AppColors.success
                  : isToday
                  ? AppColors.accent
                  : AppColors.textLight,
              fontWeight: isToday || completed
                  ? FontWeight.w600
                  : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _errorCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Text(
        message,
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
      ),
    );
  }

  Widget _buildExerciseCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Exercise Categories', style: AppTextStyles.subtitle),
        const SizedBox(height: 12),
        _ExpandableExerciseCategory(title: 'Cardio', type: 'Cardio'),
        const SizedBox(height: 12),
        _ExpandableExerciseCategory(title: 'Strength', type: 'Strength'),
        const SizedBox(height: 12),
        _ExpandableExerciseCategory(title: 'Yoga', type: 'Yoga'),
        const SizedBox(height: 12),
        _ExpandableExerciseCategory(title: 'Sports', type: 'Sports'),
      ],
    );
  }

  Widget _buildCategoryCard({
    required IconData icon,
    required String title,
    required Color color,
    required String exercises,
  }) {
    return Container(
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
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 25),
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
            '$exercises exercises',
            style: AppTextStyles.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// (obsolete) _ExerciseCategorySection removed; use _ExpandableExerciseCategory instead.

class _PlanDay {
  final String label;
  final int index; // 1-based
  final List<_PlanItem> items;
  final bool finished;
  const _PlanDay({
    required this.label,
    required this.index,
    required this.items,
    required this.finished,
  });
}

class _PlanItem {
  final int? id;
  final String name;
  final String? description;
  final String? difficulty;
  final String? category;
  final int? durationMinutes;
  final String? repetitions;
  final bool? finished;
  const _PlanItem({
    this.id,
    required this.name,
    this.description,
    this.difficulty,
    this.category,
    this.durationMinutes,
    this.repetitions,
    this.finished,
  });
}

class _ExpandableExerciseCategory extends StatefulWidget {
  final String title;
  final String type;
  const _ExpandableExerciseCategory({required this.title, required this.type});

  @override
  State<_ExpandableExerciseCategory> createState() =>
      _ExpandableExerciseCategoryState();
}

class _ExpandableExerciseCategoryState
    extends State<_ExpandableExerciseCategory> {
  bool _expanded = false;
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _items = const [];

  Future<void> _toggle() async {
    setState(() => _expanded = !_expanded);
    if (_expanded && _items.isEmpty && !_loading) {
      setState(() => _loading = true);
      try {
        final data = await MongoService.filterExercisesByExerciseType(
          widget.type,
          limit: 500,
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
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.accent.withValues(alpha: 0.6)),
              foregroundColor: AppColors.accent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: _toggle,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                FaIcon(
                  _expanded
                      ? FontAwesomeIcons.chevronUp
                      : FontAwesomeIcons.chevronDown,
                  color: AppColors.accent,
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Text(
                    'Failed to load ${widget.title}: $_error',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _items.length,
                    separatorBuilder: (context, i) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final ex = _items[idx];
                      final name = (ex['name'] ?? 'Exercise').toString();
                      final type = (ex['type'] ?? ex['exercise_type'] ?? '')
                          .toString();
                      final level = (ex['level'] ?? '').toString();
                      final force = (ex['force'] ?? '').toString();
                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ExerciseDetailPage(exercise: ex),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Theme.of(context).brightness == Brightness.dark
                                ? Border.all(
                                    color: Theme.of(context).dividerColor,
                                  )
                                : null,
                            boxShadow:
                                Theme.of(context).brightness == Brightness.dark
                                ? []
                                : [
                                    BoxShadow(
                                      color: AppColors.divider.withValues(
                                        alpha: 0.2,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: AppTextStyles.bodyLarge.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: [
                                        if (type.isNotEmpty)
                                          _chip(type, AppColors.accent),
                                        if (level.isNotEmpty)
                                          _chip(level, AppColors.success),
                                        if (force.isNotEmpty)
                                          _chip(force, AppColors.warning),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const FaIcon(
                                FontAwesomeIcons.chevronRight,
                                color: AppColors.textLight,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
      ],
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: AppTextStyles.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
