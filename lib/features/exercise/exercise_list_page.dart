import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:final_project/utils/app_colors.dart';
import 'package:final_project/utils/text_styles.dart';
import 'package:final_project/services/mongo_service.dart';
import 'package:final_project/features/exercise/exercise_detail_page.dart';

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
      if (kIsWeb) {
        setState(() {
          _error = 'Mongo is not supported on Web in this app.';
          _items = [];
          _loading = false;
        });
        return;
      }
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
    showDialog(
      context: context,
      builder: (context) {
        String tempLevel = _selectedLevel;
        String tempType = _selectedType;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Filter & Sort'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['All', 'beginner', 'intermediate', 'expert']
                          .map((level) {
                            return ChoiceChip(
                              label: Text(level),
                              selected: tempLevel == level,
                              onSelected: (selected) {
                                setDialogState(() => tempLevel = level);
                              },
                            );
                          })
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Type',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          [
                            'All',
                            'strength',
                            'cardio',
                            'stretching',
                            'powerlifting',
                            'strongman',
                            'olympic_weightlifting',
                            'plyometrics',
                          ].map((type) {
                            return ChoiceChip(
                              label: Text(type),
                              selected: tempType == type,
                              onSelected: (selected) {
                                setDialogState(() => tempType = type);
                              },
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Sort By',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      value: _sortBy,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'name', child: Text('Name')),
                        DropdownMenuItem(value: 'level', child: Text('Level')),
                        DropdownMenuItem(value: 'type', child: Text('Type')),
                      ],
                      onChanged: (value) {
                        setDialogState(() => _sortBy = value ?? 'name');
                        setState(() => _sortBy = value ?? 'name');
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedLevel = 'All';
                      _selectedType = 'All';
                      _sortBy = 'name';
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Clear'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedLevel = tempLevel;
                      _selectedType = tempType;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ],
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Exercises'),
        actions: [
          IconButton(
            onPressed: _showFilterDialog,
            icon: Stack(
              children: [
                const Icon(Icons.filter_list),
                if (_selectedLevel != 'All' || _selectedType != 'All')
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Filter exercises',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (v) => _load(name: v),
                    decoration: InputDecoration(
                      hintText: 'Search exercises by name...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF2C2C2E)
                          : const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _load(name: _searchCtrl.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Search'),
                ),
              ],
            ),
          ),

          // Filter chips
          if (_selectedLevel != 'All' || _selectedType != 'All')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                children: [
                  if (_selectedLevel != 'All')
                    Chip(
                      label: Text(_selectedLevel),
                      onDeleted: () => setState(() => _selectedLevel = 'All'),
                      deleteIconColor: isDark ? Colors.white70 : Colors.black54,
                      backgroundColor: isDark
                          ? const Color(0xFF2C2C2E)
                          : const Color(0xFFE2E8F0),
                    ),
                  if (_selectedType != 'All')
                    Chip(
                      label: Text(_selectedType),
                      onDeleted: () => setState(() => _selectedType = 'All'),
                      deleteIconColor: isDark ? Colors.white70 : Colors.black54,
                      backgroundColor: isDark
                          ? const Color(0xFF2C2C2E)
                          : const Color(0xFFE2E8F0),
                    ),
                ],
              ),
            ),

          // Results count
          if (!_loading && _error == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_filteredAndSortedItems.length} exercises found',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? const Color(0xFF8E8E93)
                          : const Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    'Sorted by: $_sortBy',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? const Color(0xFF8E8E93)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),

          // Content
          if (_loading)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Loading exercises...',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isDark
                            ? const Color(0xFF8E8E93)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_error != null)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Oops!',
                        style: AppTextStyles.titleLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (_filteredAndSortedItems.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 80,
                      color: isDark
                          ? const Color(0xFF38383A)
                          : const Color(0xFFE2E8F0),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No exercises found',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: isDark
                            ? const Color(0xFFF2F2F7)
                            : const Color(0xFF1E293B),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try adjusting your search or filters',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isDark
                            ? const Color(0xFF8E8E93)
                            : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() {
                          _selectedLevel = 'All';
                          _selectedType = 'All';
                        });
                        _load();
                      },
                      icon: const Icon(Icons.clear_all),
                      label: const Text('Clear all filters'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _load(name: _searchCtrl.text),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: _filteredAndSortedItems.length,
                  separatorBuilder: (context, i) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final ex = _filteredAndSortedItems[index];
                    final name = (ex['name'] ?? 'Exercise').toString();
                    final type = (ex['type'] ?? '').toString();
                    final level = (ex['level'] ?? '').toString();
                    return _ExerciseCard(
                      exercise: ex,
                      name: name,
                      type: type,
                      level: level,
                      isDark: isDark,
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final Map<String, dynamic> exercise;
  final String name;
  final String type;
  final String level;
  final bool isDark;

  const _ExerciseCard({
    required this.exercise,
    required this.name,
    required this.type,
    required this.level,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isDark ? 0 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isDark
            ? BorderSide(color: Theme.of(context).dividerColor)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ExerciseDetailPage(exercise: exercise),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: 0.2),
                      AppColors.accent.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.fitness_center,
                  color: AppColors.accent,
                  size: 28,
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
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (type.isNotEmpty) _chip(type, AppColors.accent),
                        if (level.isNotEmpty) _chip(level, AppColors.success),
                        if ((exercise['force'] ?? '').toString().isNotEmpty)
                          _chip(
                            (exercise['force']).toString(),
                            AppColors.warning,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Arrow
              Icon(
                Icons.chevron_right,
                color: isDark
                    ? const Color(0xFF8E8E93)
                    : const Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: AppTextStyles.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}
