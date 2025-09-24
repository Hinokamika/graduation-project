import 'dart:async';
import 'package:health/health.dart';

class HealthService {
  HealthService._();
  static final HealthService _instance = HealthService._();
  factory HealthService() => _instance;

  // The Health package exposes a `Health` class in recent versions.
  // If using older versions, `HealthFactory` was used instead.
  // Our pubspec pins a modern version, so use `Health`.
  final Health _health = Health();

  // The health data types we want to read.
  static final List<HealthDataType> _readTypes = <HealthDataType>[
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.DIETARY_ENERGY_CONSUMED,
    HealthDataType.SLEEP_SESSION,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.BODY_MASS_INDEX,
  ];

  Future<bool> hasPermissions() async {
    final granted = await _health.hasPermissions(
      _readTypes,
      permissions: _readTypes.map((_) => HealthDataAccess.READ).toList(),
    );
    return granted ?? false;
  }

  Future<bool> requestPermissions() async {
    final ok = await _health.requestAuthorization(
      _readTypes,
      permissions: _readTypes.map((_) => HealthDataAccess.READ).toList(),
    );
    return ok;
  }

  // Example: fetch total steps for today
  Future<int?> fetchTodaySteps() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    try {
      final steps = await _health.getTotalStepsInInterval(startOfDay, now);
      return steps;
    } catch (_) {
      return null;
    }
  }

  // Fetch total active energy burned (kcal) for today
  Future<double?> fetchTodayActiveEnergyKCal() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    try {
      final points = await _health.getHealthDataFromTypes(
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: startOfDay,
        endTime: now,
      );
      double total = 0;
      for (final p in points) {
        final v = (p.value is num)
            ? (p.value as num).toDouble()
            : double.tryParse('${p.value}') ?? 0.0;
        total += v;
      }
      return total;
    } catch (_) {
      return null;
    }
  }

  // Fetch steps for the last N days (inclusive of today)
  Future<List<int>> fetchStepsForLastDays(int days) async {
    final List<int> daily = [];
    final now = DateTime.now();
    for (int i = days - 1; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final start = DateTime(day.year, day.month, day.day);
      final end = start
          .add(const Duration(days: 1))
          .subtract(const Duration(milliseconds: 1));
      try {
        final steps = await _health.getTotalStepsInInterval(start, end);
        daily.add(steps ?? 0);
      } catch (_) {
        daily.add(0);
      }
    }
    return daily;
  }

  // Average heart rate for today (bpm)
  Future<double?> fetchTodayAverageHeartRate() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    try {
      final points = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: startOfDay,
        endTime: now,
      );
      if (points.isEmpty) return null;
      double sum = 0;
      int count = 0;
      for (final p in points) {
        final v = (p.value is num)
            ? (p.value as num).toDouble()
            : double.tryParse('${p.value}');
        if (v != null) {
          sum += v;
          count += 1;
        }
      }
      if (count == 0) return null;
      return sum / count;
    } catch (_) {
      return null;
    }
  }

  // Fetch today's nutrition totals (kcal, carbs g, protein g, fat g)
  Future<Map<String, double>> fetchTodayNutrition() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final end = now;
    final out = <String, double>{
      'energy_kcal': 0.0,
      'carbs_g': 0.0,
      'protein_g': 0.0,
      'fat_g': 0.0,
    };
    try {
      final points = await _health.getHealthDataFromTypes(
        types: [HealthDataType.DIETARY_ENERGY_CONSUMED],
        startTime: startOfDay,
        endTime: end,
      );
      for (final p in points) {
        final v = (p.value is num)
            ? (p.value as num).toDouble()
            : double.tryParse('${p.value}') ?? 0.0;
        if (p.type == HealthDataType.DIETARY_ENERGY_CONSUMED) {
          out['energy_kcal'] = (out['energy_kcal'] ?? 0) + v;
        }
      }
    } catch (_) {}
    return out;
  }
}
