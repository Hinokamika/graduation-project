import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/text_styles.dart';
import '../models/health_metrics.dart';

class TargetEditModal extends StatefulWidget {
  final HealthMetricType type;
  final num currentValue;
  final Function(num) onSave;

  const TargetEditModal({
    super.key,
    required this.type,
    required this.currentValue,
    required this.onSave,
  });

  @override
  State<TargetEditModal> createState() => _TargetEditModalState();
}

class _TargetEditModalState extends State<TargetEditModal> {
  late final TextEditingController _controller;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentValue.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: media.viewInsets.bottom + 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildTargetField(),
          const SizedBox(height: 20),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(child: Text(_getTitle(), style: AppTextStyles.titleLarge)),
        IconButton(
          icon: const FaIcon(FontAwesomeIcons.xmark),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildTargetField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target Value',
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          keyboardType: _getKeyboardType(),
          enabled: !_isLoading,
          decoration: InputDecoration(
            hintText: _getHint(),
            suffix: Text(
              _getUnit(),
              style: AppTextStyles.bodySmall.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _getDescription(),
          style: AppTextStyles.bodySmall.copyWith(
            color: Theme.of(context).hintColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: _getColor(),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Save Target',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  String _getTitle() {
    switch (widget.type) {
      case HealthMetricType.steps:
        return 'Edit Daily Steps Target';
      case HealthMetricType.calories:
        return 'Edit Daily Calories Target';
      case HealthMetricType.standingTime:
        return 'Edit Daily Standing Time Target';
      case HealthMetricType.sleep:
        return 'Edit Daily Sleep Target';
    }
  }


  Color _getColor() {
    switch (widget.type) {
      case HealthMetricType.steps:
        return AppColors.accent;
      case HealthMetricType.calories:
        return AppColors.warning;
      case HealthMetricType.standingTime:
        return AppColors.healthPrimary;
      case HealthMetricType.sleep:
        return AppColors.info;
    }
  }

  String _getUnit() {
    switch (widget.type) {
      case HealthMetricType.steps:
        return 'steps';
      case HealthMetricType.calories:
        return 'kcal';
      case HealthMetricType.standingTime:
        return 'hours';
      case HealthMetricType.sleep:
        return 'hours';
    }
  }

  String _getHint() {
    switch (widget.type) {
      case HealthMetricType.steps:
        return 'e.g. 10000';
      case HealthMetricType.calories:
        return 'e.g. 2200';
      case HealthMetricType.standingTime:
        return 'e.g. 12';
      case HealthMetricType.sleep:
        return 'e.g. 8.0';
    }
  }

  String _getDescription() {
    switch (widget.type) {
      case HealthMetricType.steps:
        return 'Recommended: 8,000-12,000 steps per day for adults';
      case HealthMetricType.calories:
        return 'Varies based on age, gender, and activity level';
      case HealthMetricType.standingTime:
        return 'Recommended: 12+ hours of standing per day';
      case HealthMetricType.sleep:
        return 'Recommended: 7-9 hours per night for adults';
    }
  }

  TextInputType _getKeyboardType() {
    switch (widget.type) {
      case HealthMetricType.steps:
      case HealthMetricType.calories:
      case HealthMetricType.standingTime:
        return TextInputType.number;
      case HealthMetricType.sleep:
        return const TextInputType.numberWithOptions(decimal: true);
    }
  }

  Future<void> _handleSave() async {
    setState(() => _isLoading = true);

    try {
      final text = _controller.text.replaceAll(',', '.').trim();
      num? value;

      switch (widget.type) {
        case HealthMetricType.steps:
        case HealthMetricType.calories:
        case HealthMetricType.standingTime:
          value = int.tryParse(text);
          break;
        case HealthMetricType.sleep:
          value = double.tryParse(text);
          break;
      }

      if (value == null || !_isValidValue(value)) {
        throw Exception('Please enter a valid ${_getUnit()} value');
      }

      await widget.onSave(value);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _isValidValue(num value) {
    switch (widget.type) {
      case HealthMetricType.steps:
        return value > 0 && value <= 100000;
      case HealthMetricType.calories:
        return value > 0 && value <= 10000;
      case HealthMetricType.standingTime:
        return value > 0 && value <= 24; // Max 24 hours
      case HealthMetricType.sleep:
        return value >= 4.0 && value <= 16.0;
    }
  }
}
