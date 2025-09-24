import 'package:supabase_flutter/supabase_flutter.dart';

class PlanService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Save the plan into domain tables: workout_plan, relax_plan, and meal_plan.
  /// Also links created rows to `user_identity` via `exercise_id` and `relax_id`.
  Future<void> saveChildTables({
    required Map<String, dynamic> survey,
    required Map<String, dynamic> plan,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Please sign in to save your plan.');
    }
    // Build granular inserts from the AI plan
    final days = plan['days'];
    final List<Map<String, dynamic>> workoutInserts = [];
    final List<Map<String, dynamic>> relaxInserts = [];
    if (days is List) {
      for (var i = 0; i < days.length; i++) {
        final raw = days[i];
        if (raw is! Map) continue;
        final dayLabel = raw['day']?.toString() ?? 'Day ${i + 1}';
        final trainings = raw['training'];
        if (trainings is! List) continue;
        for (final t in trainings) {
          if (t is! Map) continue;
          final type = t['type']?.toString() ?? '';
          final focus = t['focus']?.toString();
          final items = (t['items'] is List)
              ? List<String>.from((t['items'] as List).map((e) => e.toString()))
              : <String>[];
          if (type == 'primary') {
            for (final item in items) {
              final parsed = _parseExerciseItem(item);
              workoutInserts.add({
                'exercise_name': parsed['name'] as String,
                'description': (parsed['detail'] as String?) ?? focus ?? dayLabel,
                'difficulty_level': survey['activity_level']?.toString(),
                'exercise_category': _mapGoalToCategory(survey['diet_type']?.toString()),
                if (parsed['duration'] != null) 'duration_minutes': parsed['duration'],
                if (parsed['repetitions'] != null) 'repetitions': parsed['repetitions'],
                'user_id': user.id,
              });
            }
          } else if (type == 'recovery') {
            relaxInserts.add({
              'title': '$dayLabel — ${focus ?? 'Recovery'}',
              'description': items.join('\n'),
              'relaxation_type': focus ?? 'Recovery',
              'user_id': user.id,
            });
          }
        }
      }
    }

    // Best-effort cleanup to avoid duplicate plans on repeated saves
    try {
      await _supabase.from('meal_plan').delete().eq('user_id', user.id);
    } catch (_) {}
    try {
      await _supabase.from('workout_plan').delete().eq('user_id', user.id);
    } catch (_) {}
    try {
      await _supabase.from('relax_plan').delete().eq('user_id', user.id);
    } catch (_) {}

    // Insert workout items (multi-row)
    Map<String, dynamic>? firstWorkoutRow;
    if (workoutInserts.isNotEmpty) {
      try {
        final resp = await _supabase
            .from('workout_plan')
            .insert(workoutInserts)
            .select()
            .limit(1);
        if (resp is List && resp.isNotEmpty) {
          firstWorkoutRow = Map<String, dynamic>.from(resp.first as Map);
        }
      } on PostgrestException catch (e) {
        final code = e.code ?? '';
        final msg = e.message ?? '';
        if (code == '42703' || msg.contains('column') && msg.contains('user_id')) {
          final fallback = workoutInserts
              .map((m) => Map<String, dynamic>.from(m)..remove('user_id'))
              .toList();
          final resp = await _supabase
              .from('workout_plan')
              .insert(fallback)
              .select()
              .limit(1);
          if (resp is List && resp.isNotEmpty) {
            firstWorkoutRow = Map<String, dynamic>.from(resp.first as Map);
          }
        } else {
          _throwHelpfulPolicyError('workout_plan', e);
        }
      }
    }

    // Insert relax items (multi-row)
    Map<String, dynamic>? firstRelaxRow;
    if (relaxInserts.isNotEmpty) {
      try {
        final resp = await _supabase
            .from('relax_plan')
            .insert(relaxInserts)
            .select()
            .limit(1);
        if (resp is List && resp.isNotEmpty) {
          firstRelaxRow = Map<String, dynamic>.from(resp.first as Map);
        }
      } on PostgrestException catch (e) {
        final code = e.code ?? '';
        final msg = e.message ?? '';
        if (code == '42703' || msg.contains('column') && msg.contains('user_id')) {
          final fallback = relaxInserts
              .map((m) => Map<String, dynamic>.from(m)..remove('user_id'))
              .toList();
          final resp = await _supabase
              .from('relax_plan')
              .insert(fallback)
              .select()
              .limit(1);
          if (resp is List && resp.isNotEmpty) {
            firstRelaxRow = Map<String, dynamic>.from(resp.first as Map);
          }
        } else {
          _throwHelpfulPolicyError('relax_plan', e);
        }
      }
    }

    // Insert meal_plan rows (one per day)
    try {
      final days = plan['days'];
      if (days is List) {
        final inserts = <Map<String, dynamic>>[];
        for (var i = 0; i < days.length; i++) {
          final d = days[i];
          if (d is! Map) continue;
          final meals = (d['meals'] is List) ? d['meals'] as List : const [];
          final snacks = (d['snacks'] is List) ? d['snacks'] as List : const [];
          inserts.add({
            'user_id': user.id,
            'day_index': i + 1,
            'day_label': d['day']?.toString() ?? 'Day ${i + 1}',
            'meals': meals,
            'snacks': snacks,
          });
        }
        if (inserts.isNotEmpty) {
          await _supabase.from('meal_plan').insert(inserts);
        }
      }
    } on PostgrestException catch (e) {
      final code = e.code ?? '';
      final msg = e.message ?? '';
      if (code == '42P01' || msg.contains('relation "meal_plan" does not exist')) {
        throw Exception(
          'Table meal_plan not found. Please run this SQL in Supabase to enable saving meals:\n\n'
          'create table if not exists public.meal_plan (\n'
          '  id bigint generated by default as identity primary key,\n'
          '  user_id uuid references auth.users(id) on delete cascade,\n'
          '  day_index int not null,\n'
          '  day_label text,\n'
          '  meals jsonb not null,\n'
          '  snacks jsonb,\n'
          '  created_at timestamptz not null default now()\n'
          ');\n\n'
          'alter table public.meal_plan enable row level security;\n'
          'create policy "Select own" on public.meal_plan for select using (auth.uid() = user_id);\n'
          'create policy "Insert own" on public.meal_plan for insert with check (auth.uid() = user_id);\n'
          'create policy "Update own" on public.meal_plan for update using (auth.uid() = user_id) with check (auth.uid() = user_id);\n'
          'create policy "Delete own" on public.meal_plan for delete using (auth.uid() = user_id);',
        );
      }
      rethrow;
    }

    // Link created rows to user_identity
    try {
      final uid = user.id;
      final existing = await _supabase
          .from('user_identity')
          .select('id')
          .eq('user_id', uid)
          .maybeSingle();
      final updatePayload = <String, dynamic>{
        if (firstWorkoutRow != null && firstWorkoutRow['id'] != null) 'exercise_id': firstWorkoutRow['id'],
        if (firstRelaxRow != null && firstRelaxRow['id'] != null) 'relax_id': firstRelaxRow['id'],
        if (survey['diet_type'] != null) 'diet_type': survey['diet_type'].toString(),
      };
      if (existing == null) {
        await _supabase.from('user_identity').insert({
          'user_id': uid,
          ...updatePayload,
        });
      } else {
        await _supabase
            .from('user_identity')
            .update(updatePayload)
            .eq('user_id', uid);
      }
    } catch (e) {
      // Non-fatal; user_identity linkage may fail if RLS prohibits updates
      // Ignore silently but could be logged if needed.
    }
  }

  num? _tryNum(dynamic v) {
    if (v == null) return null;
    if (v is num) return v;
    if (v is String) return num.tryParse(v);
    return null;
  }

  // Parse an exercise item string like
  // "Bodyweight squats - 3x12" or "Light cycling - 20 min"
  // Returns map: {name, detail?, duration?, repetitions?}
  Map<String, String?> _parseExerciseItem(String item) {
    final parts = item.split(RegExp(r"\s[-–—]\s"));
    final name = parts.isNotEmpty ? parts.first.trim() : item.trim();
    final tail = parts.length > 1 ? parts.sublist(1).join(' - ').trim() : null;
    String? duration;
    String? reps;
    if (tail != null) {
      final lower = tail.toLowerCase();
      if (lower.contains('min')) {
        final match = RegExp(r"(\d+)\s*min").firstMatch(lower);
        if (match != null) duration = match.group(1);
      }
      if (RegExp(r"\b\d+x\d+\b").hasMatch(lower)) {
        reps = RegExp(r"\b\d+x\d+\b").firstMatch(lower)?.group(0);
      }
    }
    return {
      'name': name,
      'detail': tail,
      'duration': duration,
      'repetitions': reps,
    };
  }

  String _mapGoalToCategory(String? goal) {
    switch (goal) {
      case 'lost_weight':
      case 'lose_weight':
        return 'weight_loss';
      case 'gain_weight':
        return 'muscle_gain';
      case 'maintain_weight':
      default:
        return 'maintenance';
    }
  }

  Never _throwHelpfulPolicyError(String table, PostgrestException e) {
    final code = e.code ?? '';
    final msg = e.message ?? '';
    // If table missing or RLS blocks, provide guidance
    if (code == '42P01' || msg.contains('does not exist')) {
      throw Exception('Table $table not found. Please create it in Supabase or ensure it matches the app schema.');
    }
    if (code == '42703' || msg.contains('column') && msg.contains('user_id')) {
      throw Exception(
        'Column user_id missing on "$table". To enable owner-based RLS, run:\n\n'
        'alter table public.$table add column user_id uuid references auth.users(id) on delete cascade;\n'
        'alter table public.$table enable row level security;\n'
        'create policy "Select own" on public.$table for select using (auth.uid() = user_id);\n'
        'create policy "Insert own" on public.$table for insert with check (auth.uid() = user_id);\n'
        'create policy "Update own" on public.$table for update using (auth.uid() = user_id) with check (auth.uid() = user_id);\n'
        'create policy "Delete own" on public.$table for delete using (auth.uid() = user_id);',
      );
    }
    if (msg.contains('new row violates row-level security policy') || msg.toLowerCase().contains('rls')) {
      throw Exception(
        'RLS prevented writing to "$table". Ensure appropriate policies exist to allow authenticated users to insert/select.\n'
        'Owner-based example:\n'
        '  alter table public.$table enable row level security;\n'
        '  create policy "Select own" on public.$table for select using (auth.uid() = user_id);\n'
        '  create policy "Insert own" on public.$table for insert with check (auth.uid() = user_id);\n'
        '  create policy "Update own" on public.$table for update using (auth.uid() = user_id) with check (auth.uid() = user_id);\n'
        '  create policy "Delete own" on public.$table for delete using (auth.uid() = user_id);',
      );
    }
    throw e;
  }
}
