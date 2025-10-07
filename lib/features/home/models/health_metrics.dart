/// Health metrics data model
class HealthMetrics {
  final int? steps;
  final double? calories;
  final int? standingTimeMinutes;
  final double? sleepHours;
  final int? standingMinutes;
  final double? heartRate;
  final String? sleepStartTime;
  final DateTime lastUpdated;

  const HealthMetrics({
    this.steps,
    this.calories,
    this.standingTimeMinutes,
    this.sleepHours,
    this.standingMinutes,
    this.heartRate,
    this.sleepStartTime,
    required this.lastUpdated,
  });

  HealthMetrics copyWith({
    int? steps,
    double? calories,
    int? standingTimeMinutes,
    double? sleepHours,
    int? standingMinutes,
    double? heartRate,
    String? sleepStartTime,
    DateTime? lastUpdated,
  }) {
    return HealthMetrics(
      steps: steps ?? this.steps,
      calories: calories ?? this.calories,
      standingTimeMinutes: standingTimeMinutes ?? this.standingTimeMinutes,
      sleepHours: sleepHours ?? this.sleepHours,
      standingMinutes: standingMinutes ?? this.standingMinutes,
      heartRate: heartRate ?? this.heartRate,
      sleepStartTime: sleepStartTime ?? this.sleepStartTime,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'steps': steps,
      'calories': calories,
      'standingTimeMinutes': standingTimeMinutes,
      'sleepHours': sleepHours,
      'standingMinutes': standingMinutes,
      'heartRate': heartRate,
      'sleepStartTime': sleepStartTime,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory HealthMetrics.fromJson(Map<String, dynamic> json) {
    return HealthMetrics(
      steps: json['steps'] as int?,
      calories: _toDouble(json['calories']),
      standingTimeMinutes: json['standingTimeMinutes'] as int?,
      sleepHours: _toDouble(json['sleepHours']),
      standingMinutes: json['standingMinutes'] as int?,
      heartRate: _toDouble(json['heartRate']),
      sleepStartTime: json['sleepStartTime'] as String?,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

/// User targets/goals model
class HealthTargets {
  final int stepsTarget;
  final int caloriesTarget;
  final int standingTimeTargetMin;
  final double sleepTargetH;

  const HealthTargets({
    required this.stepsTarget,
    required this.caloriesTarget,
    required this.standingTimeTargetMin,
    required this.sleepTargetH,
  });

  HealthTargets copyWith({
    int? stepsTarget,
    int? caloriesTarget,
    int? standingTimeTargetMin,
    double? sleepTargetH,
  }) {
    return HealthTargets(
      stepsTarget: stepsTarget ?? this.stepsTarget,
      caloriesTarget: caloriesTarget ?? this.caloriesTarget,
      standingTimeTargetMin:
          standingTimeTargetMin ?? this.standingTimeTargetMin,
      sleepTargetH: sleepTargetH ?? this.sleepTargetH,
    );
  }
}

/// Complete health overview combining metrics and targets
class HealthOverview {
  final HealthMetrics metrics;
  final HealthTargets targets;

  const HealthOverview({required this.metrics, required this.targets});

  double getProgress(HealthMetricType type) {
    switch (type) {
      case HealthMetricType.steps:
        return _computeProgress(metrics.steps, targets.stepsTarget);
      case HealthMetricType.calories:
        return _computeProgress(metrics.calories, targets.caloriesTarget);
      case HealthMetricType.standingTime:
        return _computeProgress(
          metrics.standingTimeMinutes,
          targets.standingTimeTargetMin,
        );
      case HealthMetricType.sleep:
        return _computeProgress(metrics.sleepHours, targets.sleepTargetH);
    }
  }

  double _computeProgress(num? current, num target) {
    if (current == null) return 0.0;
    if (target <= 0) return 0.0;
    final p = current / target;
    if (p.isNaN || p.isInfinite) return 0.0;
    return p.clamp(0.0, 1.0);
  }
}

enum HealthMetricType { steps, calories, standingTime, sleep }
