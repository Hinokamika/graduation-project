import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:final_project/utils/app_colors.dart';
import 'package:final_project/utils/text_styles.dart';
import 'package:final_project/services/user_service.dart';
import 'package:final_project/services/auth_service.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  final UserService _userService = UserService();
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService();

  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userProfile = await _userService.getUserProfile();
      final user = _supabase.auth.currentUser;

      // Fetch saved plans (best-effort; ignore if schema not ready)
      Map<String, dynamic>? workoutPlan;
      Map<String, dynamic>? relaxPlan;
      List<Map<String, dynamic>> mealDays = [];
      if (user != null) {
        try {
          workoutPlan = await _supabase
              .from('workout_plan')
              .select('id,exercise_name,description,difficulty_level,exercise_category,created_at')
              .eq('user_id', user.id)
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();
        } catch (_) {
          try {
            workoutPlan = await _supabase
                .from('workout_plan')
                .select('id,exercise_name,description,difficulty_level,exercise_category')
                .eq('user_id', user.id)
                .order('id', ascending: false)
                .limit(1)
                .maybeSingle();
          } catch (_) {}
        }
        try {
          relaxPlan = await _supabase
              .from('relax_plan')
              .select('id,title,description,relaxation_type')
              .eq('user_id', user.id)
              .order('id', ascending: false)
              .limit(1)
              .maybeSingle();
        } catch (_) {}
        try {
          final resp = await _supabase
              .from('meal_plan')
              .select('day_index,day_label,meals,snacks')
              .eq('user_id', user.id)
              .order('day_index', ascending: true);
          if (resp is List) {
            mealDays = List<Map<String, dynamic>>.from(resp);
          }
        } catch (_) {}
      }

      setState(() {
        _userData = {
          ...?userProfile,
          'email': user?.email,
          // Prefer values from Supabase user_metadata if present
          'display_name': _extractDisplayName(user),
          'photo_url': _extractPhotoUrl(user),
          if (workoutPlan != null) 'workout_plan': workoutPlan,
          if (relaxPlan != null) 'relax_plan': relaxPlan,
          if (mealDays.isNotEmpty) 'meal_plan_days': mealDays,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading user data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Profile', style: AppTextStyles.heading3),
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: FaIcon(
            FontAwesomeIcons.arrowLeft,
            color: Theme.of(context).colorScheme.onSurface,
            size: 18,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  _buildProfileHeader(),

                  const SizedBox(height: 32),

                  // User Information
                  _buildUserInfoSection(),

                  const SizedBox(height: 32),

                  // Health Data
                  if (_userData?['survey_data'] != null) ...[
                    _buildHealthDataSection(),
                    const SizedBox(height: 32),
                  ],

                  // Saved Plans
                  if (_userData?['workout_plan'] != null ||
                      _userData?['relax_plan'] != null ||
                      (_userData?['meal_plan_days'] is List &&
                          (_userData?['meal_plan_days'] as List).isNotEmpty)) ...[
                    _buildSavedPlansSection(),
                    const SizedBox(height: 32),
                  ],

                  // Account Actions
                  _buildAccountActions(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    final user = _supabase.auth.currentUser;

    String? surveyName;
    final dynamic surveyRaw = _userData?['survey_data'];
    if (surveyRaw is Map) {
      final nameValue = surveyRaw['name'];
      if (nameValue is String && nameValue.trim().isNotEmpty) {
        surveyName = nameValue;
      }
    }

    final displayName = _extractDisplayName(user) ?? surveyName ?? 'User';
    final photoUrl =
        _extractPhotoUrl(user) ?? (_userData?['photo_url'] as String?);

    return Center(
      child: Column(
        children: [
          // Profile Picture
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.healthSecondary,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 2,
              ),
            ),
            child: photoUrl != null && photoUrl.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const FaIcon(
                          FontAwesomeIcons.user,
                          color: AppColors.healthPrimary,
                          size: 36,
                        );
                      },
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 31, vertical: 24),
                  child: const FaIcon(
                      FontAwesomeIcons.user,
                      color: AppColors.healthPrimary,
                      size: 36,
                    ),
                ),
          ),

          const SizedBox(height: 16),

          // User Name
          Text(
            displayName,
            style: AppTextStyles.title.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 8),

          // User Email
          Text(
            user?.email ?? '',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account Information',
          style: AppTextStyles.subtitle.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),

        const SizedBox(height: 16),

        // Email
        _buildInfoTile(
          icon: FontAwesomeIcons.envelope,
          title: 'Email',
          value: _supabase.auth.currentUser?.email ?? 'Not available',
        ),

        const SizedBox(height: 12),

        // Member Since
        _buildInfoTile(
          icon: FontAwesomeIcons.calendar,
          title: 'Member Since',
          value: _formatDate(_supabase.auth.currentUser?.createdAt),
        ),

        const SizedBox(height: 12),

        // Last Login
        _buildInfoTile(
          icon: FontAwesomeIcons.clock,
          title: 'Last Login',
          value: _formatDate(_supabase.auth.currentUser?.lastSignInAt),
        ),
      ],
    );
  }

  Widget _buildHealthDataSection() {
    final dynamic rawSurvey = _userData?['survey_data'];
    final Map<String, dynamic>? surveyData = rawSurvey is Map
        ? Map<String, dynamic>.from(
            rawSurvey.map((k, v) => MapEntry(k.toString(), v)),
          )
        : null;
    final data = surveyData;
    String? ageStr;
    String? genderStr;
    String? heightWeightStr;
    String? activityStr;
    String? conditionsStr;

    if (data != null) {
      final age = data['age'];
      if (age != null) ageStr = '$age years';

      final gender = data['gender'];
      if (gender != null) genderStr = '$gender';

      final height = data['height'];
      final weight = data['weight'];
      if (height != null && weight != null) {
        heightWeightStr = '$height cm, $weight kg';
      }

      final act = data['activity_level'];
      if (act != null) activityStr = '$act';

      final hc = data['health_conditions'];
      if (hc is List && hc.isNotEmpty) {
        conditionsStr = hc.join(', ');
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Health Information',
          style: AppTextStyles.subtitle.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),

        const SizedBox(height: 16),

        // Age
        if (ageStr != null)
          _buildInfoTile(
            icon: FontAwesomeIcons.cakeCandles,
            title: 'Age',
            value: ageStr,
          ),

        const SizedBox(height: 12),

        // Gender
        if (genderStr != null)
          _buildInfoTile(
            icon: FontAwesomeIcons.venusMars,
            title: 'Gender',
            value: genderStr,
          ),

        const SizedBox(height: 12),

        // Height & Weight
        if (heightWeightStr != null)
          _buildInfoTile(
            icon: FontAwesomeIcons.rulerVertical,
            title: 'Height & Weight',
            value: heightWeightStr,
          ),

        const SizedBox(height: 12),

        // Activity Level
        if (activityStr != null)
          _buildInfoTile(
            icon: FontAwesomeIcons.personRunning,
            title: 'Activity Level',
            value: activityStr,
          ),

        const SizedBox(height: 12),

        // Health Conditions
        if (conditionsStr != null)
          _buildInfoTile(
            icon: FontAwesomeIcons.notesMedical,
            title: 'Health Conditions',
            value: conditionsStr,
          ),
      ],
    );
  }

  Widget _buildAccountActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account Actions',
          style: AppTextStyles.subtitle.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),

        const SizedBox(height: 16),

        // Edit Profile Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () {
              // TODO: Implement edit profile functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Edit profile feature coming soon!'),
                ),
              );
            },
            child: Text(
              'Edit Profile',
              style: AppTextStyles.button.copyWith(color: Colors.white),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Logout Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: BorderSide(color: AppColors.error),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: _handleLogout,
            child: Text(
              'Log Out',
              style: AppTextStyles.button.copyWith(color: AppColors.error),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSavedPlansSection() {
    final wp = _userData?['workout_plan'] as Map<String, dynamic>?;
    final rp = _userData?['relax_plan'] as Map<String, dynamic>?;
    final meals = (_userData?['meal_plan_days'] is List)
        ? List<Map<String, dynamic>>.from(
            _userData!['meal_plan_days'] as List,
          )
        : <Map<String, dynamic>>[];

    String? wpSummary;
    if (wp != null) {
      final name = (wp['exercise_name'] ?? 'Workout Plan').toString();
      final diff = (wp['difficulty_level'] ?? '').toString();
      final cat = (wp['exercise_category'] ?? '').toString();
      final tags = [if (diff.isNotEmpty) diff, if (cat.isNotEmpty) cat].join(' • ');
      wpSummary = tags.isNotEmpty ? '$name — $tags' : name;
    }

    String? rpSummary;
    if (rp != null) {
      final title = (rp['title'] ?? 'Relax Plan').toString();
      final rtype = (rp['relaxation_type'] ?? '').toString();
      rpSummary = rtype.isNotEmpty ? '$title — $rtype' : title;
    }

    String? mealSummary;
    if (meals.isNotEmpty) {
      final count = meals.length;
      mealSummary = '$count day${count == 1 ? '' : 's'} saved';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Saved Plans',
          style: AppTextStyles.subtitle.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        if (wpSummary != null)
          _buildInfoTile(
            icon: FontAwesomeIcons.dumbbell,
            title: 'Workout Plan',
            value: wpSummary,
          ),
        if (wpSummary != null) const SizedBox(height: 12),
        if (rpSummary != null)
          _buildInfoTile(
            icon: FontAwesomeIcons.spa,
            title: 'Relax Plan',
            value: rpSummary,
          ),
        if (rpSummary != null) const SizedBox(height: 12),
        if (mealSummary != null)
          _buildInfoTile(
            icon: FontAwesomeIcons.utensils,
            title: 'Meal Plan',
            value: mealSummary,
          ),
      ],
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.accent, size: 20),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.label.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic dateOrIsoString) {
    if (dateOrIsoString == null) return 'Not available';
    DateTime? dt;
    if (dateOrIsoString is DateTime) {
      dt = dateOrIsoString;
    } else if (dateOrIsoString is String) {
      dt = DateTime.tryParse(dateOrIsoString);
    }
    if (dt == null) return 'Not available';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Future<void> _handleLogout() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Clear local user data
        await _userService.clearLocalData();

        // Sign out from Supabase
        await _authService.signOut();

        // Navigate to login page
        if (mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error logging out: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Helpers to safely read name and avatar from Supabase user_metadata
  String? _extractDisplayName(User? user) {
    final dynamic raw = user?.userMetadata;
    if (raw is Map) {
      final meta = Map<String, dynamic>.from(raw);
      final dynamic candidate =
          meta['full_name'] ?? meta['display_name'] ?? meta['name'];
      if (candidate is String && candidate.trim().isNotEmpty) {
        return candidate;
      }
    }
    return null;
  }

  String? _extractPhotoUrl(User? user) {
    final dynamic raw = user?.userMetadata;
    if (raw is Map) {
      final meta = Map<String, dynamic>.from(raw);
      final dynamic candidate =
          meta['avatar_url'] ?? meta['picture'] ?? meta['photo_url'];
      if (candidate is String && candidate.trim().isNotEmpty) {
        return candidate;
      }
    }
    return null;
  }
}
