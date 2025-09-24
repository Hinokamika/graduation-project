class NutritionCalculator {
  static double _activityMultiplier(String? level) {
    final l = (level ?? '').toLowerCase();
    if (l.contains('sedentary')) return 1.2;
    if (l.contains('light')) return 1.375; // 1-3 days/week
    if (l.contains('moderate')) return 1.55; // 3-5 days/week
    if (l.contains('very') || l.contains('hard')) return 1.725; // 6-7 days/week
    return 1.2; // default sedentary
  }

  // Mifflin-St Jeor BMR (metric inputs)
  static double? computeBmr({
    required double? weightKg,
    required double? heightCm,
    required int? ageYears,
    required String? gender,
  }) {
    if (weightKg == null || heightCm == null || ageYears == null) return null;
    final g = (gender ?? '').toLowerCase();
    final isFemale = g.startsWith('f');
    final bmr = isFemale
        ? 10 * weightKg + 6.25 * heightCm - 5 * ageYears - 161
        : 10 * weightKg + 6.25 * heightCm - 5 * ageYears + 5;
    return bmr;
  }

  static Map<String, double> computeTargetsFromSurvey(
    Map<String, dynamic> survey, {
    String goal = 'maintain', // 'lose' | 'maintain' | 'gain'
    int deltaPercent = 15, // 10, 15, 20
  }) {
    final weight = (survey['weight'] is num)
        ? (survey['weight'] as num).toDouble()
        : null;
    final height = (survey['height'] is num)
        ? (survey['height'] as num).toDouble()
        : null;
    final age = (survey['age'] is num) ? (survey['age'] as num).toInt() : null;
    final gender = survey['gender']?.toString();
    final activity = survey['activity_level']?.toString();

    final bmr = computeBmr(
      weightKg: weight,
      heightCm: height,
      ageYears: age,
      gender: gender,
    );
    final multiplier = _activityMultiplier(activity);
    var tdee = (bmr ?? 2000) * multiplier;

    // Apply goal adjustment to calories
    final dp = (deltaPercent.clamp(10, 20)) / 100.0;
    switch (goal.toLowerCase()) {
      case 'lose':
        tdee = tdee * (1.0 - dp);
        break;
      case 'gain':
        tdee = tdee * (1.0 + dp);
        break;
      case 'maintain':
      default:
        break;
    }

    // Macro targets
    // Protein: 1.6 g/kg, Fat: 0.9 g/kg, Carbs = remaining kcal / 4
    final proteinG = weight != null ? (1.6 * weight) : 90.0;
    final fatG = weight != null ? (0.9 * weight) : 73.0;
    final remainingKcal = (tdee - (proteinG * 4) - (fatG * 9)).clamp(0, 1e6);
    final carbsG = remainingKcal / 4.0;

    return {
      'energy_kcal': tdee,
      'protein_g': proteinG,
      'fat_g': fatG,
      'carbs_g': carbsG,
    };
  }
}
