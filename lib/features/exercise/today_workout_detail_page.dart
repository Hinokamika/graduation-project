import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:final_project/utils/app_colors.dart';
import 'package:final_project/utils/text_styles.dart';
import 'package:final_project/services/mongo_service.dart';
import 'package:final_project/services/dto/plan_dto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:final_project/features/exercise/exercise_detail_page.dart';

class TodayWorkoutDetailPage extends StatefulWidget {
  final String dayLabel;
  const TodayWorkoutDetailPage({super.key, required this.dayLabel});

  @override
  State<TodayWorkoutDetailPage> createState() => _TodayWorkoutDetailPageState();
}

class _TodayWorkoutDetailPageState extends State<TodayWorkoutDetailPage> {
  bool _loading = true;
  String? _error;
  List<_WorkoutRow> _rows = const [];
  bool _updated = false;

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
      final client = Supabase.instance.client;
      final uid = client.auth.currentUser?.id;
      // Always fetch both user-scoped and legacy (user_id null) rows for this day
      List<Map<String, dynamic>> list = [];
      try {
        final byDay = await client
            .from('workout_plan')
            .select(
              'id,exercise_name,description,difficulty_level,exercise_category,duration_minutes,repetitions,day,created_at,finished,user_id',
            )
            .eq('day', widget.dayLabel)
            .order('created_at', ascending: true);
        list = byDay
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
            .toList();
      } on PostgrestException catch (e) {
        // Fallback when user_id column not present
        final byDay = await client
            .from('workout_plan')
            .select(
              'id,exercise_name,description,difficulty_level,exercise_category,duration_minutes,repetitions,day,created_at,finished',
            )
            .eq('day', widget.dayLabel)
            .order('created_at', ascending: true);
        list = byDay
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      final mapped = list
          .map(
            (m) => _WorkoutRow(
              id: (m['id'] is int)
                  ? m['id'] as int
                  : int.tryParse('${m['id']}'),
              name: (m['exercise_name'] ?? '').toString(),
              description: (m['description'] ?? '').toString(),
              difficulty: (m['difficulty_level'] ?? '').toString(),
              category: (m['exercise_category'] ?? '').toString(),
              durationMinutes: _safeInt(m['duration_minutes']),
              repetitions: (m['repetitions'] ?? '').toString(),
              finished: (m['finished'] is bool) ? m['finished'] as bool : null,
              userId: (m['user_id'])?.toString(),
            ),
          )
          .toList();
      if (!mounted) return;
      setState(() {
        _rows = mapped;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int? _safeInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  Future<void> _openUpdateModal() async {
    final result = await showModalBottomSheet<_UpdateResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _UpdateWorkoutModal(dayLabel: widget.dayLabel),
    );
    if (result == null) return;
    await _replaceDayPlan(result.selectedExercises, replace: result.replace);
  }

  Future<void> _openExerciseDetailByName(String name) async {
    try {
      final results = await MongoService.filterExercises(name: name, limit: 1);
      if (!mounted) return;
      if (results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exercise not found')),
        );
        return;
      }
      final ex = results.first;
      // ignore: use_build_context_synchronously
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ExerciseDetailPage(exercise: ex)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to open details: $e')));
    }
  }

  Future<void> _replaceDayPlan(
    List<Map<String, dynamic>> selected, {
    bool replace = false,
  }) async {
    final client = Supabase.instance.client;
    final uid = client.auth.currentUser?.id;

    // Build inserts (replace instructions with AI transcript when possible)
    final inserts = await Future.wait(
      selected.map((ex) async {
        final name = (ex['name'] ?? 'Exercise').toString();
        String? desc;
        if (desc == null || desc.trim().isEmpty) {
          final instructions = ex['instructions'];
          if (instructions is List) {
            desc = instructions.map((e) => e.toString()).join('\n');
          } else if (instructions != null) {
            desc = instructions.toString();
          }
        }
        final level = (ex['level'] ?? '').toString();
        final type = (ex['type'] ?? ex['exercise_type'] ?? '').toString();
        final dto = WorkoutPlanInsertDTO(
          exerciseName: name,
          description: desc,
          difficultyLevel: level.isEmpty ? null : level,
          exerciseCategory: type.isEmpty ? null : type,
          durationMinutes: null,
          repetitions: '3x10',
          userId: uid ?? '',
          day: widget.dayLabel,
        );
        return dto.toMap();
      }),
    );

    try {
      if (replace) {
        // First, try to delete existing user rows for this day by their IDs (leave legacy rows)
        final existingIds = _rows
            .where(
              (r) => (uid != null && uid.isNotEmpty) ? r.userId == uid : true,
            )
            .map((r) => r.id)
            .whereType<int>()
            .toList();
        if (existingIds.isNotEmpty) {
          try {
            final inList = '(${existingIds.join(',')})';
            await client
                .from('workout_plan')
                .delete()
                .filter('id', 'in', inList);
          } on PostgrestException catch (_) {
            final orExpr = existingIds.map((id) => 'id.eq.$id').join(',');
            await client.from('workout_plan').delete().or(orExpr);
          }
        } else if (uid != null && uid.isNotEmpty) {
          // Fallback: delete by user + day only (do not touch legacy rows)
          try {
            await client
                .from('workout_plan')
                .delete()
                .eq('user_id', uid)
                .eq('day', widget.dayLabel);
          } on PostgrestException catch (e) {
            if (e.code == '42703' ||
                (e.message).toString().contains('user_id')) {
              // If user_id not present, skip fallback to avoid removing legacy rows.
            } else {
              rethrow;
            }
          }
        }
      }

      if (inserts.isNotEmpty) {
        try {
          await client.from('workout_plan').insert(inserts);
        } on PostgrestException catch (e) {
          // If user_id column doesn't exist, strip it and retry
          if (e.code == '42703' || (e.message).toString().contains('user_id')) {
            final withoutUser = inserts
                .map((m) => Map<String, dynamic>.from(m)..remove('user_id'))
                .toList();
            await client.from('workout_plan').insert(withoutUser);
          } else {
            rethrow;
          }
        }
      }

      // Keep legacy rows (user_id null) as requested; no cleanup here.

      if (!mounted) return;
      _updated = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Updated today's workout from MongoDB")),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
    }
  }

  Future<void> _deleteWorkoutRow(_WorkoutRow row) async {
    final client = Supabase.instance.client;
    try {
      if (row.id != null) {
        try {
          await client.from('workout_plan').delete().eq('id', row.id!);
        } on PostgrestException {
          await client.from('workout_plan').delete().or('id.eq.${row.id}');
        }
      } else {
        // Fallback: match by day + exercise_name
        await client
            .from('workout_plan')
            .delete()
            .eq('day', widget.dayLabel)
            .eq('exercise_name', row.name);
      }
      if (!mounted) return;
      _updated = true;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Exercise deleted')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_updated);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 18),
            onPressed: () => Navigator.of(context).pop(_updated),
            tooltip: 'Back',
          ),
          title: Text("Today's Workout • ${widget.dayLabel}"),
          actions: [
            IconButton(
              tooltip: 'Update from MongoDB',
              icon: const FaIcon(FontAwesomeIcons.penToSquare),
              onPressed: _openUpdateModal,
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _error!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.getErrorColor(context),
                  ),
                ),
              )
            : (_rows.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const FaIcon(
                              FontAwesomeIcons.circleInfo,
                              size: 28,
                              color: AppColors.textLight,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No exercises found for this day.',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.8),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _rows.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) {
                        final r = _rows[i];
                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _openExerciseDetailByName(r.name),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Border.all(
                                      color: Theme.of(context).dividerColor,
                                    )
                                  : null,
                              boxShadow:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: AppColors.divider.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: (r.finished ?? false)
                                            ? AppColors.success
                                            : Theme.of(context).dividerColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: (r.finished ?? false)
                                          ? Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 5.0,
                                                    horizontal: 5.0,
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
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  r.name,
                                                  style: AppTextStyles.bodyLarge
                                                      .copyWith(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          if (r.description != null &&
                                              r.description!.isNotEmpty)
                                            Text(
                                              r.description!,
                                              style: AppTextStyles.bodySmall
                                                  .copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurface
                                                        .withOpacity(0.8),
                                                  ),
                                            ),
                                          const SizedBox(height: 6),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 6,
                                            children: [
                                              if ((r.category ?? '').isNotEmpty)
                                                _chip(
                                                  r.category!,
                                                  AppColors.accent,
                                                ),
                                              if ((r.difficulty ?? '')
                                                  .isNotEmpty)
                                                _chip(
                                                  r.difficulty!,
                                                  AppColors.success,
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      tooltip: 'Delete exercise',
                                      icon: const FaIcon(
                                        FontAwesomeIcons.trashCan,
                                        size: 18,
                                      ),
                                      color: AppColors.error,
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text(
                                              'Delete exercise?',
                                            ),
                                            content: Text(
                                              'Remove "${r.name}" from ${widget.dayLabel}?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(
                                                  ctx,
                                                ).pop(false),
                                                child: const Text('Cancel'),
                                              ),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      AppColors.error,
                                                  foregroundColor: Colors.white,
                                                ),
                                                onPressed: () =>
                                                    Navigator.of(ctx).pop(true),
                                                child: const Text('Delete'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          await _deleteWorkoutRow(r);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )),
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: AppTextStyles.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _WorkoutRow {
  final int? id;
  final String name;
  final String? description;
  final String? difficulty;
  final String? category;
  final int? durationMinutes;
  final String? repetitions;
  final bool? finished;
  final String? userId;
  const _WorkoutRow({
    required this.id,
    required this.name,
    this.description,
    this.difficulty,
    this.category,
    this.durationMinutes,
    this.repetitions,
    this.finished,
    this.userId,
  });
}

class _UpdateResult {
  final List<Map<String, dynamic>> selectedExercises;
  final bool replace;
  const _UpdateResult(this.selectedExercises, {this.replace = false});
}

class _UpdateWorkoutModal extends StatefulWidget {
  final String dayLabel;
  const _UpdateWorkoutModal({required this.dayLabel});

  @override
  State<_UpdateWorkoutModal> createState() => _UpdateWorkoutModalState();
}

class _UpdateWorkoutModalState extends State<_UpdateWorkoutModal> {
  final TextEditingController _search = TextEditingController();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = const [];
  final Set<int> _selectedIdx = {};
  bool _replace = false;
  // Quick filters
  List<String> _types = const [];
  List<String> _levels = const [];
  String? _selectedType;
  String? _selectedLevel;

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
      final data = await MongoService.filterExercises(limit: 100);
      if (!mounted) return;
      _seedFacetOptions(data);
      setState(() => _items = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _applySearch(String v) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await MongoService.filterExercises(
        name: v,
        type: _selectedType,
        level: _selectedLevel,
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

  void _seedFacetOptions(List<Map<String, dynamic>> data) {
    final typeSet = <String>{};
    final levelSet = <String>{};
    for (final ex in data) {
      final t = (ex['type'] ?? ex['exercise_type'] ?? '').toString().trim();
      if (t.isNotEmpty) typeSet.add(t);
      final l = (ex['level'] ?? '').toString().trim();
      if (l.isNotEmpty) levelSet.add(l);
    }
    _types = typeSet.toList()..sort();
    _levels = levelSet.toList()..sort();
  }

  Future<void> _applyFilters() async {
    await _applySearch(_search.text);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, controller) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Text(
                      'Update ${widget.dayLabel}',
                      style: AppTextStyles.subtitle,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: FaIcon(FontAwesomeIcons.x, size: 22),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  onSubmitted: _applySearch,
                  decoration: InputDecoration(
                    hintText: 'Search exercises by name...',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              // Quick filters
              if (_types.isNotEmpty || _levels.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_types.isNotEmpty) ...[
                        Text(
                          'Type',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ..._types.map(
                              (t) => FilterChip(
                                label: Text(t),
                                selected: _selectedType == t,
                                onSelected: (sel) async {
                                  setState(
                                    () => _selectedType = sel ? t : null,
                                  );
                                  await _applyFilters();
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (_levels.isNotEmpty) ...[
                        Text(
                          'Level',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ..._levels.map(
                              (l) => FilterChip(
                                label: Text(l),
                                selected: _selectedLevel == l,
                                onSelected: (sel) async {
                                  setState(
                                    () => _selectedLevel = sel ? l : null,
                                  );
                                  await _applyFilters();
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (_selectedType != null || _selectedLevel != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () async {
                              setState(() {
                                _selectedType = null;
                                _selectedLevel = null;
                              });
                              await _applyFilters();
                            },
                            label: const Text('Clear filters'),
                          ),
                        ),
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
                          final ex = _items[i];
                          final name = (ex['name'] ?? 'Exercise').toString();
                          final type = (ex['type'] ?? ex['exercise_type'] ?? '')
                              .toString();
                          final level = (ex['level'] ?? '').toString();
                          final selected = _selectedIdx.contains(i);
                          return CheckboxListTile(
                            value: selected,
                            onChanged: (v) {
                              setState(() {
                                if (v == true) {
                                  _selectedIdx.add(i);
                                } else {
                                  _selectedIdx.remove(i);
                                }
                              });
                            },
                            title: Text(name),
                            subtitle: Wrap(
                              spacing: 6,
                              children: [
                                if (type.isNotEmpty) Text(type),
                                if (level.isNotEmpty)
                                  Text(
                                    '• $level',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                              ],
                            ),
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
                          StatefulBuilder(
                            builder: (context, setStateSB) => Switch(
                              value: _replace,
                              onChanged: (v) => setStateSB(() => _replace = v),
                            ),
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
                            onPressed: _selectedIdx.isEmpty
                                ? null
                                : () {
                                    final selected = _selectedIdx
                                        .map((i) => _items[i])
                                        .toList(growable: false);
                                    Navigator.of(context).pop(
                                      _UpdateResult(
                                        selected,
                                        replace: _replace,
                                      ),
                                    );
                                  },
                            child: const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
