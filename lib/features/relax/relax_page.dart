import 'package:flutter/material.dart';
import 'dart:async';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:final_project/utils/app_colors.dart';
import 'package:final_project/utils/text_styles.dart';
import 'package:final_project/services/health_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
class RelaxPage extends StatefulWidget {
  const RelaxPage({super.key});

  @override
  State<RelaxPage> createState() => _RelaxPageState();
}

class _RelaxPageState extends State<RelaxPage> {
  double? _avgHeartRate;
  String _stressLabel = '—';
  String _meditationSuggestion = '10 min';

  bool _loadingPlan = true;
  String? _planError;
  List<_RelaxDay> _days = const [];
  int _selectedDayIndex = 1;
  String _selectedMood = 'calm';
  double _sleepHours = 7.5;
  String _sleepQuality = 'good';

  @override
  void initState() {
    super.initState();
    _loadWellnessSignals();
    _loadRelaxPlan();
  }

  Future<void> _loadRelaxPlan() async {
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
              .from('relax_plan')
              .select('id, title, description, relaxation_type, day, user_id')
              .eq('user_id', uid)
              .order('id', ascending: true);
        }
        rows ??= await client
            .from('relax_plan')
            .select('id, title, description, relaxation_type, day, user_id')
            .order('id', ascending: true);
      } on PostgrestException catch (e) {
        throw Exception(e.message);
      }

      final list = (rows is List)
          ? rows.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList()
          : <Map<String, dynamic>>[];

      final byDay = <String, List<_RelaxItem>>{};
      for (final m in list) {
        final day = (m['day'] ?? 'Day 1').toString();
        byDay.putIfAbsent(day, () => []);
        byDay[day]!.add(_RelaxItem(
          id: m['id'],
          title: (m['title'] ?? 'Relax').toString(),
          description: (m['description'] ?? '').toString(),
          type: (m['relaxation_type'] ?? '').toString(),
        ));
      }

      final days = byDay.entries
          .map((e) => _RelaxDay(
                dayLabel: e.key,
                dayIndex: _dayIndexFromLabel(e.key),
                items: e.value,
              ))
          .toList()
        ..sort((a, b) => a.dayIndex.compareTo(b.dayIndex));

      if (!mounted) return;
      setState(() {
        _days = days;
        _selectedDayIndex = days.isNotEmpty ? days.first.dayIndex : 1;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _planError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingPlan = false);
    }
  }

  int _dayIndexFromLabel(String label) {
    final m = RegExp(r'(\d+)').firstMatch(label);
    if (m != null) return int.tryParse(m.group(1) ?? '1') ?? 1;
    return 1;
  }

  Future<void> _loadWellnessSignals() async {
    try {
      final hr = await HealthService().fetchTodayAverageHeartRate();
      if (!mounted) return;
      setState(() {
        _avgHeartRate = hr ?? 0;
        _stressLabel = _getStressLabel(_avgHeartRate ?? 0);
        _meditationSuggestion = _suggestMeditationDuration(_avgHeartRate ?? 0);
      });
    } catch (_) {}
  }

  String _getStressLabel(double hr) {
    if (hr < 60) return 'Low';
    if (hr < 75) return 'Normal';
    if (hr < 90) return 'Elevated';
    return 'High';
  }

  String _suggestMeditationDuration(double hr) {
    if (hr < 60) return '5 min';
    if (hr < 80) return '10 min';
    return '15 min';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            _loadWellnessSignals(),
            _loadRelaxPlan(),
          ]);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(isDark),
              const SizedBox(height: 24),

              // Wellness Stats
              _buildWellnessStats(isDark),
              const SizedBox(height: 24),

              // Quick Actions
              _buildQuickActions(isDark),
              const SizedBox(height: 24),

              // Mood Tracker
              _buildMoodTracker(isDark),
              const SizedBox(height: 24),

              // Relax Sessions
              _buildRelaxSessions(isDark),
              const SizedBox(height: 24),

              // Breathing Exercise
              _buildBreathingExercise(isDark),
              const SizedBox(height: 24),

              // Sleep Tracker
              _buildSleepTracker(isDark),
              const SizedBox(height: 24),

              // Wellness Tips
              _buildWellnessTips(isDark),
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
              'Relaxation & Wellness',
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Find peace & manage stress',
              style: AppTextStyles.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
          child: const Icon(
            FontAwesomeIcons.spa,
            color: AppColors.primary,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildWellnessStats(bool isDark) {
    return Row(
      children: [
        _buildStatCard(
          icon: FontAwesomeIcons.heart,
          label: 'Heart Rate',
          value: '${_avgHeartRate?.toStringAsFixed(0) ?? '—'} bpm',
          color: AppColors.error,
          isDark: isDark,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          icon: FontAwesomeIcons.gaugeHigh,
          label: 'Stress Level',
          value: _stressLabel,
          color: AppColors.warning,
          isDark: isDark,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          icon: FontAwesomeIcons.clock,
          label: 'Recommended',
          value: _meditationSuggestion,
          color: AppColors.primary,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Theme.of(context).dividerColor : const Color(0xFFE2E8F0),
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
                  child: Icon(icon, color: color, size: 14),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(bool isDark) {
    return Row(
      children: [
        _buildActionButton(
          icon: FontAwesomeIcons.music,
          label: 'Meditate',
          onTap: () => _openBreathingDialog(pattern: const _BreathPattern.box()),
          color: AppColors.primary,
          isDark: isDark,
        ),
        const SizedBox(width: 12),
        _buildActionButton(
          icon: FontAwesomeIcons.wind,
          label: 'Breathe',
          onTap: () => _openBreathingDialog(pattern: const _BreathPattern.fourSevenEight()),
          color: AppColors.success,
          isDark: isDark,
        ),
        const SizedBox(width: 12),
        _buildActionButton(
          icon: FontAwesomeIcons.water,
          label: 'Hydrate',
          onTap: () {},
          color: AppColors.accent,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoodTracker(bool isDark) {
    const moods = ['😊 Happy', '😌 Calm', '😔 Sad', '😤 Angry', '😴 Tired'];
    const moodColors = [
      AppColors.success,
      AppColors.primary,
      AppColors.accent,
      AppColors.warning,
      AppColors.error,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                FontAwesomeIcons.smile,
                color: AppColors.warning,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'How are you feeling?',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(moods.length, (index) {
            return GestureDetector(
              onTap: () => setState(() => _selectedMood = moods[index]),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedMood == moods[index]
                      ? moodColors[index].withValues(alpha: 0.2)
                      : (isDark ? const Color(0xFF2C2C2E) : Colors.white),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _selectedMood == moods[index]
                        ? moodColors[index]
                        : (isDark ? Theme.of(context).dividerColor : const Color(0xFFE2E8F0)),
                    width: _selectedMood == moods[index] ? 2 : 1,
                  ),
                ),
                child: Text(
                  moods[index],
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildRelaxSessions(bool isDark) {
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
            const Icon(FontAwesomeIcons.exclamation, color: AppColors.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _planError ?? 'Error loading relax plan',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
              ),
            ),
          ],
        ),
      );
    }

    if (_days.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Theme.of(context).dividerColor : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          children: [
            Icon(
              FontAwesomeIcons.spa,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No Sessions Available',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                FontAwesomeIcons.music,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Relax Sessions',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(_days.length, (i) {
              final day = _days[i];
              final isSelected = _selectedDayIndex == day.dayIndex;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedDayIndex = day.dayIndex),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : (isDark ? const Color(0xFF2C2C2E) : Colors.white),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : (isDark ? Theme.of(context).dividerColor : const Color(0xFFE2E8F0)),
                      ),
                    ),
                    child: Text(
                      day.dayLabel,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 12),
        ..._getSelectedDayItems().map((item) => _buildSessionCard(item, isDark)).toList(),
      ],
    );
  }

  List<_RelaxItem> _getSelectedDayItems() {
    for (final day in _days) {
      if (day.dayIndex == _selectedDayIndex) {
        return day.items;
      }
    }
    return [];
  }

  Widget _buildSessionCard(_RelaxItem item, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Theme.of(context).dividerColor : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              FontAwesomeIcons.play,
              color: AppColors.primary,
              size: 14,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
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

  Widget _buildBreathingExercise(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success.withValues(alpha: 0.1),
            AppColors.accent.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Theme.of(context).dividerColor : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  FontAwesomeIcons.wind,
                  color: AppColors.success,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Breathing Exercise',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '4-7-8 technique for relaxation',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _openBreathingDialog(pattern: const _BreathPattern.fourSevenEight()),
                icon: const Icon(FontAwesomeIcons.play, size: 14),
                label: const Text('Start'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openBreathingDialog({required _BreathPattern pattern}) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _BreathingSessionDialog(pattern: pattern),
    );
  }

  Widget _buildSleepTracker(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                FontAwesomeIcons.moon,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Sleep Quality',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Theme.of(context).dividerColor : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Last night',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_sleepHours.toStringAsFixed(1)} hours',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Quality: $_sleepQuality',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Icon(
                FontAwesomeIcons.bedPulse,
                size: 48,
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWellnessTips(bool isDark) {
    const tips = [
      'Take short breaks every hour to stretch',
      'Stay hydrated throughout the day',
      'Practice gratitude meditation daily',
      'Limit screen time before bedtime',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                FontAwesomeIcons.lightbulb,
                color: AppColors.warning,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Wellness Tips',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...tips.map((tip) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? Theme.of(context).dividerColor : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    FontAwesomeIcons.check,
                    color: AppColors.warning,
                    size: 12,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    tip,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )).toList(),
      ],
    );
  }
}

class _RelaxDay {
  final String dayLabel;
  final int dayIndex;
  final List<_RelaxItem> items;

  _RelaxDay({
    required this.dayLabel,
    required this.dayIndex,
    required this.items,
  });
}

class _RelaxItem {
  final int? id;
  final String title;
  final String description;
  final String type;

  _RelaxItem({
    this.id,
    required this.title,
    required this.description,
    required this.type,
  });
}

class _BreathPattern {
  final int inhale;
  final int hold;
  final int exhale;
  final String name;
  const _BreathPattern({required this.inhale, required this.hold, required this.exhale, required this.name});
  const _BreathPattern.fourSevenEight() : inhale = 4, hold = 7, exhale = 8, name = '4-7-8';
  const _BreathPattern.box() : inhale = 4, hold = 4, exhale = 4, name = 'Box';
}

class _BreathingSessionDialog extends StatefulWidget {
  final _BreathPattern pattern;
  final int minutes;
  const _BreathingSessionDialog({required this.pattern, this.minutes = 1});

  @override
  State<_BreathingSessionDialog> createState() => _BreathingSessionDialogState();
}

class _BreathingSessionDialogState extends State<_BreathingSessionDialog> {
  Timer? _timer;
  int _step = 0; // 0=inhale,1=hold,2=exhale
  int _secondsLeft = 0;
  int _sessionSecondsLeft = 0;
  bool _running = false;

  int get _currentStepDuration => [widget.pattern.inhale, widget.pattern.hold, widget.pattern.exhale][_step];

  @override
  void initState() {
    super.initState();
    _sessionSecondsLeft = widget.minutes * 60;
    _startStep();
  }

  void _startStep() {
    _timer?.cancel();
    _running = true;
    _secondsLeft = _currentStepDuration;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _secondsLeft--;
        _sessionSecondsLeft--;
        if (_sessionSecondsLeft <= 0) {
          _running = false;
          _timer?.cancel();
        } else if (_secondsLeft <= 0) {
          _step = (_step + 1) % 3;
          _secondsLeft = _currentStepDuration;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _stepLabel => _step == 0 ? 'Inhale' : (_step == 1 ? 'Hold' : 'Exhale');

  double get _progress {
    final total = _currentStepDuration.toDouble();
    final done = (total - _secondsLeft).clamp(0, total);
    if (total <= 0) return 0;
    return done / total;
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      insetPadding: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(FontAwesomeIcons.wind, color: AppColors.success, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Guided Breathing • ${widget.pattern.name}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: onSurface,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(FontAwesomeIcons.xmark, size: 16),
                  onPressed: () => Navigator.of(context).pop(),
                )
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _stepLabel,
              style: AppTextStyles.titleMedium.copyWith(
                color: onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_secondsLeft}s',
              style: AppTextStyles.titleLarge.copyWith(
                color: onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              width: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 120,
                    width: 120,
                    child: CircularProgressIndicator(
                      value: _running ? _progress : 0,
                      strokeWidth: 8,
                      valueColor: AlwaysStoppedAnimation(AppColors.success),
                      backgroundColor: AppColors.success.withValues(alpha: 0.15),
                    ),
                  ),
                  Icon(
                    _step == 2 ? FontAwesomeIcons.arrowDown : (_step == 0 ? FontAwesomeIcons.arrowUp : FontAwesomeIcons.pause),
                    size: 20,
                    color: AppColors.success,
                  )
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${(_sessionSecondsLeft / 60).floor()}m ${(_sessionSecondsLeft % 60).toString().padLeft(2, '0')}s left',
                  style: AppTextStyles.bodySmall.copyWith(color: onSurface.withOpacity(0.7)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(FontAwesomeIcons.stop),
                    label: const Text('Stop'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (_sessionSecondsLeft <= 0) {
                        Navigator.of(context).pop();
                      } else if (_running) {
                        _timer?.cancel();
                        setState(() => _running = false);
                      } else {
                        _startStep();
                      }
                    },
                    icon: Icon(_running ? FontAwesomeIcons.pause : FontAwesomeIcons.play),
                    label: Text(_running ? 'Pause' : 'Resume'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
