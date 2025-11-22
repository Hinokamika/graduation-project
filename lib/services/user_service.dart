import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'connectivity_service.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:final_project/services/health_service.dart';

class UserService {
  static const String _userBoxName = 'userBox';
  static const String _onboardingKey = 'onboardingComplete';
  static const String _userIdentityIdKey = 'user_identity_id';
  static const String _surveyDirtyKey = 'survey_dirty';
  static const String _healthPermissionPromptedKey =
      'health_permission_prompted';
  static const String _nutritionGoalKey =
      'nutrition_goal'; // 'lose' | 'maintain' | 'gain'
  static const String _nutritionGoalDeltaKey =
      'nutrition_goal_delta'; // 10 | 15 | 20
  // Today's Summary targets
  static const String _stepsTargetKey = 'steps_target'; // int
  static const String _caloriesTargetKey = 'calories_target'; // int
  static const String _standingTimeTargetMinKey =
      'standing_time_target_min'; // int minutes
  static const String _sleepTargetHoursKey =
      'sleep_target_hours'; // double hours
  static const String _applyTargetsToTodayKey =
      'apply_targets_to_today'; // bool
  // Workout weekly progress
  static const String _workoutCurrentDayIndexKey =
      'workout_current_day_index'; // int (1-based)

  // Replacement for Hive Box
  static final _MemoryBox _userBox = _MemoryBox(_userBoxName);

  final SupabaseClient _supabase = Supabase.instance.client;
  static bool _listenersStarted = false;
  StreamSubscription<bool>? _connSub;
  StreamSubscription<AuthState>? _authSub;

  UserService() {
    _initHive();
  }

  Future<void> _initHive() async {
    // No-op for memory box
  }

  _MemoryBox get _getUserBox {
    return _userBox;
  }

  // Start background sync listeners for auth and connectivity
  Future<void> startSyncListeners() async {
    if (_listenersStarted) return;
    _listenersStarted = true;

    // Connectivity changes
    _connSub = ConnectivityService().onlineChanges.listen((isOnline) async {
      if (isOnline) await _attemptBackgroundSync();
    });

    // Auth changes
    _authSub = _supabase.auth.onAuthStateChange.listen((event) async {
      await _attemptBackgroundSync();
    });

    // Initial attempt
    await _attemptBackgroundSync();
  }

  // Request Apple Health permissions on first app launch (iOS only)
  Future<void> requestHealthPermissionsAtFirstLaunch() async {
    // Only request on iOS devices (not web, not Android)
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    try {
      final box = _getUserBox;
      final prompted =
          box.get(_healthPermissionPromptedKey, defaultValue: false) == true;
      if (prompted) return;

      final health = HealthService();
      var granted = await health.hasPermissions();
      if (!granted) {
        await health.requestPermissions();
      }
      await box.put(_healthPermissionPromptedKey, true);
    } catch (e) {
      try {
        final box = _getUserBox;
        await box.put(_healthPermissionPromptedKey, true);
      } catch (_) {}
      print('Health permission prompt error: $e');
    }
  }

  Future<void> _attemptBackgroundSync() async {
    try {
      final online = await ConnectivityService().isOnline();
      if (!online) return;
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final box = _getUserBox;
      final isDirty = box.get(_surveyDirtyKey, defaultValue: false) == true;
      final hasLocalSurvey = box.get('survey_data') != null;
      if (!isDirty && !hasLocalSurvey) return;

      await syncLocalSurveyToSupabase();
      await box.put(_surveyDirtyKey, false);
    } catch (_) {}
  }

  // Check if user has completed onboarding
  Future<bool> isOnboardingComplete() async {
    // Check local storage as fast path
    try {
      final box = _getUserBox;
      final localComplete = box.get(_onboardingKey, defaultValue: false);
      if (localComplete == true) return true;
    } catch (e) {
      print('Error checking onboarding status: $e');
    }

    // If not found locally, try Supabase profile flag (optional)
    try {
      final uid = _supabase.auth.currentUser?.id;
      if (uid == null) return false;
      final resp = await _supabase
          .from('user_identity')
          .select('id')
          .eq('user_id', uid)
          .maybeSingle();
      return resp != null; // treat existing row as onboarded
    } catch (_) {
      return false;
    }
  }

  // Mark onboarding as complete (local flag)
  Future<void> markOnboardingComplete() async {
    final box = _getUserBox;
    await box.put(_onboardingKey, true);
  }

