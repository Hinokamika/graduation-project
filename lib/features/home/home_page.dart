import 'package:final_project/config/theme_controller.dart';
import 'package:final_project/features/chat/chat_page.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:final_project/utils/app_colors.dart';
import 'package:final_project/utils/text_styles.dart';
import 'package:final_project/features/home/overview_page.dart';
import 'package:final_project/features/exercise/exercise_page.dart';
import 'package:final_project/features/nutrition/meal_page.dart';
import 'package:final_project/features/relax/relax_page.dart';
import 'package:final_project/features/profile/user_page.dart';
import 'package:final_project/features/settings/settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const OverviewPage(),
    const ExercisePage(),
    const ChatPage(),
    const MealPage(),
    const RelaxPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            // Top Navbar
            _buildTopNavbar(),

            // Main Content
            Expanded(child: _pages[_currentIndex]),
          ],
        ),
      ),

      // Bottom Navigation
      bottomNavigationBar: _buildBottomNavbar(),
    );
  }

  Widget _buildTopNavbar() {
    final width = MediaQuery.of(context).size.width;
    final horizontal = width < 360 ? 16.0 : 24.0;
    final vertical = width < 360 ? 12.0 : 16.0;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Theme.of(context).brightness == Brightness.dark
            ? Border.all(color: Theme.of(context).dividerColor)
            : null,
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? []
            : [
                BoxShadow(
                  color: AppColors.divider.withValues(alpha: 0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // App Title
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HealthCare+',
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Your Health Companion',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),

          // Settings and User Profile
          Row(
            children: [
              // Settings Button
              IconButton(
                icon: const FaIcon(
                  FontAwesomeIcons.gear,
                  size: 20,
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SettingsPage(),
                    ),
                  );
                },
                tooltip: 'Settings',
              ),
              // Theme Toggle Button
              IconButton(
                icon: FaIcon(
                  Theme.of(context).brightness == Brightness.dark
                      ? FontAwesomeIcons.sun
                      : FontAwesomeIcons.moon,
                  color: AppColors.getTextPrimary(context),
                  size: 22,
                ),
                onPressed: () {
                  ThemeController.instance.toggle();
                },
                tooltip: 'Toggle Theme',
              ),

              // Notifications
              Stack(
                children: [
                  IconButton(
                    icon: const FaIcon(
                      FontAwesomeIcons.bell,
                      size: 22,
                    ),
                    onPressed: () {
                      // Handle notifications
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Notifications feature coming soon!'),
                          backgroundColor: AppColors.accent,
                        ),
                      );
                    },
                    tooltip: 'Notifications',
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 8),

              // User Profile Button
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const UserPage()),
                  );
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.healthSecondary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: const FaIcon(
                      FontAwesomeIcons.user,
                      color: AppColors.healthPrimary,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavbar() {
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 360;
    final isMedium = width < 420;
    final barHeight = isCompact ? 64.0 : (isMedium ? 72.0 : 80.0);
    // Make the navbar wider by reducing horizontal margins
    final horizontal = isCompact ? 8.0 : 12.0;
    // Make it floating with a smaller bottom margin
    final bottom = 4.0;
    final iconSize = isCompact ? 20.0 : 24.0;
    final showLabels =
        width >= 360; // hide labels on compact to prevent overflow

    // Shorten labels on medium widths to avoid overflow
    final overviewLabel = isMedium ? 'Home' : 'Overview';
    final workoutLabel = isMedium ? 'Work' : 'Workout';

    return SafeArea(
      top: false,
      child: Container(
        margin: EdgeInsets.fromLTRB(horizontal, 0, horizontal, bottom),
        height: barHeight,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Theme.of(context).brightness == Brightness.dark
              ? Border.all(color: Theme.of(context).dividerColor)
              : null,
          boxShadow: Theme.of(context).brightness == Brightness.dark
              ? []
              : [
                  BoxShadow(
                    color: AppColors.divider.withValues(alpha: 0.45),
                    blurRadius: 14,
                    spreadRadius: 0,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildNavItem(
                icon: FontAwesomeIcons.tableCellsLarge,
                selectedIcon: FontAwesomeIcons.tableCellsLarge,
                label: overviewLabel,
                index: 0,
                showLabel: showLabels,
                iconSize: iconSize,
              ),
            ),
            Expanded(
              child: _buildNavItem(
                icon: FontAwesomeIcons.dumbbell,
                selectedIcon: FontAwesomeIcons.dumbbell,
                label: workoutLabel,
                index: 1,
                showLabel: showLabels,
                iconSize: iconSize,
              ),
            ),
            Expanded(
              child: _buildNavItem(
                icon: FontAwesomeIcons.commentDots,
                selectedIcon: FontAwesomeIcons.commentDots,
                label: 'Chat',
                index: 2,
                showLabel: showLabels,
                iconSize: iconSize,
              ),
            ),
            Expanded(
              child: _buildNavItem(
                icon: FontAwesomeIcons.lemon,
                selectedIcon: FontAwesomeIcons.lemon,
                label: 'Meal',
                index: 3,
                showLabel: showLabels,
                iconSize: iconSize,
              ),
            ),
            Expanded(
              child: _buildNavItem(
                icon: FontAwesomeIcons.leaf,
                selectedIcon: FontAwesomeIcons.leaf,
                label: 'Relax',
                index: 4,
                showLabel: showLabels,
                iconSize: iconSize,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
    required bool showLabel,
    required double iconSize,
  }) {
    final isSelected = _currentIndex == index;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.accent.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              FaIcon(
                isSelected ? selectedIcon : icon,
                color: isSelected ? AppColors.accent : AppColors.textLight,
                size: iconSize,
              ),
              if (showLabel) ...[
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isSelected ? AppColors.accent : AppColors.textLight,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
