import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:final_project/utils/app_colors.dart';
import 'package:final_project/utils/text_styles.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ExerciseDetailPage extends StatefulWidget {
  final Map<String, dynamic> exercise;
  const ExerciseDetailPage({super.key, required this.exercise});

  @override
  State<ExerciseDetailPage> createState() => _ExerciseDetailPageState();
}

class _ExerciseDetailPageState extends State<ExerciseDetailPage> {

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = (widget.exercise['name'] ?? 'Exercise').toString();
    final type = (widget.exercise['type'] ?? '').toString();
    final level = (widget.exercise['level'] ?? '').toString();
    final force = (widget.exercise['force'] ?? '').toString();
    // Equipment may be a list; if it's empty, don't show it.
    final equipment = _fmtList(widget.exercise['equipment']);
    final primary = _fmtList(
      widget.exercise['primary_muscles'] ?? widget.exercise['primaryMuscles'],
    );
    final secondary = _fmtList(
      widget.exercise['secondary_muscles'] ??
          widget.exercise['secondaryMuscles'],
    );
    final instructionsList = _parseInstructions(widget.exercise['instructions']);
    final youtubeLink = _getYoutubeLink(widget.exercise);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: FaIcon(
            FontAwesomeIcons.arrowLeft,
            color: AppColors.getTextPrimary(context),
            size: 18,
          ),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        title: Text(name),
        actions: [
          IconButton(
            onPressed: () => _addToPlan(context, name),
            icon: const FaIcon(FontAwesomeIcons.circlePlus),
            tooltip: 'Add to workout plan',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero section with exercise name and key info
            _buildHeroSection(name, type, level, isDark),
            const SizedBox(height: 24),

            // Key attributes in a grid
            _buildAttributesGrid(type, level, force, equipment, isDark),
            const SizedBox(height: 5),

            // Video section (YouTube)
            if (youtubeLink != null) ...[
              _buildYoutubeSection(youtubeLink, isDark),
              const SizedBox(height: 24),
            ],

            // Muscles section
            if (primary.isNotEmpty || secondary.isNotEmpty) ...[
              _buildMusclesSection(primary, secondary, isDark),
              const SizedBox(height: 24),
            ],

            // Instructions section (bullet points)
            if (instructionsList.isNotEmpty) ...[
              _buildInstructionsSection(instructionsList, isDark),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  // ---- YouTube helpers ----
  String? _getYoutubeLink(Map<String, dynamic> ex) {
    final candidates = [
      ex['youtube_link'],
    ];
    for (final c in candidates) {
      if (c is String && c.trim().isNotEmpty) {
        final s = c.trim();
        if (s.contains('youtu.be') || s.contains('youtube.com')) return s;
      }
    }
    return null;
  }

  String? _extractYoutubeId(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.host.contains('youtu.be')) {
        return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
      }
      if (uri.host.contains('youtube.com')) {
        if (uri.pathSegments.contains('watch')) {
          return uri.queryParameters['v'];
        }
        // Share links like /shorts/ID or /embed/ID
        if (uri.pathSegments.isNotEmpty) {
          final idx = uri.pathSegments.length - 1;
          return uri.pathSegments[idx];
        }
      }
    } catch (_) {}
    return null;
  }

  Widget _buildYoutubeSection(String url, bool isDark) {
    final id = _extractYoutubeId(url);
    final thumb = id != null
        ? 'https://img.youtube.com/vi/$id/hqdefault.jpg'
        : null;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF38383A) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Video',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _launchExternal(url),
                child: const Text('Open'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _launchExternal(url),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (thumb != null)
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        thumb,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    padding: const EdgeInsets.all(10),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchExternal(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // Fallback toast
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open YouTube link')),
        );
      }
    }
  }

  Widget _buildHeroSection(
    String name,
    String type,
    String level,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withValues(alpha: 0.15),
            AppColors.accent.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    if (type.isNotEmpty) _smallChip(type, AppColors.accent),
                    if (level.isNotEmpty) _smallChip(level, AppColors.success),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttributesGrid(
    String type,
    String level,
    String force,
    String equipment,
    bool isDark,
  ) {
    final attributes = <Map<String, dynamic>>[
      if (type.isNotEmpty)
        {
          'icon': FontAwesomeIcons.tags,
          'label': 'Type',
          'value': type,
          'color': AppColors.accent,
        },
      if (level.isNotEmpty)
        {
          'icon': FontAwesomeIcons.arrowTrendUp,
          'label': 'Level',
          'value': level,
          'color': AppColors.success,
        },
      if (force.isNotEmpty)
        {
          'icon': FontAwesomeIcons.bolt,
          'label': 'Force',
          'value': force,
          'color': AppColors.warning,
        },
      if (equipment.isNotEmpty)
        {
          'icon': FontAwesomeIcons.screwdriverWrench,
          'label': 'Equipment',
          'value': equipment,
          'color': AppColors.primary,
        },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        // Make tiles a bit taller to avoid small text overflows on some devices
        childAspectRatio: 1.6,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: attributes.length,
      itemBuilder: (context, index) {
        final attr = attributes[index];
        return _attributeCard(
          attr['icon'] as IconData,
          attr['label'] as String,
          attr['value'] as String,
          attr['color'] as Color,
          isDark,
        );
      },
    );
  }

  Widget _attributeCard(
    IconData icon,
    String label,
    String value,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF38383A) : const Color(0xFFE2E8F0),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: FaIcon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMusclesSection(String primary, String secondary, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF38383A) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Target Muscles',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (primary.isNotEmpty) ...[
            Text(
              'Primary',
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark
                    ? const Color(0xFF8E8E93)
                    : const Color(0xFF64748B),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: primary
                  .split(', ')
                  .map((m) => _muscleChip(m, AppColors.healthPrimary, true))
                  .toList(),
            ),
          ],
          if (primary.isNotEmpty && secondary.isNotEmpty)
            const SizedBox(height: 16),
          if (secondary.isNotEmpty) ...[
            Text(
              'Secondary',
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark
                    ? const Color(0xFF8E8E93)
                    : const Color(0xFF64748B),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: secondary
                  .split(', ')
                  .map((m) => _muscleChip(m, AppColors.textLight, false))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  List<String> _parseInstructions(dynamic raw) {
    if (raw is List) {
      return raw.whereType<String>().map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }
    if (raw is String) {
      return raw
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return const [];
  }

  Widget _buildInstructionsSection(List<String> steps, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF38383A) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Instructions',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(steps.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: FaIcon(
                      FontAwesomeIcons.circle,
                      size: 8,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      steps[i],
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isDark
                            ? const Color(0xFFF2F2F7)
                            : const Color(0xFF1E293B),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }


  void _addToPlan(BuildContext context, String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "$name" to your workout plan!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'VIEW',
          textColor: Colors.white,
          onPressed: () {
            // Navigate to workout plan
          },
        ),
      ),
    );
  }

  Widget _smallChip(String text, Color color) {
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

  Widget _muscleChip(String text, Color color, bool isPrimary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isPrimary ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
            isPrimary ? FontAwesomeIcons.solidStar : FontAwesomeIcons.star,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _allFieldsView(Map<String, dynamic> data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final entries =
        data.entries.map((e) => MapEntry(e.key.toString(), e.value)).toList()
          ..sort((a, b) => a.key.compareTo(b.key));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF38383A) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final entry in entries) ...[
            _fieldItem(entry.key, entry.value, 0, isDark),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _fieldItem(String key, dynamic value, int depth, bool isDark) {
    final labelStyle = AppTextStyles.bodySmall.copyWith(
      color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF64748B),
      fontWeight: FontWeight.w700,
    );
    return Padding(
      padding: EdgeInsets.only(left: (depth * 12).toDouble()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(key, style: labelStyle),
          const SizedBox(height: 6),
          _valueWidget(value, depth, isDark),
        ],
      ),
    );
  }

  Widget _valueWidget(dynamic value, int depth, bool isDark) {
    if (value == null) {
      return Text('—', style: AppTextStyles.bodyMedium);
    }
    if (value is bool || value is num || value is String) {
      return Text(
        value.toString(),
        style: AppTextStyles.bodyMedium.copyWith(
          color: isDark ? const Color(0xFFF2F2F7) : const Color(0xFF1E293B),
        ),
      );
    }
    if (value is List) {
      if (value.isEmpty) return Text('[]', style: AppTextStyles.bodyMedium);
      final allScalars = value.every(
        (e) => e == null || e is bool || e is num || e is String,
      );
      if (allScalars) {
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: value.map((e) => _chip(e?.toString() ?? 'null')).toList(),
        );
      } else {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final item in value) ...[
              _valueWidget(item, depth + 1, isDark),
              const SizedBox(height: 6),
            ],
          ],
        );
      }
    }
    if (value is Map) {
      final entries =
          value.entries.map((e) => MapEntry(e.key.toString(), e.value)).toList()
            ..sort((a, b) => a.key.compareTo(b.key));
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? const Color(0xFF38383A) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final entry in entries) ...[
              _fieldItem(entry.key, entry.value, depth + 1, isDark),
              const SizedBox(height: 8),
            ],
          ],
        ),
      );
    }
    // Fallback for other types (e.g., ObjectId)
    return Text(
      value.toString(),
      style: AppTextStyles.bodyMedium.copyWith(
        color: isDark ? const Color(0xFFF2F2F7) : const Color(0xFF1E293B),
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.accent,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _fmtList(dynamic value) {
    if (value == null) return '';
    if (value is List) {
      return value.whereType<String>().join(', ');
    }
    return value.toString();
  }
}
