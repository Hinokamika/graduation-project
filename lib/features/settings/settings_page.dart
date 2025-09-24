import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:final_project/utils/app_colors.dart';
import 'package:final_project/utils/text_styles.dart';
import 'package:final_project/config/theme_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:final_project/services/user_service.dart';
import 'package:final_project/features/profile/user_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UserService _userService = UserService();
  
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _darkModeEnabled = ThemeController.instance.mode.value == ThemeMode.dark;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Settings', style: AppTextStyles.heading3),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Settings
            _buildSectionTitle('Account Settings'),
            const SizedBox(height: 16),
            _buildAccountSettings(),
            
            const SizedBox(height: 32),
            
            // App Preferences
            _buildSectionTitle('App Preferences'),
            const SizedBox(height: 16),
            _buildAppPreferences(),
            
            const SizedBox(height: 32),
            
            // Privacy & Security
            _buildSectionTitle('Privacy & Security'),
            const SizedBox(height: 16),
            _buildPrivacySettings(),
            
            const SizedBox(height: 32),
            
            // Support
            _buildSectionTitle('Support'),
            const SizedBox(height: 16),
            _buildSupportSettings(),
            
            const SizedBox(height: 32),
            
            // About
            _buildSectionTitle('About'),
            const SizedBox(height: 16),
            _buildAboutSettings(),
            
            const SizedBox(height: 32),
            
            // Danger Zone
            _buildSectionTitle('Danger Zone'),
            const SizedBox(height: 16),
            _buildDangerZone(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.subtitle.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildAccountSettings() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.person_outline,
            title: 'Profile Information',
            subtitle: 'Update your personal details',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const UserPage(),
                ),
              );
            },
          ),
          
          _buildDivider(),
          
          _buildSettingsTile(
            icon: Icons.email_outlined,
            title: 'Email Preferences',
            subtitle: 'Manage email notifications',
            onTap: () {
              _showComingSoon('Email Preferences');
            },
          ),
          
          _buildDivider(),
          
          _buildSettingsTile(
            icon: Icons.lock_outline,
            title: 'Change Password',
            subtitle: 'Update your account password',
            onTap: () {
              _showComingSoon('Change Password');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppPreferences() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            icon: Icons.notifications_outlined,
            title: 'Push Notifications',
            subtitle: 'Receive app notifications',
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),
          
          _buildDivider(),
          
          _buildSwitchTile(
            icon: Icons.dark_mode_outlined,
            title: 'Dark Mode',
            subtitle: 'Enable dark theme',
            value: _darkModeEnabled,
            onChanged: (value) {
              setState(() {
                _darkModeEnabled = value;
              });
              ThemeController.instance
                  .setMode(value ? ThemeMode.dark : ThemeMode.light);
            },
          ),
          
          _buildDivider(),
          
          _buildSwitchTile(
            icon: Icons.fingerprint_outlined,
            title: 'Biometric Login',
            subtitle: 'Use fingerprint or face ID',
            value: _biometricEnabled,
            onChanged: (value) {
              setState(() {
                _biometricEnabled = value;
              });
              _showComingSoon('Biometric Login');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySettings() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            subtitle: 'Read our privacy policy',
            onTap: () {
              _showComingSoon('Privacy Policy');
            },
          ),
          
          _buildDivider(),
          
          _buildSettingsTile(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            subtitle: 'Read our terms and conditions',
            onTap: () {
              _showComingSoon('Terms of Service');
            },
          ),
          
          _buildDivider(),
          
          _buildSettingsTile(
            icon: Icons.data_usage_outlined,
            title: 'Data Usage',
            subtitle: 'Manage app data and storage',
            onTap: () {
              _showComingSoon('Data Usage');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSettings() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.help_outline,
            title: 'Help Center',
            subtitle: 'Get help and support',
            onTap: () {
              _showComingSoon('Help Center');
            },
          ),
          
          _buildDivider(),
          
          _buildSettingsTile(
            icon: Icons.chat_outlined,
            title: 'Contact Us',
            subtitle: 'Reach out to our support team',
            onTap: () {
              _showComingSoon('Contact Us');
            },
          ),
          
          _buildDivider(),
          
          _buildSettingsTile(
            icon: Icons.star_outline,
            title: 'Rate App',
            subtitle: 'Share your feedback',
            onTap: () {
              _showComingSoon('Rate App');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSettings() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.info_outline,
            title: 'App Version',
            subtitle: '1.0.0',
            onTap: null,
          ),
          
          _buildDivider(),
          
          _buildSettingsTile(
            icon: Icons.update_outlined,
            title: 'Check for Updates',
            subtitle: 'See if a newer version is available',
            onTap: () {
              _showComingSoon('Check for Updates');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.restart_alt,
            title: 'Reset App',
            subtitle: 'Clear local data and sign out',
            onTap: _handleResetApp,
            iconColor: AppColors.error,
          ),
          
          _buildDivider(),
          
          _buildSettingsTile(
            icon: Icons.delete_outline,
            title: 'Clear Cache',
            subtitle: 'Clear app cache and temporary files',
            onTap: _handleClearCache,
            iconColor: AppColors.error,
          ),
          
          _buildDivider(),
          
          _buildSettingsTile(
            icon: Icons.logout_outlined,
            title: 'Log Out',
            subtitle: 'Sign out of your account',
            onTap: _handleLogout,
            iconColor: AppColors.error,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.accent).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: iconColor ?? AppColors.accent,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
      trailing: onTap != null
          ? Icon(
              Icons.chevron_right,
              color: AppColors.textLight,
              size: 20,
            )
          : null,
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
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
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.accent,
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 72,
      endIndent: 16,
      color: Theme.of(context).dividerColor,
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature feature coming soon!'),
        backgroundColor: AppColors.accent,
      ),
    );
  }

  Future<void> _handleClearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache?'),
        content: const Text(
          'This will remove locally saved survey and onboarding data from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _userService.clearLocalData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Local cache cleared.'),
          backgroundColor: Colors.green,
          duration: Duration(milliseconds: 1200),
        ),
      );

      // If not authenticated, return to root so AuthWrapper can route to Intro
      if (_supabase.auth.currentUser == null) {
        await Future.delayed(const Duration(milliseconds: 400));
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to clear cache: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleResetApp() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset App?'),
        content: const Text(
          'This will clear local data and sign out of your account. You will return to the start of the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _userService.clearLocalData();
      await _supabase.auth.signOut();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('App reset complete.'),
          backgroundColor: Colors.green,
          duration: Duration(milliseconds: 1200),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reset app: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
        await _supabase.auth.signOut();
        
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
