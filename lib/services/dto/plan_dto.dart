// DTOs for transforming AI-generated plan into DB rows

class WorkoutPlanInsertDTO {
  final String exerciseName;
  final String? description;
  final String? difficultyLevel;
  final String? exerciseCategory;
  final int? durationMinutes;
  final String? repetitions;
  final String userId;
  final String day;

  const WorkoutPlanInsertDTO({
    required this.exerciseName,
    required this.userId,
    required this.day,
    this.description,
    this.difficultyLevel,
    this.exerciseCategory,
    this.durationMinutes,
    this.repetitions,
  });

  Map<String, dynamic> toMap() => {
        'exercise_name': exerciseName,
        if (description != null) 'description': description,
        if (difficultyLevel != null) 'difficulty_level': difficultyLevel,
        if (exerciseCategory != null) 'exercise_category': exerciseCategory,
        if (durationMinutes != null) 'duration_minutes': durationMinutes,
        if (repetitions != null) 'repetitions': repetitions,
        'user_id': userId,
        'day': day,
      };
}

class RelaxPlanInsertDTO {
  final String title;
  final String description;
  final String relaxationType;
  final String userId;
  final String day;

  const RelaxPlanInsertDTO({
    required this.title,
    required this.description,
    required this.relaxationType,
    required this.userId,
    required this.day,
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'relaxation_type': relaxationType,
        'user_id': userId,
        'day': day,
      };
}

class MealPlanInsertDTO {
  final String userId;
  final int dayIndex;
  final String dayLabel;
  final List<dynamic> meals;
  final List<dynamic> snacks;

  const MealPlanInsertDTO({
    required this.userId,
    required this.dayIndex,
    required this.dayLabel,
    required this.meals,
    required this.snacks,
  });

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'day_index': dayIndex,
        'day_label': dayLabel,
        'meals': meals,
        'snacks': snacks,
      };
}

class PlanInsertDTOs {
  final List<WorkoutPlanInsertDTO> workout;
  final List<RelaxPlanInsertDTO> relax;
  final List<MealPlanInsertDTO> meals;

  const PlanInsertDTOs({
    required this.workout,
    required this.relax,
    required this.meals,
  });

  static PlanInsertDTOs fromPlanSurvey({
    required Map<String, dynamic> plan,
    required Map<String, dynamic> survey,
    required String userId,
    required String Function(String? goal) mapGoalToCategory,
  }) {
    final days = plan['days'];
    final List<WorkoutPlanInsertDTO> workoutInserts = [];
    final List<RelaxPlanInsertDTO> relaxInserts = [];
    final List<MealPlanInsertDTO> mealInserts = [];

    if (days is List) {
      for (var i = 0; i < days.length; i++) {
        final raw = days[i];
        if (raw is! Map) continue;
        final dayLabel = raw['day']?.toString() ?? 'Day ${i + 1}';

        // Trainings
        final trainings = raw['training'];
        if (trainings is List) {
          for (final t in trainings) {
            if (t is! Map) continue;
            final type = t['type']?.toString() ?? '';
            final focus = t['focus']?.toString();
            final items = (t['items'] is List)
                ? (t['items'] as List).map((e) => e.toString()).toList()
                : const <String>[];

            if (type == 'primary') {
              for (final item in items) {
                final parsed = _parseExerciseItem(item);
                final dto = WorkoutPlanInsertDTO(
                  exerciseName: parsed.name,
                  description: parsed.detail ?? focus ?? dayLabel,
                  difficultyLevel: survey['activity_level']?.toString(),
                  exerciseCategory:
                      mapGoalToCategory(survey['diet_type']?.toString()),
                  durationMinutes: parsed.durationMinutes,
                  repetitions: parsed.repetitions,
                  userId: userId,
                  day: dayLabel,
                );
                workoutInserts.add(dto);
              }
            } else if (type == 'recovery') {
              final dto = RelaxPlanInsertDTO(
                title: '${focus ?? 'Recovery'}',
                description: items.join('\n'),
                relaxationType: focus ?? 'Recovery',
                userId: userId,
                day: dayLabel,
              );
              relaxInserts.add(dto);
            }
          }
        }

        // Meals per day
        final meals = (raw['meals'] is List) ? raw['meals'] as List : const [];
        final snacks = (raw['snacks'] is List) ? raw['snacks'] as List : const [];
        mealInserts.add(
          MealPlanInsertDTO(
            userId: userId,
            dayIndex: i + 1,
            dayLabel: dayLabel,
            meals: meals,
            snacks: snacks,
          ),
        );
      }
    }

    return PlanInsertDTOs(
      workout: workoutInserts,
      relax: relaxInserts,
      meals: mealInserts,
    );
  }
}

class _ParsedExerciseItem {
  final String name;
  final String? detail;
  final int? durationMinutes;
  final String? repetitions;

  const _ParsedExerciseItem({
    required this.name,
    this.detail,
    this.durationMinutes,
    this.repetitions,
  });
}

_ParsedExerciseItem _parseExerciseItem(String item) {
  final parts = item.split(RegExp(r"\s[-–—]\s"));
  final name = parts.isNotEmpty ? parts.first.trim() : item.trim();
  final tail = parts.length > 1 ? parts.sublist(1).join(' - ').trim() : null;
  int? durationMinutes;
  String? reps;
  if (tail != null) {
    final lower = tail.toLowerCase();
    final minMatch = RegExp(r"(\d+)\s*min").firstMatch(lower);
    if (minMatch != null) {
      durationMinutes = int.tryParse(minMatch.group(1) ?? '');
    }
    final repsMatch = RegExp(r"\b\d+x\d+\b").firstMatch(lower);
    if (repsMatch != null) {
      reps = repsMatch.group(0);
    }
  }
  return _ParsedExerciseItem(
    name: name,
    detail: tail,
    durationMinutes: durationMinutes,
    repetitions: reps,
  );
}