  // Create or update user_identity from sign up details
  Future<void> createOrUpdateUserIdentityFromSignup({
    required String email,
    required String userName,
    String? phone,
  }) async {
    try {
      // Prefer linking the row created during survey by stored id
      final box = _getUserBox;
      final existingLocalId = box.get(_userIdentityIdKey) as int?;
      if (existingLocalId != null) {
        await _supabase
            .from('user_identity')
            .update({
              'email': email,
              'user_name': userName,
              if (phone != null && phone.isNotEmpty) 'phone': phone,
              if (_supabase.auth.currentUser?.id != null)
                'user_id': _supabase.auth.currentUser!.id,
            })
            .eq('id', existingLocalId);
        return;
      }

      final uid = _supabase.auth.currentUser?.id;

      // 1. Try to update by user_id (if we have one)
      if (uid != null) {
        final updatedByUid = await _supabase
            .from('user_identity')
            .update({
              'email': email,
              'user_name': userName,
              if (phone != null && phone.isNotEmpty) 'phone': phone,
            })
            .eq('user_id', uid)
            .select();

        if (updatedByUid.isNotEmpty) return;
      }

      // 2. Try to update by email (claim existing row)
      final updatedByEmail = await _supabase
          .from('user_identity')
          .update({
            'user_name': userName,
            if (uid != null) 'user_id': uid,
            if (phone != null && phone.isNotEmpty) 'phone': phone,
          })
          .eq('email', email)
          .select();

      if (updatedByEmail.isNotEmpty) return;

      // 3. Insert (Upsert to handle race conditions on user_id)
      await _supabase.from('user_identity').upsert({
        'email': email,
        'user_name': userName,
        if (uid != null) 'user_id': uid,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      }, onConflict: 'user_id');
    } catch (e) {
      print('Error syncing user_identity (signup): $e');
    }
  }

  // ---- Workout progress (local) ----
  Future<int> getWorkoutCurrentDayIndex() async {
    final box = _getUserBox;
    final idx = box.get(_workoutCurrentDayIndexKey, defaultValue: 1);
    if (idx is int && idx >= 1) return idx;
    return 1;
  }

  Future<void> setWorkoutCurrentDayIndex(int index) async {
    final box = _getUserBox;
    await box.put(_workoutCurrentDayIndexKey, index < 1 ? 1 : index);
  }

  // Save survey data
  Future<void> saveSurveyData(Map<String, dynamic> surveyData) async {
    try {
      // Persist locally for offline reads
      final box = _getUserBox;
      await box.put('survey_data', surveyData);
      await box.put(_onboardingKey, true);
      await box.put(_surveyDirtyKey, true);
      print('Survey data saved locally');

      // If not authenticated or offline, stop here. We'll sync later.
      final user = _supabase.auth.currentUser;
      final online = await ConnectivityService().isOnline();
      if (user == null || !online) {
        return;
      }

      // Build payload mapped to user_identity columns
      final payload = <String, dynamic>{
        if (surveyData['name'] != null) 'user_name': surveyData['name'],
        if (surveyData['age'] != null)
          'age': (surveyData['age'] as num?)?.toInt(),
        if (surveyData['gender'] != null) 'gender': surveyData['gender'],
        if (surveyData['height'] != null)
          'height': (surveyData['height'] as num?)?.toDouble(),
        if (surveyData['weight'] != null)
          'weight': (surveyData['weight'] as num?)?.toDouble(),
        if (surveyData['activity_level'] != null)
          'activity_level': surveyData['activity_level'],
      };

      // Insert or update on Supabase; if user exists, include identifiers
      try {
        if (user.email?.isNotEmpty == true) payload['email'] = user.email;
        if (user.id.isNotEmpty) payload['user_id'] = user.id;

        // Deterministic update by user_id, else insert
        Map<String, dynamic>? resp;
        try {
          final existingByUid = await _supabase
              .from('user_identity')
              .select('id')
              .eq('user_id', user.id)
              .maybeSingle();
          if (existingByUid != null && existingByUid['id'] != null) {
            resp = await _supabase
                .from('user_identity')
                .update(payload)
                .eq('user_id', user.id)
                .select('id')
                .maybeSingle();
          } else {
            resp = await _supabase
                .from('user_identity')
                .insert(payload)
                .select('id')
                .maybeSingle();
          }
        } catch (e) {
          print('Error during survey update/insert: $e');
          rethrow;
        }
        if (resp != null && resp['id'] != null) {
          await box.put(_userIdentityIdKey, resp['id'] as int);
          await box.put(_surveyDirtyKey, false);
        }
      } catch (e) {
        print('Supabase survey upsert failed (non-fatal): $e');
      }
    } catch (e) {
      print('Error saving survey data: $e');
    }
  }

