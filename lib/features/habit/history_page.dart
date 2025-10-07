import 'package:flutter/material.dart';
import 'package:final_project/services/habit_service.dart';
import 'package:final_project/utils/text_styles.dart';
import 'package:final_project/utils/app_colors.dart';

class MetricInfo {
  final String name;
  final String key;
  final Color color;

  MetricInfo(this.name, this.key, this.color);
}

class HabitHistoryPage extends StatefulWidget {
  const HabitHistoryPage({super.key});

  @override
  State<HabitHistoryPage> createState() => _HabitHistoryPageState();
}

class _HabitHistoryPageState extends State<HabitHistoryPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  List<Map<String, dynamic>> _days = [];
  bool _loading = true;
  int _selectedMetric = 0;

  final List<MetricInfo> _metrics = [
    MetricInfo('Steps', 'steps', AppColors.accent),
    MetricInfo('Calories', 'calories', AppColors.warning),
    MetricInfo('Standing', 'standing_minutes', AppColors.healthPrimary),
    MetricInfo('Sleep', 'sleep_hours', AppColors.info),
    MetricInfo('Heart Rate', 'heart_rate_avg', AppColors.heartRate),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _tabController.addListener(() => _load());
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final days = _tabController.index == 0 ? 7 : 30;
    final end = DateTime.now();
    final start = end.subtract(Duration(days: days - 1));
    final rows = await HabitService().getMetricsRange(start, end);
    if (!mounted) return;
    setState(() {
      _days = rows;
      _loading = false;
    });
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.white, size: 24),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                'Health Analytics',
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 40,
                      right: 20,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(40),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 60,
                      right: 100,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Tab Selector
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: const EdgeInsets.all(4),
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF64748B),
                labelStyle: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('7 Days'),
                    ),
                  ),
                  Tab(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('30 Days'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          _loading
              ? SliverToBoxAdapter(
                  child: SizedBox(
                    height: 300,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                              ),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Analyzing your health data...',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height,
                    child: TabBarView(
                      controller: _tabController,
                      children: [_buildModernContent(), _buildModernContent()],
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildModernContent() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Metrics Overview Cards
          Text(
            'Health Metrics',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          _buildMetricsGrid(),
          const SizedBox(height: 24),

          // Daily Timeline
          Text(
            'Daily Timeline',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildDailyTimeline()),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _metrics.length,
        itemBuilder: (context, index) {
          final metric = _metrics[index];
          final latestValue = _getLatestValue(metric.key);
          final isSelected = _selectedMetric == index;

          return GestureDetector(
            onTap: () => setState(() => _selectedMetric = index),
            child: Container(
              width: 140,
              margin: EdgeInsets.only(
                right: index == _metrics.length - 1 ? 0 : 12,
              ),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          metric.color,
                          metric.color.withValues(alpha: 0.7),
                        ],
                      )
                    : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: isSelected
                    ? null
                    : Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? metric.color.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.06),
                    blurRadius: isSelected ? 12 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Add a colored indicator bar at the top
                    Container(
                      width: 20,
                      height: 3,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : metric.color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      metric.name,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.8)
                            : const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      latestValue,
                      style: AppTextStyles.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDailyTimeline() {
    if (_days.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No health data available for this period',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _days.length,
        itemBuilder: (context, index) {
          final day = _days[index];
          final date = DateTime.parse(day['bucket_date']);
          final isToday = DateTime.now().difference(date).inDays == 0;

          return Container(
            margin: EdgeInsets.only(bottom: index == _days.length - 1 ? 0 : 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: isToday
                  ? const LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    )
                  : null,
              color: isToday ? null : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: isToday
                  ? null
                  : Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDateTimeline(day['bucket_date']),
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isToday
                                ? Colors.white
                                : const Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          isToday ? 'Today' : _getDayOfWeek(date),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isToday
                                ? Colors.white.withValues(alpha: 0.8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildTimelineChip(
                      'Steps',
                      day['steps'],
                      AppColors.accent,
                      isToday,
                    ),
                    _buildTimelineChip(
                      'Cal',
                      day['calories'],
                      AppColors.warning,
                      isToday,
                    ),
                    _buildTimelineChip(
                      'Standing',
                      day['standing_minutes'],
                      AppColors.healthPrimary,
                      isToday,
                    ),
                    _buildTimelineChip(
                      'Sleep',
                      day['sleep_hours'],
                      AppColors.info,
                      isToday,
                    ),
                    _buildTimelineChip(
                      'HR',
                      day['heart_rate_avg'],
                      AppColors.heartRate,
                      isToday,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimelineChip(
    String label,
    dynamic value,
    Color color,
    bool isToday,
  ) {
    final displayValue = _formatChipValue(label, value);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isToday
            ? Colors.white.withValues(alpha: 0.2)
            : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: isToday
            ? Border.all(color: Colors.white.withValues(alpha: 0.3))
            : Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isToday
                    ? Colors.white.withValues(alpha: 0.8)
                    : const Color(0xFF64748B),
              ),
            ),
            TextSpan(
              text: displayValue,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isToday ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLatestValue(String key) {
    if (_days.isEmpty) return '—';
    final latest = _days.last;
    return _formatChipValue('', latest[key]);
  }

  String _formatChipValue(String label, dynamic value) {
    if (value == null) return '—';
    if (value is num) {
      if (label == 'Sleep') return '${value.toStringAsFixed(1)}h';
      if (label == 'Standing') return '${(value / 60).toStringAsFixed(1)}h';
      if (label == 'HR') return '${value.round()}';
      return value.round().toString();
    }
    return value.toString();
  }

  String _formatDateTimeline(String dateStr) {
    final date = DateTime.parse(dateStr);
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  String _getDayOfWeek(DateTime date) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }
}
