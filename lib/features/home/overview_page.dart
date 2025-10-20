import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../utils/app_colors.dart';
import '../../utils/text_styles.dart';
import '../../components/enhanced_card.dart';
import '../../services/user_service.dart';
import 'providers/health_data_provider.dart';
import 'widgets/health_summary_grid.dart';
import 'widgets/target_edit_modal.dart';
import 'models/health_metrics.dart';

class OverviewPage extends StatefulWidget {
  const OverviewPage({super.key});

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  late final HealthDataProvider _provider;
  String? _displayName;

  @override
  void initState() {
    super.initState();
    _provider = HealthDataProvider();
    _provider.addListener(_onProviderChanged);

    // No heavyweight animations for faster first paint

    // Load user name from Supabase user_identity (via UserService)
    _loadUserName();
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderChanged);
    _provider.dispose();
    super.dispose();
  }

  void _onProviderChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadUserName() async {
    try {
      final profile = await UserService().getUserProfile();
      final data = profile?['survey_data'];
      if (data is Map && mounted) {
        final name = data['name'];
        if (name is String && name.trim().isNotEmpty) {
          setState(() => _displayName = name.trim());
        }
      }
    } catch (_) {
      // Ignore; fall back to default greeting
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Builder(
        builder: (context) {
          if (_provider.isLoading && _provider.overview == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_provider.error != null && _provider.overview == null) {
            return _buildErrorState(context, _provider);
          }

          if (_provider.overview == null) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: _provider.refreshData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width > 600
                    ? 32.0
                    : 16.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _buildWelcomeSection(context),
                  const SizedBox(height: 24),
                  _buildTodaySummary(context, _provider),
                  const SizedBox(height: 24),
                  _buildHealthMetrics(context, _provider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, HealthDataProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FaIcon(
              FontAwesomeIcons.triangleExclamation,
              size: 56,
              color: AppColors.warning,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Health Data',
              style: AppTextStyles.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _provider.error!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.getTextSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _provider.refreshData,
              icon: const FaIcon(FontAwesomeIcons.arrowsRotate, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.heart,
              size: 56,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Welcome to Health Overview',
              style: AppTextStyles.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Set up your health targets to get started',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.getTextSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    final now = DateTime.now();
    final hour = now.hour;
    String greeting;
    IconData greetingIcon;
    Color greetingColor;

    if (hour < 12) {
      greeting = 'Good Morning';
      greetingIcon = FontAwesomeIcons.sun;
      greetingColor = AppColors.warning;
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
      greetingIcon = FontAwesomeIcons.sun;
      greetingColor = AppColors.success;
    } else {
      greeting = 'Good Evening';
      greetingIcon = FontAwesomeIcons.moon;
      greetingColor = AppColors.sleep;
    }

    return EnhancedCard(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              greetingColor.withValues(alpha: 0.1),
              greetingColor.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(greetingIcon, color: greetingColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  greeting,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: greetingColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _displayName ?? 'Health Champion!',
              style: AppTextStyles.displayMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaySummary(BuildContext context, HealthDataProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const FaIcon(
              FontAwesomeIcons.chartColumn,
              color: AppColors.primary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text("Today's Progress", style: AppTextStyles.subtitle),
            const Spacer(),
            if (_provider.isLoading)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.info,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Syncing...',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.info,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.circleCheck,
                      color: AppColors.success,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Live',
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
        const SizedBox(height: 16),

        HealthSummaryGrid(
          overview: _provider.overview!,
          onEditTarget: (type) =>
              _showTargetEditModal(context, _provider, type),
        ),

        const SizedBox(height: 20),
        _buildActionButtons(context, _provider),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    HealthDataProvider provider,
  ) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider, width: 1),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.of(context).pushNamed('/habit_history'),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const FaIcon(
                    FontAwesomeIcons.chartColumn,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Show History',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHealthMetrics(
    BuildContext context,
    HealthDataProvider provider,
  ) {
    final overview = _provider.overview!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Health Metrics', style: AppTextStyles.subtitle),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Theme.of(context).brightness == Brightness.dark
                ? Border.all(
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.3),
                  )
                : null,
            boxShadow: Theme.of(context).brightness == Brightness.dark
                ? []
                : [
                    BoxShadow(
                      color: AppColors.divider.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            children: [
              _buildMetricRow(
                context,
                label: 'Heart Rate',
                value: overview.metrics.heartRate?.toStringAsFixed(0) ?? '72',
                unit: 'bpm',
                status: 'Normal',
                statusColor: AppColors.success,
              ),
              const SizedBox(height: 16),
              _buildMetricRow(
                context,
                label: 'Standing Time',
                value: overview.metrics.standingMinutes != null
                    ? (overview.metrics.standingMinutes! / 60).toStringAsFixed(
                        1,
                      )
                    : '0.8',
                unit: 'hrs',
                status: 'Good',
                statusColor: AppColors.success,
              ),
              const SizedBox(height: 16),
              _buildMetricRow(
                context,
                label: 'Last Updated',
                value: _formatLastUpdated(overview.metrics.lastUpdated),
                unit: '',
                status: _provider.hasHealthPermissions ? 'HealthKit' : 'Manual',
                statusColor: _provider.hasHealthPermissions
                    ? AppColors.success
                    : AppColors.warning,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricRow(
    BuildContext context, {
    required String label,
    required String value,
    required String unit,
    required String status,
    required Color statusColor,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        Text(
          '$value $unit',
          style: AppTextStyles.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
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

  String _formatLastUpdated(DateTime lastUpdated) {
    final now = DateTime.now();
    final diff = now.difference(lastUpdated);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  Future<void> _showTargetEditModal(
    BuildContext context,
    HealthDataProvider provider,
    HealthMetricType type,
  ) async {
    final overview = provider.overview!;
    num currentValue;

    switch (type) {
      case HealthMetricType.steps:
        currentValue = overview.targets.stepsTarget;
        break;
      case HealthMetricType.calories:
        currentValue = overview.targets.caloriesTarget;
        break;
      case HealthMetricType.standingTime:
        currentValue = overview.targets.standingTimeTargetMin;
        break;
      case HealthMetricType.sleep:
        currentValue = overview.targets.sleepTargetH;
        break;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => TargetEditModal(
        type: type,
        currentValue: currentValue,
        onSave: (value) => provider.updateTarget(type, value),
      ),
    );
  }
}
