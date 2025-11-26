import 'package:supabase_flutter/supabase_flutter.dart';

class NutritionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> saveGoalEntry({
    required String goal, // 'lose' | 'maintain' | 'gain'
    required int deltaPercent, // 10 | 15 | 20
    int? caloriesTarget,
    double? carbsG,
    double? proteinG,
    double? fatG,
    double? sugarG,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Please sign in to save your nutrition goal.');
    }

    final payload = <String, dynamic>{
      'user_id': user.id,
      if (caloriesTarget != null) 'calories_target': caloriesTarget,
      if (carbsG != null) 'carbs_g': carbsG,
      if (proteinG != null) 'protein_g': proteinG,
      if (fatG != null) 'fat_g': fatG,
      if (sugarG != null) 'sugar_g': sugarG,
    };

    try {
      await _supabase.from('nutrition_goal_history').insert(payload);
    } on PostgrestException catch (e) {
      final code = e.code ?? '';
      final msg = e.message;
      // If column sugar_g doesn't exist in schema, retry without it and warn.
      if (code == 'PGRST204' ||
          msg.contains("sugar_g") ||
          msg.contains("Could not find the 'sugar_g' column")) {
        final fallback = Map<String, dynamic>.from(payload)..remove('sugar_g');
        try {
          await _supabase.from('nutrition_goal_history').insert(fallback);
          // Optionally, you can surface a soft warning to the caller via exception
          // but we prefer silent success with logs to avoid interrupting the user flow.
          // print('nutrition_goal_history.sugar_g column missing; saved without sugar.');
          return;
        } on PostgrestException catch (e2) {
          throw Exception(
            'Column sugar_g is missing on nutrition_goal_history and fallback insert failed: '
            '${e2.message}. To store sugar, run:\n\n'
            'alter table public.nutrition_goal_history add column sugar_g double precision;\n',
          );
        }
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getGoalHistory() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];
    try {
      try {
        final resp = await _supabase
            .from('nutrition_goal_history')
            .select(
              'id, calories_target, carbs_g, protein_g, fat_g, sugar_g, created_at',
            )
            .eq('user_id', user.id)
            .order('created_at', ascending: false);
        return resp
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
            .toList();
      } on PostgrestException catch (e) {
        // Fallback if sugar_g column doesn't exist
        final code = e.code ?? '';
        final msg = e.message;
        if (code == 'PGRST204' || msg.contains('sugar_g')) {
          final resp = await _supabase
              .from('nutrition_goal_history')
              .select(
                'id, calories_target, carbs_g, protein_g, fat_g, created_at',
              )
              .eq('user_id', user.id)
              .order('created_at', ascending: false);
          return resp
              .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
              .toList();
        }
        rethrow;
      }
    } catch (_) {
      return [];
    }
  }
}
