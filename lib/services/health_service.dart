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
  static const List<HealthDataType> _readTypes = <HealthDataType>[
    HealthDataType.HEIGHT,
    HealthDataType.WEIGHT,
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.ACTIVE_ENERGY_BURNED,
  ];

  Future<bool> hasPermissions() async {
    final granted = await _health.hasPermissions(_readTypes, permissions: _readTypes.map((_) => HealthDataAccess.READ).toList());
    return granted ?? false;
  }

  Future<bool> requestPermissions() async {
    final ok = await _health.requestAuthorization(
      _readTypes,
      permissions: _readTypes.map((_) => HealthDataAccess.READ).toList(),
    );
    return ok;
  }

  // Fetch the latest height and weight to help prefill the survey.
  // Returns a map with keys: 'height' (double?), 'weight' (double?).
  Future<Map<String, double?>> fetchLatestProfileMetrics() async {
    final DateTime end = DateTime.now();
    final DateTime start = DateTime(end.year - 2); // look back 2 years

    final types = <HealthDataType>[HealthDataType.HEIGHT, HealthDataType.WEIGHT];
    final points = await _health.getHealthDataFromTypes(
      types: types,
      startTime: start,
      endTime: end,
    );

    double? latestHeight;
    double? latestWeight;
    DateTime? latestHeightAt;
    DateTime? latestWeightAt;

    for (final p in points) {
      if (p.type == HealthDataType.HEIGHT) {
        final v = (p.value is num) ? (p.value as num).toDouble() : double.tryParse('${p.value}');
        if (v != null) {
          if (latestHeightAt == null || p.dateTo.isAfter(latestHeightAt!)) {
            latestHeight = v;
            latestHeightAt = p.dateTo;
          }
        }
      } else if (p.type == HealthDataType.WEIGHT) {
        final v = (p.value is num) ? (p.value as num).toDouble() : double.tryParse('${p.value}');
        if (v != null) {
          if (latestWeightAt == null || p.dateTo.isAfter(latestWeightAt!)) {
            latestWeight = v;
            latestWeightAt = p.dateTo;
          }
        }
      }
    }

    return {
      'height': latestHeight,
      'weight': latestWeight,
    };
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
}
