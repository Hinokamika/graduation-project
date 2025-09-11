import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:final_project/utils/app_colors.dart';
import 'package:final_project/utils/text_styles.dart';
import 'package:final_project/services/user_service.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  final UserService _userService = UserService();
  final SupabaseClient _supabase = Supabase.instance.client;
  
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
      
      setState(() {
        _userData = {
          ...?userProfile,
          'email': user?.email,
          'display_name': user?.displayName,
          'photo_url': user?.photoURL,
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Profile', style: AppTextStyles.heading3),
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: Icon(
            CupertinoIcons.back,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
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
                  
                  // Account Actions
                  _buildAccountActions(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    final user = _supabase.auth.currentUser;
    
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
                color: AppColors.divider,
                width: 2,
              ),
            ),
            child: user?.photoURL != null
                ? ClipOval(
                    child: Image.network(
                      user!.photoURL!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.person_outline,
                          color: AppColors.healthPrimary,
                          size: 40,
                        );
                      },
                    ),
                  )
                : Icon(
                    Icons.person_outline,
                    color: AppColors.healthPrimary,
                    size: 40,
                  ),
          ),
          
          const SizedBox(height: 16),
          
          // User Name
          Text(
            user?.displayName ?? _userData?['survey_data']?['name'] ?? 'User',
            style: AppTextStyles.title.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // User Email
          Text(
            user?.email ?? '',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
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
            color: AppColors.textPrimary,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Email
        _buildInfoTile(
          icon: Icons.email_outlined,
          title: 'Email',
          value: _supabase.auth.currentUser?.email ?? 'Not available',
        ),
        
        const SizedBox(height: 12),
        
        // Member Since
        _buildInfoTile(
          icon: Icons.calendar_today_outlined,
          title: 'Member Since',
          value: _formatDate(_supabase.auth.currentUser?.createdAt),
        ),
        
        const SizedBox(height: 12),
        
        // Last Login
        _buildInfoTile(
          icon: Icons.access_time_outlined,
          title: 'Last Login',
          value: _formatDate(_supabase.auth.currentSession?.createdAt),
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
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Health Information',
          style: AppTextStyles.subtitle.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Age
        if (surveyData?['age'] != null)
          _buildInfoTile(
            icon: Icons.cake_outlined,
            title: 'Age',
            value: '${surveyData!['age']} years',
          ),
        
        const SizedBox(height: 12),
        
        // Gender
        if (surveyData?['gender'] != null)
          _buildInfoTile(
            icon: Icons.wc_outlined,
            title: 'Gender',
            value: surveyData!['gender'],
          ),
        
        const SizedBox(height: 12),
        
        // Height & Weight
        if (surveyData?['height'] != null && surveyData?['weight'] != null)
          _buildInfoTile(
            icon: Icons.height_outlined,
            title: 'Height & Weight',
            value: '${surveyData!['height']} cm, ${surveyData!['weight']} kg',
          ),
        
        const SizedBox(height: 12),
        
        // Activity Level
        if (surveyData?['activity_level'] != null)
          _buildInfoTile(
            icon: Icons.directions_run_outlined,
            title: 'Activity Level',
            value: surveyData!['activity_level'],
          ),
        
        const SizedBox(height: 12),
        
        // Health Conditions
        if (surveyData?['health_conditions'] != null &&
            (surveyData!['health_conditions'] as List).isNotEmpty)
          _buildInfoTile(
            icon: Icons.medical_information_outlined,
            title: 'Health Conditions',
            value: (surveyData!['health_conditions'] as List).join(', '),
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
            color: AppColors.textPrimary,
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
              style: AppTextStyles.button.copyWith(
                color: Colors.white,
              ),
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
              style: AppTextStyles.button.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
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
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
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
            child: Icon(
              icon,
              color: AppColors.accent,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not available';
    return '${date.day}/${date.month}/${date.year}';
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
        
        // Sign out from Firebase
        await _auth.signOut();
        
        // Navigate to login page
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
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
}
