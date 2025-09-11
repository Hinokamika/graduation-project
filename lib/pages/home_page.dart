import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:final_project/utils/app_colors.dart';
import 'package:final_project/utils/text_styles.dart';
import 'package:final_project/pages/overview_page.dart';
import 'package:final_project/pages/exercise_page.dart';
import 'package:final_project/pages/meal_page.dart';
import 'package:final_project/pages/relax_page.dart';
import 'package:final_project/pages/user_page.dart';
import 'package:final_project/pages/settings_page.dart';

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
    const MealPage(),
    const RelaxPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Top Navbar
          _buildTopNavbar(),
          
          // Main Content
          Expanded(
            child: _pages[_currentIndex],
          ),
        ],
      ),
      
      // Bottom Navigation
      bottomNavigationBar: _buildBottomNavbar(),
    );
  }

  Widget _buildTopNavbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
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
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          
          // Settings and User Profile
          Row(
            children: [
              // Settings Button
              IconButton(
                icon: Icon(
                  CupertinoIcons.gear,
                  color: AppColors.textPrimary,
                  size: 24,
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
              
              const SizedBox(width: 8),
              
              // Notifications
              Stack(
                children: [
                  IconButton(
                    icon: Icon(
                      CupertinoIcons.bell,
                      color: AppColors.textPrimary,
                      size: 24,
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
                    MaterialPageRoute(
                      builder: (context) => const UserPage(),
                    ),
                  );
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.healthSecondary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.divider,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    CupertinoIcons.person,
                    color: AppColors.healthPrimary,
                    size: 20,
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
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.divider.withValues(alpha: 0.5),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(
            icon: CupertinoIcons.square_grid_2x2,
            selectedIcon: CupertinoIcons.square_grid_2x2_fill,
            label: 'Overview',
            index: 0,
          ),
          _buildNavItem(
            icon: CupertinoIcons.sportscourt,
            selectedIcon: CupertinoIcons.sportscourt_fill,
            label: 'Exercise',
            index: 1,
          ),
          _buildNavItem(
            icon: CupertinoIcons.heart,
            selectedIcon: CupertinoIcons.heart_fill,
            label: 'Meal',
            index: 2,
          ),
          _buildNavItem(
            icon: CupertinoIcons.leaf_arrow_circlepath,
            selectedIcon: CupertinoIcons.leaf_arrow_circlepath,
            label: 'Relax',
            index: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.accent.withValues(alpha: 0.1) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              color: isSelected ? AppColors.accent : AppColors.textLight,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: isSelected ? AppColors.accent : AppColors.textLight,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
