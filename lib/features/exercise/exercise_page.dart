import 'package:flutter/material.dart';
import 'package:final_project/utils/app_colors.dart';
import 'package:final_project/utils/text_styles.dart';
import 'package:final_project/services/health_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ExercisePage extends StatefulWidget {
  const ExercisePage({super.key});

  @override
  State<ExercisePage> createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage> {
  int? _stepsToday;
  int? _steps7dTotal;
  double? _activeEnergyKCal;

  @override
  void initState() {
    super.initState();
    _loadHealthStats();
  }

  Future<void> _loadHealthStats() async {
    try {
      final health = HealthService();
      final todaySteps = await health.fetchTodaySteps();
      final seven = await health.fetchStepsForLastDays(7);
      final energy = await health.fetchTodayActiveEnergyKCal();
      if (!mounted) return;
      setState(() {
        _stepsToday = todaySteps ?? 0;
        _steps7dTotal = seven.fold<int>(0, (a, b) => a + b);
        _activeEnergyKCal = energy ?? 0;
      });
    } catch (_) {
      // Keep defaults when health access fails
    }
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

            // Today's Workout
            _buildTodaysWorkout(),
            const SizedBox(height: 32),

            // Weekly Progress
            _buildWeeklyProgress(),
            const SizedBox(height: 32),

            // Exercise Categories
            _buildExerciseCategories(),
            const SizedBox(height: 32),
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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 17),
                  child: const FaIcon(
                    FontAwesomeIcons.dumbbell,
                    color: AppColors.accent,
                    size: 26,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Steps (7d)',
                  value: _formatInt(_steps7dTotal ?? 0),
                  subtitle: 'Total',
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: 'Active Energy',
                  value: _formatKcal(_activeEnergyKCal ?? 0),
                  subtitle: 'Today',
                  color: AppColors.warning,
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

  Widget _buildTodaysWorkout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Today's Workout", style: AppTextStyles.subtitle),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Full Body Strength',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '45 min',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Complete 3 sets of each exercise with 60s rest between sets.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 20),
              _buildExerciseItem(
                name: 'Push-ups',
                sets: '3 x 15',
                completed: true,
              ),
              const SizedBox(height: 12),
              _buildExerciseItem(
                name: 'Squats',
                sets: '3 x 20',
                completed: true,
              ),
              const SizedBox(height: 12),
              _buildExerciseItem(
                name: 'Plank',
                sets: '3 x 30s',
                completed: false,
              ),
              const SizedBox(height: 12),
              _buildExerciseItem(
                name: 'Lunges',
                sets: '3 x 12',
                completed: false,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    // Start workout
                  },
                  child: Text('Start Workout', style: AppTextStyles.button),
                ),
              ),
            ],
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
              ? const FaIcon(FontAwesomeIcons.check, color: Colors.white, size: 14)
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
                  Text(
                    '4/5 completed',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildDayCard('Mon', true),
                  const SizedBox(width: 8),
                  _buildDayCard('Tue', true),
                  const SizedBox(width: 8),
                  _buildDayCard('Wed', false),
                  const SizedBox(width: 8),
                  _buildDayCard('Thu', true),
                  const SizedBox(width: 8),
                  _buildDayCard('Fri', true),
                  const SizedBox(width: 8),
                  _buildDayCard('Sat', false),
                  const SizedBox(width: 8),
                  _buildDayCard('Sun', false),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDayCard(String day, bool completed) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: completed
              ? AppColors.success.withValues(alpha: 0.1)
              : Theme.of(context).dividerColor.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          day,
          style: AppTextStyles.bodySmall.copyWith(
            color: completed ? AppColors.success : AppColors.textLight,
            fontWeight: completed ? FontWeight.w600 : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildExerciseCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Exercise Categories', style: AppTextStyles.subtitle),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildCategoryCard(
                icon: FontAwesomeIcons.personRunning,
                title: 'Cardio',
                color: AppColors.accent,
                exercises: '12',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildCategoryCard(
                icon: FontAwesomeIcons.dumbbell,
                title: 'Strength',
                color: AppColors.warning,
                exercises: '18',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildCategoryCard(
                icon: FontAwesomeIcons.spa,
                title: 'Yoga',
                color: AppColors.healthPrimary,
                exercises: '8',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildCategoryCard(
                icon: FontAwesomeIcons.football,
                title: 'Sports',
                color: AppColors.success,
                exercises: '15',
              ),
            ),
          ],
        ),
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
