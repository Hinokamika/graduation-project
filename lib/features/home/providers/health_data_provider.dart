import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../services/health_service.dart';
import '../../../services/habit_service.dart';
import '../../../services/user_service.dart';
import '../models/health_metrics.dart';

/// Real-time health data provider with automatic refresh
class HealthDataProvider extends ChangeNotifier {
  static const Duration _refreshInterval = Duration(minutes: 10);
  static const Duration _healthKitInterval = Duration(minutes: 5);

  final HealthService _healthService = HealthService();
  final HabitService _habitService = HabitService();
  final UserService _userService = UserService();

  Timer? _refreshTimer;
  Timer? _healthKitTimer;

  HealthOverview? _overview;
  bool _isLoading = false;
  String? _error;
  bool _hasHealthPermissions = false;

  HealthOverview? get overview => _overview;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasHealthPermissions => _hasHealthPermissions;

  HealthDataProvider() {
    // Kick off a first render fast: load data immediately
    refreshData();
    // Check permissions in background; when ready, do a HealthKit-only refresh
    unawaited(_checkHealthPermissions().then((_) => _refreshHealthKitData()));
    _startAutoRefresh();
  }

  // Initializer removed in favor of faster, parallel startup

  Future<void> _checkHealthPermissions() async {
    try {
      _hasHealthPermissions = await _healthService.hasPermissions();
      if (!_hasHealthPermissions) {
        _hasHealthPermissions = await _healthService.requestPermissions();
      }
    } catch (e) {
      debugPrint('Health permissions check failed: $e');
    }
  }

  void _startAutoRefresh() {
    // Regular data refresh every 5 minutes
    _refreshTimer = Timer.periodic(_refreshInterval, (_) => refreshData());

    // More frequent HealthKit refresh every 2 minutes for real-time data
    _healthKitTimer = Timer.periodic(
      _healthKitInterval,
      (_) => _refreshHealthKitData(),
    );
  }

