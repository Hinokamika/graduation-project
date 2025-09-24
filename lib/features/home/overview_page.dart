import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:final_project/utils/app_colors.dart';
import 'package:final_project/utils/text_styles.dart';

class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Welcome Section
          _buildWelcomeSection(context),
            const SizedBox(height: 32),
            
          // Today's Summary
          _buildTodaySummary(context),
            const SizedBox(height: 32),
            
            // Health Metrics
            _buildHealthMetrics(context),
            const SizedBox(height: 32),
            
            // Recent Activities
            _buildRecentActivities(context),
            const SizedBox(height: 32),
            
            // Quick Actions
            _buildQuickActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Theme.of(context).brightness == Brightness.dark
            ? Border.all(color: Theme.of(context).dividerColor)
            : null,
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? []
            : [
                BoxShadow(
                  color: AppColors.divider.withValues(alpha: 0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Good Morning,',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sarah Johnson',
            style: AppTextStyles.heading2.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.chart_bar,
                      color: AppColors.success,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Great Progress!',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySummary(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today's Summary",
          style: AppTextStyles.subtitle,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                context,
                title: 'Steps',
                value: '8,432',
                target: '10,000',
                icon: CupertinoIcons.person_2,
                color: AppColors.accent,
                progress: 0.84,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                context,
                title: 'Calories',
                value: '1,850',
                target: '2,200',
                icon: Icons.local_fire_department,
                color: AppColors.warning,
                progress: 0.84,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                context,
                title: 'Water',
                value: '1.8L',
                target: '2.5L',
                icon: Icons.water_drop,
                color: AppColors.healthPrimary,
                progress: 0.72,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                context,
                title: 'Sleep',
                value: '7.5h',
                target: '8h',
                icon: Icons.bedtime,
                color: AppColors.info,
                progress: 0.94,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required String value,
    required String target,
    required IconData icon,
    required Color color,
    required double progress,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Theme.of(context).brightness == Brightness.dark
            ? Border.all(color: Theme.of(context).dividerColor)
            : null,
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? []
            : [
                BoxShadow(
                  color: AppColors.divider.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Target: $target',
            style: AppTextStyles.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Theme.of(context).dividerColor,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthMetrics(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Health Metrics',
          style: AppTextStyles.subtitle,
        ),
        const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Theme.of(context).brightness == Brightness.dark
                  ? Border.all(color: Theme.of(context).dividerColor)
                  : null,
              boxShadow: Theme.of(context).brightness == Brightness.dark
                  ? []
                  : [
                      BoxShadow(
                        color: AppColors.divider.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
          child: Column(
            children: [
              _buildMetricRow(
                label: 'Heart Rate',
                value: '72 bpm',
                status: 'Normal',
                statusColor: AppColors.success,
                icon: Icons.favorite,
              ),
              const SizedBox(height: 16),
              _buildMetricRow(
                label: 'Blood Pressure',
                value: '120/80',
                status: 'Optimal',
                statusColor: AppColors.success,
                icon: Icons.monitor_heart,
              ),
              const SizedBox(height: 16),
              _buildMetricRow(
                label: 'BMI',
                value: '22.4',
                status: 'Healthy',
                statusColor: AppColors.success,
                icon: Icons.calculate,
              ),
              const SizedBox(height: 16),
              _buildMetricRow(
                label: 'Stress Level',
                value: 'Low',
                status: 'Good',
                statusColor: AppColors.wellness,
                icon: Icons.psychology,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricRow({
    required String label,
    required String value,
    required String status,
    required Color statusColor,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.textSecondary,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status,
            style: AppTextStyles.bodySmall.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivities(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activities',
          style: AppTextStyles.subtitle,
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Theme.of(context).brightness == Brightness.dark
                ? Border.all(color: Theme.of(context).dividerColor)
                : null,
            boxShadow: Theme.of(context).brightness == Brightness.dark
                ? []
                : [
                    BoxShadow(
                      color: AppColors.divider.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            children: [
              _buildActivityItem(
                context,
                icon: CupertinoIcons.sportscourt,
                title: 'Morning Yoga',
                time: '30 min ago',
                calories: '120 cal',
                color: AppColors.accent,
              ),
              Divider(height: 1, color: Theme.of(context).dividerColor),
              _buildActivityItem(
                context,
                icon: Icons.restaurant,
                title: 'Healthy Breakfast',
                time: '2 hours ago',
                calories: '350 cal',
                color: AppColors.success,
              ),
              Divider(height: 1, color: Theme.of(context).dividerColor),
              _buildActivityItem(
                context,
                icon: Icons.directions_walk,
                title: 'Evening Walk',
                time: 'Yesterday',
                calories: '180 cal',
                color: AppColors.healthPrimary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(BuildContext context, {
    required IconData icon,
    required String title,
    required String time,
    required String calories,
    required Color color,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: color,
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
        time,
        style: AppTextStyles.bodySmall.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
      trailing: Text(
        calories,
        style: AppTextStyles.bodySmall.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: AppTextStyles.subtitle,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.add,
                label: 'Log Activity',
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.camera_alt,
                label: 'Scan Food',
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.medication,
                label: 'Medications',
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.calendar_today,
                label: 'Appointments',
                color: AppColors.info,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Theme.of(context).brightness == Brightness.dark
            ? Border.all(color: Theme.of(context).dividerColor)
            : null,
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? []
            : [
                BoxShadow(
                  color: AppColors.divider.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