  // Sync previously saved local survey data to Supabase after user logs in
  Future<void> syncLocalSurveyToSupabase() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return; // requires authenticated session

      final box = _getUserBox;
      final surveyData = box.get('survey_data');
      if (surveyData == null) return; // nothing to sync

      // Normalize to Map<String, dynamic>
      final Map<String, dynamic> sd = surveyData is Map
          ? Map<String, dynamic>.from(
              surveyData.map((k, v) => MapEntry(k.toString(), v)),
            )
          : {};

      final payload = <String, dynamic>{
        if (sd['name'] != null) 'user_name': sd['name'],
        if (sd['age'] != null) 'age': (sd['age'] as num?)?.toInt(),
        if (sd['gender'] != null) 'gender': sd['gender'],
        if (sd['height'] != null) 'height': (sd['height'] as num?)?.toDouble(),
        if (sd['weight'] != null) 'weight': (sd['weight'] as num?)?.toDouble(),
        if (sd['activity_level'] != null)
          'activity_level': sd['activity_level'],
        // 'health_conditions' column no longer used in user_identity
        // identifiers
        'user_id': user.id,
        if (user.email?.isNotEmpty == true) 'email': user.email,
      };

      // Prefer deterministic update by user_id, then insert if missing
      Map<String, dynamic>? resp;
      try {
        final existingByUid = await _supabase
            .from('user_identity')
            .select('id')
            .eq('user_id', user.id)
            .maybeSingle();
        if (existingByUid != null && existingByUid['id'] is int) {
          resp = await _supabase
              .from('user_identity')
              .update(payload)
              .eq('user_id', user.id)
              .select('id')
              .maybeSingle();
        } else {
          resp = await _supabase
              .from('user_identity')
              .insert(payload)
              .select('id')
              .maybeSingle();
        }
      } catch (e) {
        // Log error instead of retrying with problematic upsert
        print('Error during survey sync update/insert: $e');
        rethrow;
      }

