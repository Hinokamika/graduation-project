import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:final_project/utils/app_colors.dart';
import 'package:final_project/utils/text_styles.dart';
import 'package:final_project/services/health_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:final_project/services/mongo_service.dart';

class RelaxPage extends StatefulWidget {
  const RelaxPage({super.key});

  @override
  State<RelaxPage> createState() => _RelaxPageState();
}

class _RelaxPageState extends State<RelaxPage> {
  double? _avgHeartRate;
  String _stressLabel = '—';
  String _meditationSuggestion = '10 min';

  // Relax plan (Supabase)
  bool _loadingPlan = true;
  String? _planError;
  List<_RelaxDay> _days = const [];
  int _selectedDayIndex = 1;

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

      // Group by day
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
            _buildRelaxPlanSection(),
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
                child: const FaIcon(
                  FontAwesomeIcons.heart,
                  color: AppColors.wellness,
                  size: 26,
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
        Text('How are you feeling today?', style: AppTextStyles.subtitle),
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
            color: selected
                ? color.withValues(alpha: 0.2)
                : AppColors.divider.withValues(alpha: 0.3),
            shape: BoxShape.circle,
            border: selected
                ? Border.all(color: color, width: 2)
                : Border.all(color: Colors.transparent, width: 2),
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: selected
                ? color
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
        Text('Meditation Sessions', style: AppTextStyles.subtitle),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMeditationCard(
                title: 'Morning Calm',
                duration: '10 min',
                type: 'Breathing',
                color: AppColors.healthPrimary,
                icon: FontAwesomeIcons.sun,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMeditationCard(
                title: 'Stress Relief',
                duration: '15 min',
                type: 'Guided',
                color: AppColors.wellness,
                icon: FontAwesomeIcons.wandMagicSparkles,
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
                icon: FontAwesomeIcons.moon,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMeditationCard(
                title: 'Focus Boost',
                duration: '5 min',
                type: 'Quick',
                color: AppColors.accent,
                icon: FontAwesomeIcons.crosshairs,
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
            child: Icon(icon, color: color, size: 20),
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
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
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
        Text('Breathing Exercises', style: AppTextStyles.subtitle),
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

  // ---- Relax plan (Supabase + Mongo) ----
  Widget _buildRelaxPlanSection() {
    if (_loadingPlan) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Your Relax Plan'),
          SizedBox(height: 12),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }
    if (_planError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Relax Plan', style: AppTextStyles.subtitle),
          const SizedBox(height: 8),
          Text(_planError!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
        ],
      );
    }
    if (_days.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Relax Plan', style: AppTextStyles.subtitle),
          const SizedBox(height: 8),
          Text('No relax plan found. Use Discover to add yoga/breathing items.',
              style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _openRelaxUpdateModal,
            icon: const FaIcon(FontAwesomeIcons.compass, size: 16),
            label: const Text('Discover'),
          )
        ],
      );
    }

    final selected = _days.firstWhere(
      (d) => d.dayIndex == _selectedDayIndex,
      orElse: () => _days.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Your Relax Plan', style: AppTextStyles.subtitle),
            TextButton.icon(
              onPressed: _openRelaxUpdateModal,
              icon: const FaIcon(FontAwesomeIcons.compass, size: 14),
              label: const Text('Discover'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _days
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
              if (selected.items.isEmpty)
                Text('No items for ${selected.dayLabel}.', style: AppTextStyles.bodySmall)
              else
                ...selected.items.map((it) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(it.title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                                if (it.description.isNotEmpty)
                                  Text(it.description, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                                if (it.type.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.wellness.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(it.type, style: AppTextStyles.bodySmall.copyWith(color: AppColors.wellness)),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            icon: const FaIcon(FontAwesomeIcons.trashCan, size: 16),
                            color: AppColors.error,
                            onPressed: () => _deleteRelaxItem(it),
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

  Future<void> _openRelaxUpdateModal() async {
    final result = await showModalBottomSheet<_RelaxUpdateResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _RelaxUpdateModal(dayLabel: _days.isEmpty ? 'Day $_selectedDayIndex' : _days.firstWhere((e) => e.dayIndex == _selectedDayIndex, orElse: () => _days.first).dayLabel),
    );
    if (result == null) return;
    await _saveRelaxItemsForDay(result.items, replace: result.replace);
  }

  Future<void> _saveRelaxItemsForDay(List<Map<String, dynamic>> items, {bool replace = false}) async {
    final client = Supabase.instance.client;
    final uid = client.auth.currentUser?.id;
    try {
      if (replace && uid != null) {
        // Delete user's items for this day
        try {
          await client
              .from('relax_plan')
              .delete()
              .eq('user_id', uid)
              .eq('day', _days.firstWhere((e) => e.dayIndex == _selectedDayIndex, orElse: () => _days.first).dayLabel);
        } catch (_) {}
      }
      if (items.isNotEmpty) {
        final dayLabel = _days.isEmpty
            ? 'Day $_selectedDayIndex'
            : _days.firstWhere((e) => e.dayIndex == _selectedDayIndex, orElse: () => _days.first).dayLabel;
        // Fetch existing user items for dedupe
        final existingUser = uid == null
            ? const []
            : await client
                .from('relax_plan')
                .select('title, relaxation_type')
                .eq('user_id', uid)
                .eq('day', dayLabel);
        final existingKeys = <String>{};
        if (existingUser is List) {
          for (final r in existingUser) {
            final rm = Map<String, dynamic>.from(r as Map);
            final k = '${(rm['title'] ?? '').toString().toLowerCase()}::${(rm['relaxation_type'] ?? '').toString().toLowerCase()}';
            existingKeys.add(k);
          }
        }

        final inserts = items.map((m) {
          final name = (m['name'] ?? 'Relax').toString();
          final instructions = m['instructions'];
          String desc = '';
          if (instructions is List) desc = instructions.map((e) => e.toString()).join('\n');
          if (desc.isEmpty && m['description'] != null) desc = m['description'].toString();
          final type = (m['type'] ?? m['exercise_type'] ?? '').toString();
          return {
            if (uid != null) 'user_id': uid,
            'day': dayLabel,
            'title': name,
            'description': desc,
            'relaxation_type': type,
          };
        }).where((row){
          final key = '${(row['title'] ?? '').toString().toLowerCase()}::${(row['relaxation_type'] ?? '').toString().toLowerCase()}';
          final isNew = !existingKeys.contains(key);
          if (isNew) existingKeys.add(key);
          return isNew;
        }).toList();
        if (inserts.isNotEmpty) {
          await client.from('relax_plan').insert(inserts);
        }
      }
      await _loadRelaxPlan();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Relax plan updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
    }
  }

  Future<void> _deleteRelaxItem(_RelaxItem it) async {
    final client = Supabase.instance.client;
    try {
      if (it.id != null) {
        await client.from('relax_plan').delete().eq('id', it.id);
      } else {
        final uid = client.auth.currentUser?.id;
        final dayLabel = _days.isEmpty
            ? 'Day $_selectedDayIndex'
            : _days.firstWhere((e) => e.dayIndex == _selectedDayIndex, orElse: () => _days.first).dayLabel;
        final q = client.from('relax_plan').delete().eq('day', dayLabel).eq('title', it.title);
        if (uid != null) {
          await q.eq('user_id', uid);
        } else {
          await q;
        }
      }
      await _loadRelaxPlan();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item removed')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
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
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
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
            child: Icon(FontAwesomeIcons.wind, color: color, size: 18),
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
        Text('Sleep Quality', style: AppTextStyles.subtitle),
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
        Text('Wellness Tips', style: AppTextStyles.subtitle),
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
                icon: FontAwesomeIcons.leaf,
                title: 'Connect with Nature',
                description:
                    'Spend time outdoors to reduce stress and improve mood.',
                color: AppColors.success,
              ),
              Divider(height: 1, color: Theme.of(context).dividerColor),
              _buildTipItem(
                icon: FontAwesomeIcons.music,
                title: 'Listen to Calming Music',
                description:
                    'Soothing sounds can help reduce anxiety and promote relaxation.',
                color: AppColors.healthPrimary,
              ),
              Divider(height: 1, color: Theme.of(context).dividerColor),
              _buildTipItem(
                icon: FontAwesomeIcons.spa,
                title: 'Practice Gratitude',
                description:
                    'Take time each day to reflect on things you\'re grateful for.',
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
}

class _RelaxDay {
  final String dayLabel;
  final int dayIndex;
  final List<_RelaxItem> items;
  const _RelaxDay({required this.dayLabel, required this.dayIndex, required this.items});
}

class _RelaxItem {
  final dynamic id;
  final String title;
  final String description;
  final String type;
  const _RelaxItem({required this.id, required this.title, required this.description, required this.type});
}

class _RelaxUpdateResult {
  final List<Map<String, dynamic>> items;
  final bool replace;
  const _RelaxUpdateResult(this.items, {this.replace = false});
}

class _RelaxUpdateModal extends StatefulWidget {
  final String dayLabel;
  const _RelaxUpdateModal({required this.dayLabel});
  @override
  State<_RelaxUpdateModal> createState() => _RelaxUpdateModalState();
}

class _RelaxUpdateModalState extends State<_RelaxUpdateModal> {
  final TextEditingController _search = TextEditingController();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = const [];
  final Set<int> _selected = {};
  bool _replace = false;
  String _type = 'yoga';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await MongoService.filterExercisesByExerciseType(_type, limit: 50);
      if (!mounted) return;
      setState(() => _items = data);
    } catch (e) {
      if (!mounted) return; setState(() => _error = e.toString());
    } finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _applySearch() async {
    setState(() { _loading = true; _error = null; });
    try {
      // Use name contains and type filter
      var data = await MongoService.filterExercisesByExerciseType(_type, limit: 200);
      final q = _search.text.trim().toLowerCase();
      if (q.isNotEmpty) {
        data = data.where((m) => (m['name'] ?? '').toString().toLowerCase().contains(q)).toList();
      }
      if (!mounted) return; setState(() => _items = data);
    } catch (e) { if (!mounted) return; setState(() => _error = e.toString()); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      builder: (_, controller) => Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Text('Discover ${widget.dayLabel}', style: AppTextStyles.subtitle),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
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
                        hintText: 'Search relax items by name...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _type,
                    items: const [
                      DropdownMenuItem(value: 'yoga', child: Text('Yoga')),
                      DropdownMenuItem(value: 'stretch', child: Text('Stretch')),
                      DropdownMenuItem(value: 'meditation', child: Text('Meditation')),
                      DropdownMenuItem(value: 'breath', child: Text('Breathing')),
                    ],
                    onChanged: (v) { setState(() => _type = v ?? 'yoga'); _load(); },
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
                            final name = (m['name'] ?? 'Relax').toString();
                            final type = (m['type'] ?? m['exercise_type'] ?? '').toString();
                            final selected = _selected.contains(i);
                            return CheckboxListTile(
                              value: selected,
                              onChanged: (v) => setState(() { if (v == true) _selected.add(i); else _selected.remove(i); }),
                              title: Text(name),
                              subtitle: type.isEmpty ? null : Text(type),
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
                        Switch(value: _replace, onChanged: (v) => setState(() => _replace = v)),
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
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _selected.isEmpty
                              ? null
                              : () {
                                  final items = _selected.map((i) => _items[i]).toList(growable: false);
                                  Navigator.pop(context, _RelaxUpdateResult(items, replace: _replace));
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
      ),
    );
  }
}
