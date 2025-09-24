import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:final_project/utils/app_colors.dart';
import 'package:final_project/utils/text_styles.dart';
import 'package:final_project/services/health_service.dart';

class RelaxPage extends StatefulWidget {
  const RelaxPage({super.key});

  @override
  State<RelaxPage> createState() => _RelaxPageState();
}

class _RelaxPageState extends State<RelaxPage> {
  double? _avgHeartRate;
  String _stressLabel = '—';
  String _meditationSuggestion = '10 min';

  @override
  void initState() {
    super.initState();
    _loadWellnessSignals();
  }

  Future<void> _loadWellnessSignals() async {
    try {
      final health = HealthService();
      final hr = await health.fetchTodayAverageHeartRate();
      if (!mounted) return;
      setState(() {
        _avgHeartRate = hr;
        _stressLabel = _computeStressLabel(hr);
        _meditationSuggestion = _computeMeditationSuggestion(_stressLabel);
      });
    } catch (_) {
      // leave defaults
    }
  }

  String _computeStressLabel(double? hr) {
    if (hr == null) return 'Unknown';
    if (hr < 70) return 'Low';
    if (hr < 90) return 'Moderate';
    return 'High';
  }

  String _computeMeditationSuggestion(String stress) {
    switch (stress) {
      case 'High':
        return '15 min';
      case 'Moderate':
        return '10 min';
      case 'Low':
        return '5 min';
      default:
        return '10 min';
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
            
            // Mood Tracker
            _buildMoodTracker(),
            const SizedBox(height: 32),
            
            // Meditation Sessions
            _buildMeditationSessions(),
            const SizedBox(height: 32),
            
            // Breathing Exercises
            _buildBreathingExercises(),
            const SizedBox(height: 32),
            
            // Sleep Quality
            _buildSleepQuality(),
            const SizedBox(height: 32),
            
            // Wellness Tips
            _buildWellnessTips(),
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
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Relax & Wellness',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.heading2.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'Find Your Inner Peace',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.wellness.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CupertinoIcons.heart,
                  color: AppColors.wellness,
                  size: 30,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildWellnessStatCard(
                  title: 'Stress Level',
                  value: _avgHeartRate == null
                      ? _stressLabel
                      : '$_stressLabel (${_avgHeartRate!.toStringAsFixed(0)} bpm)',
                  color: AppColors.wellness,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildWellnessStatCard(
                  title: 'Meditation',
                  value: _meditationSuggestion,
                  color: AppColors.healthPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWellnessStatCard({
    required String title,
    required String value,
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
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodTracker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How are you feeling today?',
          style: AppTextStyles.subtitle,
        ),
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
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMoodOption(
                    emoji: '😊',
                    label: 'Great',
                    color: AppColors.success,
                    selected: true,
                  ),
                  _buildMoodOption(
                    emoji: '🙂',
                    label: 'Good',
                    color: AppColors.wellness,
                    selected: false,
                  ),
                  _buildMoodOption(
                    emoji: '😐',
                    label: 'Okay',
                    color: AppColors.warning,
                    selected: false,
                  ),
                  _buildMoodOption(
                    emoji: '😔',
                    label: 'Sad',
                    color: AppColors.info,
                    selected: false,
                  ),
                  _buildMoodOption(
                    emoji: '😰',
                    label: 'Anxious',
                    color: AppColors.error,
                    selected: false,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'You\'re feeling great today! Keep up the positive energy.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.success,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMoodOption({
    required String emoji,
    required String label,
    required Color color,
    required bool selected,
  }) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.2) : AppColors.divider.withValues(alpha: 0.3),
            shape: BoxShape.circle,
            border: selected
                ? Border.all(color: color, width: 2)
                : Border.all(color: Colors.transparent, width: 2),
          ),
          child: Center(
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: selected ? color : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildMeditationSessions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meditation Sessions',
          style: AppTextStyles.subtitle,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMeditationCard(
                title: 'Morning Calm',
                duration: '10 min',
                type: 'Breathing',
                color: AppColors.healthPrimary,
                icon: CupertinoIcons.sun_max,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMeditationCard(
                title: 'Stress Relief',
                duration: '15 min',
                type: 'Guided',
                color: AppColors.wellness,
                icon: CupertinoIcons.sparkles,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMeditationCard(
                title: 'Sleep Preparation',
                duration: '20 min',
                type: 'Relaxation',
                color: AppColors.info,
                icon: CupertinoIcons.moon,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMeditationCard(
                title: 'Focus Boost',
                duration: '5 min',
                type: 'Quick',
                color: AppColors.accent,
                icon: CupertinoIcons.scope,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMeditationCard({
    required String title,
    required String duration,
    required String type,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
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
          Row(
            children: [
              Text(
                duration,
                style: AppTextStyles.bodySmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  type,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreathingExercises() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Breathing Exercises',
          style: AppTextStyles.subtitle,
        ),
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
              _buildBreathingExercise(
                title: '4-7-8 Breathing',
                description: 'Inhale 4s, Hold 7s, Exhale 8s',
                duration: '5 min',
                color: AppColors.wellness,
              ),
              const SizedBox(height: 16),
              _buildBreathingExercise(
                title: 'Box Breathing',
                description: '4s inhale, 4s hold, 4s exhale, 4s hold',
                duration: '3 min',
                color: AppColors.healthPrimary,
              ),
              const SizedBox(height: 16),
              _buildBreathingExercise(
                title: 'Deep Breathing',
                description: 'Slow, deep breaths for relaxation',
                duration: '10 min',
                color: AppColors.success,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBreathingExercise({
    required String title,
    required String description,
    required String duration,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.air,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            duration,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepQuality() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sleep Quality',
          style: AppTextStyles.subtitle,
        ),
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
                    'Last Night',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '7.5 hours',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.wellness,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: 0.94,
                backgroundColor: AppColors.divider,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.wellness),
                borderRadius: BorderRadius.circular(8),
                minHeight: 12,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sleep Quality',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    'Good',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.wellness,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.wellness,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    // Start sleep meditation
                  },
                  child: Text(
                    'Start Sleep Meditation',
                    style: AppTextStyles.button,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWellnessTips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Wellness Tips',
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
                icon: Icons.nature,
                title: 'Connect with Nature',
                description: 'Spend time outdoors to reduce stress and improve mood.',
                color: AppColors.success,
              ),
              Divider(height: 1, color: Theme.of(context).dividerColor),
              _buildTipItem(
                icon: Icons.music_note,
                title: 'Listen to Calming Music',
                description: 'Soothing sounds can help reduce anxiety and promote relaxation.',
                color: AppColors.healthPrimary,
              ),
              Divider(height: 1, color: Theme.of(context).dividerColor),
              _buildTipItem(
                icon: Icons.self_improvement,
                title: 'Practice Gratitude',
                description: 'Take time each day to reflect on things you\'re grateful for.',
                color: AppColors.wellness,
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