  Future<void> refreshData() async {
    _setLoading(true);
    _setError(null);

    try {
      // Load targets
      final targets = await _loadTargets();

      // Load today's metrics from both HealthKit and local storage
      final metrics = await _loadTodayMetrics();

      _overview = HealthOverview(metrics: metrics, targets: targets);

      // Auto-save today's progress to Supabase habit table
      unawaited(_persistTodayMetrics(metrics));

      notifyListeners();
    } catch (e) {
      _setError('Failed to load health data: $e');
      debugPrint('Health data refresh failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _refreshHealthKitData() async {
    if (!_hasHealthPermissions || _overview == null) return;

    try {
      // Only refresh HealthKit data without showing loading state
      final healthKitMetrics = await _loadHealthKitMetrics();

      if (healthKitMetrics != null) {
        // Merge with existing metrics, preferring HealthKit data
        final currentMetrics = _overview!.metrics;
        final updatedMetrics = currentMetrics.copyWith(
          steps: healthKitMetrics.steps ?? currentMetrics.steps,
          calories: healthKitMetrics.calories ?? currentMetrics.calories,
          standingTimeMinutes:
              healthKitMetrics.standingTimeMinutes ??
              currentMetrics.standingTimeMinutes,
          sleepHours: healthKitMetrics.sleepHours ?? currentMetrics.sleepHours,
          heartRate: healthKitMetrics.heartRate ?? currentMetrics.heartRate,
          lastUpdated: DateTime.now(),
        );

        _overview = HealthOverview(
          metrics: updatedMetrics,
          targets: _overview!.targets,
        );

        // Auto-save after merging fresh HealthKit data
        unawaited(_persistTodayMetrics(updatedMetrics));

        notifyListeners();
      }
    } catch (e) {
      debugPrint('HealthKit refresh failed: $e');
    }
  }

  Future<HealthTargets> _loadTargets() async {
    // Fetch all targets concurrently to reduce latency
    final results = await Future.wait([
      _userService.getStepsTarget(),
      _userService.getCaloriesTarget(),
      _userService.getStandingTimeTargetMinutes(),
      _userService.getSleepTargetHours(),
    ]);

    final steps = results[0] as int;
    final calories = results[1] as int;
    final standingTime = results[2] as int;
    final sleep = results[3] as double;

    return HealthTargets(
      stepsTarget: steps,
      caloriesTarget: calories,
      standingTimeTargetMin: standingTime,
      sleepTargetH: sleep,
    );
  }

  Future<HealthMetrics> _loadTodayMetrics() async {
    // Load HealthKit and local in parallel, then merge
    final results = await Future.wait([
      _loadHealthKitMetrics(),
      _loadLocalMetrics(),
    ]);
    final healthKitMetrics = results[0] as HealthMetrics?;
    final localMetrics = results[1] as HealthMetrics?;

    // Merge data, preferring HealthKit when available
    return HealthMetrics(
      steps: healthKitMetrics?.steps ?? localMetrics?.steps,
      calories: healthKitMetrics?.calories ?? localMetrics?.calories,
      standingTimeMinutes:
          healthKitMetrics?.standingTimeMinutes ??
          localMetrics?.standingTimeMinutes,
      sleepHours: healthKitMetrics?.sleepHours ?? localMetrics?.sleepHours,
      standingMinutes: localMetrics?.standingMinutes, // Only from local
      heartRate: healthKitMetrics?.heartRate ?? localMetrics?.heartRate,
      sleepStartTime: localMetrics?.sleepStartTime, // Only from local
      lastUpdated: DateTime.now(),
    );
  }

  Future<HealthMetrics?> _loadHealthKitMetrics() async {
    if (!_hasHealthPermissions) return null;

    try {
      // Parallel fetch for better performance
      final results = await Future.wait([
        _healthService.fetchTodaySteps(),
        _healthService.fetchTodayCalories(),
        _healthService.fetchTodayStandingTimeMinutes(),
        _healthService.fetchTodaySleepHours(),
        _healthService.fetchTodayAverageHeartRate(),
      ]);

      final steps = results[0] as int?;
      final calories = results[1] as double?;
      final standingTime = results[2] as int?;
      final sleep = results[3] as double?;
      final heartRate = results[4] as double?;

      debugPrint(
        'HealthKit Sync - Steps: $steps, Calories: $calories, Standing: ${standingTime}min, Sleep: $sleep, HR: $heartRate',
      );

      return HealthMetrics(
        steps: steps,
        calories: calories,
        standingTimeMinutes: standingTime,
        sleepHours: sleep,
        heartRate: heartRate,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      debugPrint('HealthKit data loading failed: $e');
      return null;
    }
  }

  Future<HealthMetrics?> _loadLocalMetrics() async {
    try {
      final today = DateTime.now();
      final rows = await _habitService.getMetricsRange(today, today);

      if (rows.isEmpty) return null;

      final data = rows.first;
      final standingTime = (data['standing_minutes'] ?? data['standing_time_minutes']) as int?;
      return HealthMetrics(
        steps: data['steps'] as int?,
        calories: _toDouble(data['calories']),
        standingTimeMinutes: standingTime,
        sleepHours: _toDouble(data['sleep_hours']),
        standingMinutes: data['standing_minutes'] as int?,
        heartRate: _toDouble(data['heart_rate_avg']),
        sleepStartTime: data['sleep_start_time'] as String?,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Local metrics loading failed: $e');
      return null;
    }
  }

  Future<void> updateTarget(HealthMetricType type, num value) async {
    if (_overview == null) return;

    try {
      _setLoading(true);

      switch (type) {
        case HealthMetricType.steps:
          await _userService.setStepsTarget(value as int);
          break;
        case HealthMetricType.calories:
          await _userService.setCaloriesTarget(value as int);
          break;
        case HealthMetricType.standingTime:
          await _userService.setStandingTimeTargetMinutes(value as int);
          break;
        case HealthMetricType.sleep:
          await _userService.setSleepTargetHours(value as double);
          break;
      }

      // Refresh data to get updated targets
      await refreshData();
    } catch (e) {
      _setError('Failed to update target: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateTodayMetrics({
    int? steps,
    int? calories,
    int? standingTimeMinutes,
    double? sleepHours,
    int? standingMinutes,
    int? heartRateAvg,
    String? sleepStartTime,
  }) async {
    try {
      await _habitService.upsertTodayMetrics(
        steps: steps,
        calories: calories,
        standingTimeMinutes: standingTimeMinutes,
        sleepHours: sleepHours,
        standingMinutes: standingMinutes,
        heartRateAvg: heartRateAvg,
        sleepStartTime: sleepStartTime,
      );

      // Refresh data immediately after update
      await refreshData();
    } catch (e) {
      _setError('Failed to update metrics: $e');
      rethrow;
    }
  }

  // Persist today's metrics to Supabase habit table (bucketed by local date).
  Future<void> _persistTodayMetrics(HealthMetrics metrics) async {
    try {
      await _habitService.upsertTodayMetrics(
        steps: metrics.steps,
        calories: metrics.calories?.round(),
        standingTimeMinutes: metrics.standingTimeMinutes,
        sleepHours: metrics.sleepHours,
        heartRateAvg: metrics.heartRate?.round(),
      );
    } catch (e) {
      // Ignore persistence errors in background; visible flow shouldn't break
      debugPrint('Background persist failed: $e');
    }
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String? error) {
    if (_error != error) {
      _error = error;
      notifyListeners();
    }
  }

  static double? _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _healthKitTimer?.cancel();
    super.dispose();
  }
}
