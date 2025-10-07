import 'dart:async';
import 'package:health/health.dart';
import 'package:flutter/foundation.dart';

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
    // Sleep categories: request all we might query
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_IN_BED,
    HealthDataType.SLEEP_AWAKE,
    // Sleep stages (Apple Watch):
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,
    HealthDataType.APPLE_STAND_HOUR, // Changed from WATER to APPLE_STAND_HOUR
    HealthDataType.BODY_MASS_INDEX,
    HealthDataType.RESTING_HEART_RATE,
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
    debugPrint('🏥 HealthService: Fetching today\'s steps...');
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    try {
      final stepsData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: startOfDay,
        endTime: now,
      );

      if (stepsData.isEmpty) {
        debugPrint('🏥 HealthService: No steps data found for today');
        return null;
      }

      final totalSteps = stepsData
          .map((data) => _asDouble(data.value)?.toInt() ?? 0)
          .fold<int>(0, (sum, steps) => sum + steps);

      debugPrint(
        '🏥 HealthService: Found ${stepsData.length} step entries, total: $totalSteps',
      );
      return totalSteps;
    } catch (e) {
      debugPrint('❌ HealthService: Error fetching steps: $e');
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
        final v = _asDouble(p.value) ?? 0.0;
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
    debugPrint('🏥 HealthService: Fetching today\'s heart rate...');
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    try {
      final points = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: startOfDay,
        endTime: now,
      );
      if (points.isEmpty) {
        debugPrint('🏥 HealthService: No heart rate data found for today');
        return null;
      }
      double total = 0;
      int count = 0;
      for (final p in points) {
        final v = _asDouble(p.value) ?? 0.0;
        total += v;
        count++;
      }
      final result = total > 0 ? total / count : null;
      debugPrint(
        '🏥 HealthService: Found $count heart rate entries, average: $result',
      );
      return result;
    } catch (e) {
      debugPrint('❌ HealthService: Error fetching heart rate: $e');
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
        final v = _asDouble(p.value) ?? 0.0;
        if (p.type == HealthDataType.DIETARY_ENERGY_CONSUMED) {
          out['energy_kcal'] = (out['energy_kcal'] ?? 0) + v;
        }
      }
    } catch (_) {}
    return out;
  }

  // Fetch today's calories (total energy)
  Future<double?> fetchTodayCalories() async {
    debugPrint('🏥 HealthService: Fetching today\'s calories...');
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    try {
      double totalActive = 0;
      double totalDietary = 0;

      // Get active energy burned
      final activePoints = await _health.getHealthDataFromTypes(
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: startOfDay,
        endTime: now,
      );
      for (final p in activePoints) {
        final v = _asDouble(p.value) ?? 0.0;
        totalActive += v;
      }

      // Get dietary energy consumed
      final dietaryPoints = await _health.getHealthDataFromTypes(
        types: [HealthDataType.DIETARY_ENERGY_CONSUMED],
        startTime: startOfDay,
        endTime: now,
      );
      for (final p in dietaryPoints) {
        final v = _asDouble(p.value) ?? 0.0;
        totalDietary += v;
      }

      final result = totalActive > 0
          ? totalActive
          : (totalDietary > 0 ? totalDietary : null);
      debugPrint(
        '🏥 HealthService: Active: $totalActive, Dietary: $totalDietary, Result: $result',
      );
      return result;
    } catch (e) {
      debugPrint('❌ HealthService: Error fetching calories: $e');
      return null;
    }
  }

  // Fetch today's sleep hours
  Future<double?> fetchTodaySleepHours() async {
    debugPrint('🏥 HealthService: Fetching today\'s sleep hours...');
    final now = DateTime.now();
    // Sleep commonly spans past midnight. Use a generous window of 36 hours
    // to reliably capture the last overnight session + any naps.
    final startWindow = DateTime(now.year, now.month, now.day);
    final endWindow = now;

    try {
      // Try to read ASLEEP first; if none, fall back to IN_BED which most
      // devices can record. We explicitly avoid AWAKE in totals.
      final asleep = await _health.getHealthDataFromTypes(
        types: [HealthDataType.SLEEP_ASLEEP],
        startTime: startWindow,
        endTime: endWindow,
      );

      List<HealthDataPoint> segments = asleep;

      // If no generic ASLEEP segments, try summing sleep stages (REM/DEEP/LIGHT)
      if (segments.isEmpty) {
        final stagePoints = await _health.getHealthDataFromTypes(
          types: [
            HealthDataType.SLEEP_REM,
            HealthDataType.SLEEP_DEEP,
            HealthDataType.SLEEP_LIGHT,
          ],
          startTime: startWindow,
          endTime: endWindow,
        );
        if (stagePoints.isNotEmpty) {
          segments = stagePoints;
        }
      }

      if (segments.isEmpty) {
        // Compute asleep as IN_BED - AWAKE when ASLEEP is unavailable.
        final inBed = await _health.getHealthDataFromTypes(
          types: [HealthDataType.SLEEP_IN_BED],
          startTime: startWindow,
          endTime: endWindow,
        );
        final awake = await _health.getHealthDataFromTypes(
          types: [HealthDataType.SLEEP_AWAKE],
          startTime: startWindow,
          endTime: endWindow,
        );

        if (inBed.isEmpty && awake.isEmpty) {
          debugPrint('🏥 HealthService: No sleep data found');
          return null;
        }

        double inBedH = 0.0;
        for (final d in inBed) {
          inBedH += d.dateTo.difference(d.dateFrom).inMinutes / 60.0;
        }
        double awakeH = 0.0;
        for (final d in awake) {
          awakeH += d.dateTo.difference(d.dateFrom).inMinutes / 60.0;
        }
        final total = (inBedH - awakeH).clamp(0.0, double.infinity);
        debugPrint(
          '🏥 HealthService: Sleep fallback -> inBed: ${inBed.length} (${inBedH.toStringAsFixed(2)}h), '
          'awake: ${awake.length} (${awakeH.toStringAsFixed(2)}h), total: ${total.toStringAsFixed(2)}h',
        );
        return total > 0 ? total : null;
      }

      // Sum all sleep segments (generic ASLEEP or stage segments)
      double totalHours = 0.0;
      for (final data in segments) {
        final startTime = data.dateFrom;
        final endTime = data.dateTo;
        final duration = endTime.difference(startTime);
        totalHours += duration.inMinutes / 60.0;
      }

      debugPrint(
        '🏥 HealthService: Found ${segments.length} sleep entries, total hours: $totalHours',
      );
      return totalHours > 0 ? totalHours : null;
    } catch (e) {
      debugPrint('❌ HealthService: Error fetching sleep: $e');
      return null;
    }
  }

  // Fetch today's standing hours (optimized for performance)
  Future<int?> fetchTodayStandingTimeMinutes() async {
    debugPrint('🏥 HealthService: Fetching today\'s standing hours...');
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    try {
      final standingData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.APPLE_STAND_HOUR],
        startTime: startOfDay,
        endTime: now,
      );

      if (standingData.isEmpty) {
        // Fallback approximation for users without Apple Watch: estimate stand
        // hours by counting hours that contain any steps. This is not identical
        // to Apple Stand Hours, but provides a useful proxy when no watch data
        // exists.
        final stepPoints = await _health.getHealthDataFromTypes(
          types: [HealthDataType.STEPS],
          startTime: startOfDay,
          endTime: now,
        );

        if (stepPoints.isEmpty) {
          debugPrint('🏥 HealthService: No standing hour data and no step data');
          return null;
        }

        final Set<String> standHours = <String>{};
        for (final p in stepPoints) {
          final steps = _asDouble(p.value) ?? 0.0;
          if (steps <= 0) continue;
          DateTime h = DateTime(p.dateFrom.year, p.dateFrom.month, p.dateFrom.day, p.dateFrom.hour);
          final end = p.dateTo;
          while (!h.isAfter(end)) {
            // Use hour key YYYY-MM-DDTHH for uniqueness
            final key = '${h.year}-${h.month.toString().padLeft(2, '0')}-${h.day.toString().padLeft(2, '0')}T${h.hour.toString().padLeft(2, '0')}';
            standHours.add(key);
            h = h.add(const Duration(hours: 1));
          }
        }

        final approxHours = standHours.length;
        final approxMinutes = approxHours ;
        debugPrint(
          '🏥 HealthService: Standing fallback by steps -> hours: $approxHours, minutes: $approxMinutes',
        );
        return approxMinutes > 0 ? approxMinutes : null;
      }

      // APPLE_STAND_HOUR returns 1 for each hour where user stood for at least 1 minute
      // Simply count the entries and convert to minutes (multiply by 60)
      final standingHours = standingData.length;
      final standingMinutes = standingHours;

      debugPrint(
        '🏥 HealthService: Found $standingHours standing hours = $standingMinutes minutes',
      );
      return standingMinutes > 0 ? standingMinutes : null;
    } catch (e) {
      debugPrint('❌ HealthService: Error fetching standing hours: $e');
      return null;
    }
  }

  // Safely convert plugin value objects into a double in a best-effort way.
  // health >= 8 introduced typed values (e.g., NumericHealthValue, HeartRateHealthValue,
  // etc.). Fall back to parsing when types are unknown.
  double? _asDouble(dynamic value) {
    try {
      if (value == null) return null;
      // Numeric wrapper (steps, energy, many metrics)
      if (value is NumericHealthValue) {
        return value.numericValue.toDouble();
      }
      // Try common typed fields via dynamic access without importing symbols
      final dyn = value as dynamic;
      // Heart rate: bpm
      try {
        final bpm = dyn.bpm;
        if (bpm is num) return bpm.toDouble();
      } catch (_) {}
      // Energy: kcal
      try {
        final kcal = dyn.kcal;
        if (kcal is num) return kcal.toDouble();
      } catch (_) {}
      // Water: ml or liters
      try {
        final ml = dyn.ml;
        if (ml is num) return ml.toDouble();
      } catch (_) {}
      try {
        final liters = dyn.liters;
        if (liters is num) return (liters.toDouble() * 1000.0);
      } catch (_) {}
      // Generic numericValue on some base classes
      try {
        final n = dyn.numericValue;
        if (n is num) return n.toDouble();
      } catch (_) {}
      // Fallback: parse to double if possible
      return double.tryParse('$value');
    } catch (_) {
      return null;
    }
  }
}
