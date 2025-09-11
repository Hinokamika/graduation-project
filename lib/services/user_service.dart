import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserService {
  static const String _userBoxName = 'userBox';
  static const String _onboardingKey = 'onboardingComplete';
  static const String _userIdentityIdKey = 'user_identity_id';

  Box? _userBox;
  final SupabaseClient _supabase = Supabase.instance.client;

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
        await _supabase.from('user_identity').update({
          'email': email,
          'user_name': userName,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          if (_supabase.auth.currentUser?.id != null) 'user_id': _supabase.auth.currentUser!.id,
        }).eq('id', existingLocalId);
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
          await _supabase.from('user_identity').update({
            'email': email,
            'user_name': userName,
            if (phone != null && phone.isNotEmpty) 'phone': phone,
          }).eq('user_id', uid);
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
        await _supabase.from('user_identity').update({
          'user_name': userName,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
        }).eq('email', email);
      }
    } catch (e) {
      print('Error syncing user_identity (signup): $e');
    }
  }

  // Save survey data
  Future<void> saveSurveyData(Map<String, dynamic> surveyData) async {
    final user = _supabase.auth.currentUser;
    try {
      // Persist locally for offline reads
      final box = await _getUserBox;
      await box.put('survey_data', surveyData);
      await box.put(_onboardingKey, true);
      print('Survey data saved locally');

      // Build payload mapped to user_identity columns
      final payload = <String, dynamic>{
        if (surveyData['name'] != null) 'user_name': surveyData['name'],
        if (surveyData['age'] != null) 'age': (surveyData['age'] as num?)?.toInt(),
        if (surveyData['gender'] != null) 'gender': surveyData['gender'],
        if (surveyData['height'] != null) 'height': (surveyData['height'] as num?)?.toInt(),
        if (surveyData['weight'] != null) 'weight': (surveyData['weight'] as num?)?.toInt(),
        if (surveyData['activity_level'] != null)
          'activity_level': surveyData['activity_level'],
        if (surveyData['health_conditions'] != null)
          'health_conditional': surveyData['health_conditions'],
      };

      // Insert or update on Supabase; if user exists, include identifiers
      try {
        if (user != null) {
          if (user.email?.isNotEmpty == true) payload['email'] = user.email;
          if (user.id.isNotEmpty) payload['user_id'] = user.id;
        }

        final existingId = box.get(_userIdentityIdKey) as int?;
        if (existingId != null) {
          await _supabase
              .from('user_identity')
              .update(payload)
              .eq('id', existingId);
        } else if (payload.containsKey('user_id')) {
          final upserted = await _supabase
              .from('user_identity')
              .upsert(payload, onConflict: 'user_id')
              .select('id')
              .maybeSingle();
          if (upserted != null && upserted['id'] != null) {
            await box.put(_userIdentityIdKey, upserted['id'] as int);
          }
        } else {
          final inserted = await _supabase
              .from('user_identity')
              .insert(payload)
              .select('id')
              .maybeSingle();
          if (inserted != null && inserted['id'] != null) {
            await box.put(_userIdentityIdKey, inserted['id'] as int);
          }
        }
      } catch (e) {
        print('Supabase survey upsert failed (non-fatal): $e');
      }
    } catch (e) {
      print('Error saving survey data: $e');
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
            .select('id,user_name,age,gender,height,weight,activity_level,health_conditional,email')
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
              .select('id,user_name,age,gender,height,weight,activity_level,health_conditional,email')
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
          'health_conditions': row['health_conditional'],
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
}
