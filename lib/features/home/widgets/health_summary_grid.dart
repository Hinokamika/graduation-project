import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/services.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/text_styles.dart';
import '../models/health_metrics.dart';

class HealthSummaryCard extends StatefulWidget {
  final String title;
  final String value;
  final String target;
  final Color color;
  final double progress;
  final VoidCallback? onTap;

  const HealthSummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.target,
    required this.color,
    required this.progress,
    this.onTap,
  });

  @override
  State<HealthSummaryCard> createState() => _HealthSummaryCardState();
}

class _HealthSummaryCardState extends State<HealthSummaryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: widget.progress)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void didUpdateWidget(HealthSummaryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _progressAnimation =
          Tween<double>(
            begin: oldWidget.progress,
            end: widget.progress,
          ).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeOutCubic,
            ),
          );
      _animationController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap != null
                  ? () {
                      HapticFeedback.lightImpact();
                      widget.onTap!();
                    }
                  : null,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.color.withValues(alpha: 0.05),
                      widget.color.withValues(alpha: 0.02),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: widget.color.withValues(alpha: 0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.title,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (widget.onTap != null)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: widget.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: FaIcon(
                              FontAwesomeIcons.pen,
                              size: 14,
                              color: widget.color,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.value,
                      style: AppTextStyles.heading2.copyWith(
                        color: widget.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Target: ${widget.target}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _progressAnimation.value.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                widget.color,
                                widget.color.withValues(alpha: 0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(_progressAnimation.value * 100).toInt()}%',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: widget.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_progressAnimation.value >= 1.0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const FaIcon(
                                  FontAwesomeIcons.circleCheck,
                                  size: 10,
                                  color: AppColors.success,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  'Goal',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.success,
                                    fontSize: 10,
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
              ),
            ),
          ),
        );
      },
    );
  }
}

class HealthSummaryGrid extends StatelessWidget {
  final HealthOverview overview;
  final Function(HealthMetricType) onEditTarget;

  const HealthSummaryGrid({
    super.key,
    required this.overview,
    required this.onEditTarget,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: HealthSummaryCard(
                title: 'Steps',
                value: overview.metrics.steps == null
                    ? '–'
                    : _formatNumber(overview.metrics.steps!),
                target: '${overview.targets.stepsTarget}',
                color: AppColors.accent,
                progress: overview.getProgress(HealthMetricType.steps),
                onTap: () => onEditTarget(HealthMetricType.steps),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: HealthSummaryCard(
                title: 'Calories Burned',
                value: overview.metrics.calories == null
                    ? '–'
                    : _formatNumber(overview.metrics.calories!.round()),
                target: '${overview.targets.caloriesTarget}',
                color: AppColors.warning,
                progress: overview.getProgress(HealthMetricType.calories),
                onTap: () => onEditTarget(HealthMetricType.calories),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: HealthSummaryCard(
                title: 'Standing Time',
                value: overview.metrics.standingTimeMinutes == null
                    ? '–'
                    : '${(overview.metrics.standingTimeMinutes! / 60).toStringAsFixed(1)} hours',
                target:
                    '${(overview.targets.standingTimeTargetMin / 60).toStringAsFixed(1)} hours',
                color: AppColors.healthPrimary,
                progress: overview.getProgress(HealthMetricType.standingTime),
                onTap: () => onEditTarget(HealthMetricType.standingTime),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: HealthSummaryCard(
                title: 'Sleep',
                value: overview.metrics.sleepHours == null
                    ? '–'
                    : '${overview.metrics.sleepHours!.toStringAsFixed(1)}h',
                target: '${overview.targets.sleepTargetH.toStringAsFixed(1)}h',
                color: AppColors.info,
                progress: overview.getProgress(HealthMetricType.sleep),
                onTap: () => onEditTarget(HealthMetricType.sleep),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatNumber(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idx = s.length - i;
      buf.write(s[i]);
      if (idx > 1 && idx % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }
}
