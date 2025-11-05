import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:final_project/utils/app_colors.dart';
import 'package:final_project/utils/text_styles.dart';
import 'package:final_project/services/nutrition_service.dart';

class NutritionHistoryPage extends StatefulWidget {
  const NutritionHistoryPage({super.key});

  @override
  State<NutritionHistoryPage> createState() => _NutritionHistoryPageState();
}

class _NutritionHistoryPageState extends State<NutritionHistoryPage> {
  final _service = NutritionService();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await _service.getGoalHistory();
      if (!mounted) return;
      setState(() => _rows = rows);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition Goal History'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(FontAwesomeIcons.chevronLeft),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _errorView()
          : _rows.isEmpty
          ? _emptyView()
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _rows.length,
                itemBuilder: (context, i) => _rowCard(_rows[i]),
              ),
            ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          _error ?? 'Error',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _emptyView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(FontAwesomeIcons.circleInfo, size: 40),
          const SizedBox(height: 12),
          Text('No nutrition goals saved yet', style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  Widget _rowCard(Map<String, dynamic> m) {
    final createdAt = DateTime.tryParse(m['created_at']?.toString() ?? '');
    final goal = (m['goal'] ?? '').toString();
    final delta = m['delta_percent']?.toString();
    final kcal = m['calories_target']?.toString();
    final carbs = m['carbs_g']?.toString();
    final protein = m['protein_g']?.toString();
    final fat = m['fat_g']?.toString();
    final sugar = m['sugar_g']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.getBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(FontAwesomeIcons.sliders, size: 14),
              const SizedBox(width: 8),
              Text(
                'Goal: $goal  ${delta != null ? '($delta%)' : ''}',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (createdAt != null)
                Text(
                  createdAt.toLocal().toString().split(' ')[0],
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              if (kcal != null)
                _chip(FontAwesomeIcons.fire, '$kcal kcal', AppColors.accent),
              if (carbs != null)
                _chip(
                  FontAwesomeIcons.breadSlice,
                  '${carbs}g',
                  AppColors.primary,
                ),
              if (protein != null)
                _chip(FontAwesomeIcons.egg, '${protein}g', AppColors.accent),
              if (fat != null)
                _chip(FontAwesomeIcons.droplet, '${fat}g', AppColors.warning),
              if (sugar != null)
                _chip(FontAwesomeIcons.cubes, '${sugar}g', AppColors.info),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(text, style: AppTextStyles.bodySmall.copyWith(color: color)),
        ],
      ),
    );
  }
}
