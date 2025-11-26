import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:final_project/utils/app_colors.dart';
import 'package:final_project/utils/text_styles.dart';
import 'package:final_project/services/mongo_service.dart';
import 'package:final_project/features/exercise/exercise_detail_page.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ExerciseListPage extends StatefulWidget {
  const ExerciseListPage({super.key});

  @override
  State<ExerciseListPage> createState() => _ExerciseListPageState();
}

class _ExerciseListPageState extends State<ExerciseListPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];
  String _selectedLevel = 'All';
  String _selectedType = 'All';
  String _sortBy = 'name'; // name, level, type

  List<Map<String, dynamic>> get _filteredAndSortedItems {
    var filtered = _items.where((ex) {
      if (_selectedLevel != 'All' &&
          (ex['level'] ?? '').toString() != _selectedLevel) {
        return false;
      }
      if (_selectedType != 'All' &&
          (ex['type'] ?? '').toString() != _selectedType) {
        return false;
      }
      return true;
    }).toList();

    // Sort
    filtered.sort((a, b) {
      if (_sortBy == 'name') {
        return (a['name'] ?? '').toString().compareTo(
          (b['name'] ?? '').toString(),
        );
      } else if (_sortBy == 'level') {
        return (a['level'] ?? '').toString().compareTo(
          (b['level'] ?? '').toString(),
        );
      } else {
        return (a['type'] ?? '').toString().compareTo(
          (b['type'] ?? '').toString(),
        );
      }
    });

    return filtered;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({String? name}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await MongoService.filterExercises(
        name: name?.trim().isEmpty == true ? null : name?.trim(),
        limit: 200,
      );
      setState(() {
        _items = data;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        String tempLevel = _selectedLevel;
        String tempType = _selectedType;
        String tempSort = _sortBy;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter & Sort',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const FaIcon(FontAwesomeIcons.xmark, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Level',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: ['All', 'beginner', 'intermediate', 'expert'].map(
                      (level) {
                        final isSelected = tempLevel == level;
                        return FilterChip(
                          label: Text(level),
                          selected: isSelected,
                          onSelected: (selected) {
                            setSheetState(() => tempLevel = level);
                          },
                          backgroundColor: Theme.of(context).cardColor,
                          selectedColor: AppColors.accent.withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.accent : null,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.accent
                                  : Theme.of(context).dividerColor,
                            ),
                          ),
                        );
                      },
                    ).toList(),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Type',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['All', 'strength', 'cardio', 'stretching'].map((
                      type,
                    ) {
                      final isSelected = tempType == type;
                      return FilterChip(
                        label: Text(type),
                        selected: isSelected,
                        onSelected: (selected) {
                          setSheetState(() => tempType = type);
                        },
                        backgroundColor: Theme.of(context).cardColor,
                        selectedColor: AppColors.accent.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.accent : null,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.accent
                                : Theme.of(context).dividerColor,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedLevel = tempLevel;
                          _selectedType = tempType;
                          _sortBy = tempSort;
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasFilters = _selectedLevel != 'All' || _selectedType != 'All';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              shape: BoxShape.circle,
            ),
            child: const FaIcon(FontAwesomeIcons.arrowLeft, size: 16),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Exercise Library',
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              onPressed: _showFilterDialog,
              style: IconButton.styleFrom(
                backgroundColor: hasFilters
                    ? AppColors.accent.withOpacity(0.1)
                    : Theme.of(context).cardColor,
              ),
              icon: Stack(
                children: [
                  FaIcon(
                    FontAwesomeIcons.sliders,
                    size: 18,
                    color: hasFilters
                        ? AppColors.accent
                        : Theme.of(context).iconTheme.color,
                  ),
                  if (hasFilters)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (v) => _load(name: v),
                      decoration: InputDecoration(
                        hintText: 'Search exercises...',
                        hintStyle: TextStyle(
                          color: Theme.of(context).hintColor.withOpacity(0.5),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () => _load(name: _searchCtrl.text),
                    icon: const FaIcon(
                      FontAwesomeIcons.arrowRight,
                      color: Colors.white,
                      size: 18,
                    ),
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
          ),

          // Active Filters Display
          if (hasFilters)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              child: Row(
                children: [
                  if (_selectedLevel != 'All')
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ActionChip(
                        label: Text(_selectedLevel),
                        onPressed: () => setState(() => _selectedLevel = 'All'),
                        backgroundColor: AppColors.accent.withOpacity(0.1),
                        labelStyle: const TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  if (_selectedType != 'All')
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ActionChip(
                        label: Text(_selectedType),
                        onPressed: () => setState(() => _selectedType = 'All'),
                        backgroundColor: AppColors.accent.withOpacity(0.1),
                        labelStyle: const TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  TextButton(
                    onPressed: () => setState(() {
                      _selectedLevel = 'All';
                      _selectedType = 'All';
                    }),
                    child: const Text('Clear All'),
                  ),
                ],
              ),
            ),

          // Content Area
          Expanded(child: _buildContent(isDark)),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.accent),
            const SizedBox(height: 24),
            Text(
              'Loading exercises...',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: FaIcon(
                  FontAwesomeIcons.triangleExclamation,
                  size: 48,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Something went wrong',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Theme.of(context).hintColor,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const FaIcon(FontAwesomeIcons.rotateRight, size: 16),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredAndSortedItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                shape: BoxShape.circle,
              ),
              child: FaIcon(
                FontAwesomeIcons.dumbbell,
                size: 64,
                color: Theme.of(context).disabledColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No exercises found',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _load(name: _searchCtrl.text),
      color: AppColors.accent,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        itemCount: _filteredAndSortedItems.length,
        separatorBuilder: (context, i) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final ex = _filteredAndSortedItems[index];
          return _ExerciseCard(exercise: ex, isDark: isDark);
        },
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final Map<String, dynamic> exercise;
  final bool isDark;

  const _ExerciseCard({required this.exercise, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final name = (exercise['name'] ?? 'Exercise').toString();
    final type = (exercise['type'] ?? '').toString();
    final level = (exercise['level'] ?? '').toString();
    final force = (exercise['force'] ?? '').toString();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ExerciseDetailPage(exercise: exercise),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Container
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _getTypeColor(type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: FaIcon(
                      _getTypeIcon(type),
                      color: _getTypeColor(type),
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          if (level.isNotEmpty)
                            _StatusBadge(
                              text: level,
                              color: _getLevelColor(level),
                            ),
                          if (type.isNotEmpty)
                            _StatusBadge(
                              text: type,
                              color: _getTypeColor(type),
                              isOutline: true,
                            ),
                          if (force.isNotEmpty)
                            _StatusBadge(
                              text: force,
                              color: AppColors.warning,
                              isOutline: true,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Arrow
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 12),
                  child: FaIcon(
                    FontAwesomeIcons.chevronRight,
                    size: 14,
                    color: Theme.of(context).disabledColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return AppColors.success;
      case 'intermediate':
        return AppColors.warning;
      case 'expert':
        return AppColors.error;
      default:
        return AppColors.accent;
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'cardio':
        return Colors.orange;
      case 'strength':
        return Colors.blue;
      case 'stretching':
        return Colors.purple;
      case 'powerlifting':
        return Colors.red;
      default:
        return AppColors.accent;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'cardio':
        return FontAwesomeIcons.heartPulse;
      case 'strength':
        return FontAwesomeIcons.dumbbell;
      case 'stretching':
        return FontAwesomeIcons.personRunning; // Approximation
      case 'powerlifting':
        return FontAwesomeIcons.weightHanging;
      default:
        return FontAwesomeIcons.personWalking;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  final bool isOutline;

  const _StatusBadge({
    required this.text,
    required this.color,
    this.isOutline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOutline ? Colors.transparent : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: isOutline ? Border.all(color: color.withOpacity(0.3)) : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
