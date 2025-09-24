import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
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

  Box? _userBox;
  final SupabaseClient _supabase = Supabase.instance.client;
  static bool _listenersStarted = false;
  StreamSubscription<bool>? _connSub;
  StreamSubscription<AuthState>? _authSub;

  UserService() {
    _initHive();
  }

  Future<void> _initHive() async {
    try {
      await Hive.initFlutter();
      _userBox = await Hive.openBox(_userBoxName);
    } catch (e) {
      print('Error initializing Hive: $e');
    }
  }

  Future<Box> get _getUserBox async {
    if (_userBox == null) {
      await _initHive();
    }
    return _userBox!;
  }

  // Start background sync listeners for auth and connectivity
  Future<void> startSyncListeners() async {
    if (_listenersStarted) return;
    _listenersStarted = true;
    await _initHive();

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
      final box = await _getUserBox;
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
        final box = await _getUserBox;
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

      final box = await _getUserBox;
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
      final box = await _getUserBox;
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
    final box = await _getUserBox;
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
      final box = await _getUserBox;
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

      // Try to find existing row by user_id first, then by email
      final uid = _supabase.auth.currentUser?.id;
      if (uid != null) {
        final existingByUid = await _supabase
            .from('user_identity')
            .select('id')
            .eq('user_id', uid)
            .maybeSingle();
        if (existingByUid != null) {
          await _supabase
              .from('user_identity')
              .update({
                'email': email,
                'user_name': userName,
                if (phone != null && phone.isNotEmpty) 'phone': phone,
              })
              .eq('user_id', uid);
          return;
        }
      }

      // Fallback: find by email
      final existing = await _supabase
          .from('user_identity')
          .select('id')
          .eq('email', email)
          .maybeSingle();

      if (existing == null) {
        await _supabase.from('user_identity').insert({
          'user_name': userName,
          'email': email,
          if (uid != null) 'user_id': uid,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
        });
      } else {
        await _supabase
            .from('user_identity')
            .update({
              'user_name': userName,
              if (phone != null && phone.isNotEmpty) 'phone': phone,
            })
            .eq('email', email);
      }
    } catch (e) {
      print('Error syncing user_identity (signup): $e');
    }
  }

  // Save survey data
  Future<void> saveSurveyData(Map<String, dynamic> surveyData) async {
    try {
      // Persist locally for offline reads
      final box = await _getUserBox;
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
        if (surveyData['health_conditions'] != null)
          'health_conditions': surveyData['health_conditions'],
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
        } catch (_) {
          // Fallback to upsert for rare races
          resp = await _supabase
              .from('user_identity')
              .upsert(payload, onConflict: 'user_id')
              .select('id')
              .maybeSingle();
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

      final box = await _getUserBox;
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
        if (sd['health_conditions'] != null)
          'health_conditions': sd['health_conditions'],
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
        // Fallback to upsert in case of race condition
        resp = await _supabase
            .from('user_identity')
            .upsert(payload, onConflict: 'user_id')
            .select('id')
            .maybeSingle();
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
    final box = await _getUserBox;
    try {
      Map<String, dynamic>? row;

      final uid = _supabase.auth.currentUser?.id;
      if (uid != null && uid.isNotEmpty) {
        final resp = await _supabase
            .from('user_identity')
            .select(
              'id,user_name,age,gender,height,weight,activity_level,health_conditions,email',
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
                'id,user_name,age,gender,height,weight,activity_level,health_conditions,email',
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
          'health_conditions': row['health_conditions'],
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
    final box = await _getUserBox;
    await box.clear();
  }

  // Nutrition goal preferences
  Future<String> getNutritionGoal() async {
    final box = await _getUserBox;
    return (box.get(_nutritionGoalKey) as String?) ?? 'maintain';
  }

  Future<void> setNutritionGoal(String goal) async {
    final box = await _getUserBox;
    await box.put(_nutritionGoalKey, goal);
  }

  Future<int> getNutritionGoalDelta() async {
    final box = await _getUserBox;
    final v = box.get(_nutritionGoalDeltaKey);
    if (v is int) return v;
    if (v is num) return v.toInt();
    return 15;
  }

  Future<void> setNutritionGoalDelta(int percent) async {
    final box = await _getUserBox;
    await box.put(_nutritionGoalDeltaKey, percent);
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
      final box = await _getUserBox;
      final surveyData = box.get('survey_data');
      return surveyData != null;
    } catch (e) {
      return false;
    }
  }

  // Debug: print Hive user box path and contents
  Future<void> debugPrintHiveInfo() async {
    try {
      final box = await _getUserBox;

      // Box metadata
      print('Hive box name: ${box.name}');
      print('Hive box length: ${box.length}');

      // Try to print underlying filesystem path when available (not on web)
      try {
        // Box.path exists on supported platforms. On web this may throw.
        final dynamic b = box; // avoid hard dependency if path is absent
        final path = b.path as String?; // may be null on some platforms
        if (path != null) {
          print('Hive box path: $path');
        } else {
          print(
            'Hive storage path: <not available> (web/IndexedDB or unsupported)',
          );
        }
      } catch (_) {
        print(
          'Hive storage path: <not available> (web/IndexedDB or unsupported)',
        );
      }

      // Print keys and values
      for (final key in box.keys) {
        final value = box.get(key);
        print('Hive entry -> $key: $value');
      }
    } catch (e) {
      print('Error printing Hive debug info: $e');
    }
  }
}