      if (resp != null && resp['id'] is int) {
        await box.put(_userIdentityIdKey, resp['id'] as int);
        await box.put(_surveyDirtyKey, false);
      }
    } catch (e) {
      print('Error syncing local survey to Supabase: $e');
    }
  }

  // Get user profile data (Supabase first, fallback to local)
  Future<Map<String, dynamic>?> getUserProfile() async {
    final box = _getUserBox;
    try {
      Map<String, dynamic>? row;

      final uid = _supabase.auth.currentUser?.id;
      if (uid != null && uid.isNotEmpty) {
        final resp = await _supabase
            .from('user_identity')
            .select(
              'id,user_name,age,gender,height,weight,activity_level,email',
            )
            .eq('user_id', uid)
            .maybeSingle();
        if (resp != null) {
          row = Map<String, dynamic>.from(resp);
          final id = row['id'];
          if (id is int) {
            await box.put(_userIdentityIdKey, id);
          }
        }
      } else {
        // Not logged in: try using stored Supabase id from survey
        final localId = box.get(_userIdentityIdKey) as int?;
        if (localId != null) {
          final resp = await _supabase
              .from('user_identity')
              .select(
                'id,user_name,age,gender,height,weight,activity_level,email',
              )
              .eq('id', localId)
              .maybeSingle();
          if (resp != null) {
            row = Map<String, dynamic>.from(resp);
          }
        }
      }

      if (row != null) {
        final survey = <String, dynamic>{
          'name': row['user_name'],
          'age': row['age'],
          'gender': row['gender'],
          'height': row['height'],
          'weight': row['weight'],
          'activity_level': row['activity_level'],
          // 'health_conditions' not selected from user_identity
        };
        // Cache locally for faster subsequent reads
        await box.put('survey_data', survey);
        return {'survey_data': survey};
      }
    } catch (e) {
      print('Error fetching user profile from Supabase: $e');
    }

    // Fallback to local cache
    try {
      final surveyData = box.get('survey_data');
      if (surveyData != null) {
        if (surveyData is Map) {
          final typed = Map<String, dynamic>.from(
            surveyData.map((key, value) => MapEntry(key.toString(), value)),
          );
          return {'survey_data': typed};
        }
        return {'survey_data': surveyData};
      }
    } catch (e) {
      print('Error fetching user profile (local): $e');
    }
    return null;
  }

  // Clear local user data (for logout)
  Future<void> clearLocalData() async {
    final box = _getUserBox;
    await box.clear();
  }

  // Nutrition goal preferences
  Future<String> getNutritionGoal() async {
    final box = _getUserBox;
    return (box.get(_nutritionGoalKey) as String?) ?? 'maintain';
  }

  Future<void> setNutritionGoal(String goal) async {
    final box = _getUserBox;
    await box.put(_nutritionGoalKey, goal);
  }

  Future<int> getNutritionGoalDelta() async {
    final box = _getUserBox;
    final v = box.get(_nutritionGoalDeltaKey);
    if (v is int) return v;
    if (v is num) return v.toInt();
    return 15;
  }

  Future<void> setNutritionGoalDelta(int percent) async {
    final box = _getUserBox;
    await box.put(_nutritionGoalDeltaKey, percent);
  }

  // Daily targets: steps, calories, water, sleep
  Future<int> getStepsTarget() async {
    final box = _getUserBox;
    final v = box.get(_stepsTargetKey);
    if (v is int) return v;
    if (v is num) return v.toInt();
    return 10000; // default steps
  }

  Future<void> setStepsTarget(int steps) async {
    final box = _getUserBox;
    await box.put(_stepsTargetKey, steps);
  }

  Future<int> getCaloriesTarget() async {
    final box = _getUserBox;
    final v = box.get(_caloriesTargetKey);
    if (v is int) return v;
    if (v is num) return v.toInt();
    return 2200; // default kcal
  }

  Future<void> setCaloriesTarget(int kcal) async {
    final box = _getUserBox;
    await box.put(_caloriesTargetKey, kcal);
  }

  Future<int> getStandingTimeTargetMinutes() async {
    final box = _getUserBox;
    final v = box.get(_standingTimeTargetMinKey);
    if (v is int) return v;
    if (v is num) return v.round();
    return 720; // default 12 hours (720 minutes) standing goal - Apple Watch standard
  }

  Future<void> setStandingTimeTargetMinutes(int minutes) async {
    final box = _getUserBox;
    await box.put(_standingTimeTargetMinKey, minutes);
  }

  Future<double> getSleepTargetHours() async {
    final box = _getUserBox;
    final v = box.get(_sleepTargetHoursKey);
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return 8.0; // default hours
  }

  Future<void> setSleepTargetHours(double hours) async {
    final box = _getUserBox;
    await box.put(_sleepTargetHoursKey, hours);
  }

  // Preference: apply targets to today's record automatically
  Future<bool> getApplyTargetsToToday() async {
    final box = _getUserBox;
    final v = box.get(_applyTargetsToTodayKey);
    if (v is bool) return v;
    return false;
  }

  Future<void> setApplyTargetsToToday(bool enabled) async {
    final box = _getUserBox;
    await box.put(_applyTargetsToTodayKey, enabled);
  }

  // Check if user profile exists in Supabase
  Future<bool> doesUserProfileExist() async {
    try {
      final uid = _supabase.auth.currentUser?.id;
      if (uid == null) return false;
      final existing = await _supabase
          .from('user_identity')
          .select('id')
          .eq('user_id', uid)
          .maybeSingle();
      if (existing != null) return true;
      // fallback to local check
      final box = _getUserBox;
      final surveyData = box.get('survey_data');
      return surveyData != null;
    } catch (e) {
      return false;
    }
  }

  // Debug: print user box path and contents
  Future<void> debugPrintStorageInfo() async {
    try {
      final box = _getUserBox;

      // Box metadata
      print('MemoryBox name: ${box.name}');
      print('MemoryBox length: ${box.length}');

      // Print keys and values
      for (final key in box.keys) {
        final value = box.get(key);
        print('MemoryBox entry -> $key: $value');
      }
    } catch (e) {
      print('Error printing MemoryBox debug info: $e');
    }
  }
}

/// A simple in-memory replacement for Hive Box
class _MemoryBox {
  final String name;
  final Map<dynamic, dynamic> _data = {};

  _MemoryBox(this.name);

  dynamic get(dynamic key, {dynamic defaultValue}) {
    return _data.containsKey(key) ? _data[key] : defaultValue;
  }

  Future<void> put(dynamic key, dynamic value) async {
    _data[key] = value;
  }

  Future<void> clear() async {
    _data.clear();
  }

  Iterable<dynamic> get keys => _data.keys;
  Iterable<dynamic> get values => _data.values;
  int get length => _data.length;

  // Mock path for debug compatibility
  String? get path => 'memory://$name';
}
