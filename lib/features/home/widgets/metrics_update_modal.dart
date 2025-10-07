import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/text_styles.dart';

class MetricsUpdateModal extends StatefulWidget {
  final Function({
    int? steps,
    int? calories,
    int? standingTimeMinutes,
    double? sleepHours,
    int? standingMinutes,
    int? heartRateAvg,
    String? sleepStartTime,
  })
  onSave;

  const MetricsUpdateModal({super.key, required this.onSave});

  @override
  State<MetricsUpdateModal> createState() => _MetricsUpdateModalState();
}

class _MetricsUpdateModalState extends State<MetricsUpdateModal> {
  final _stepsController = TextEditingController();
  final _kcalController = TextEditingController();
  final _standingTimeController = TextEditingController();
  final _sleepController = TextEditingController();
  final _standController = TextEditingController();
  final _hrController = TextEditingController();
  TimeOfDay? _sleepStart;
  bool _isLoading = false;

  @override
  void dispose() {
    _stepsController.dispose();
    _kcalController.dispose();
    _standingTimeController.dispose();
    _sleepController.dispose();
    _standController.dispose();
    _hrController.dispose();
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildMetricsForm(),
            const SizedBox(height: 20),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text('Update Today\'s Metrics', style: AppTextStyles.titleLarge),
        const Spacer(),
        IconButton(
          icon: const FaIcon(FontAwesomeIcons.xmark),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildMetricsForm() {
    return Column(
      children: [
        _buildMetricField(
          label: 'Steps',
          controller: _stepsController,
          hint: 'e.g. 8500',
          icon: FontAwesomeIcons.person,
          keyboard: TextInputType.number,
        ),
        const SizedBox(height: 12),
        _buildMetricField(
          label: 'Calories (kcal)',
          controller: _kcalController,
          hint: 'e.g. 1850',
          icon: FontAwesomeIcons.fireFlameCurved,
          keyboard: TextInputType.number,
        ),
        const SizedBox(height: 12),
        _buildMetricField(
          label: 'Standing Time (hours)',
          controller: _standingTimeController,
          hint: 'e.g. 12.0',
          icon: FontAwesomeIcons.personWalking,
          keyboard: TextInputType.number,
        ),
        const SizedBox(height: 12),
        _buildMetricField(
          label: 'Sleep (hours)',
          controller: _sleepController,
          hint: 'e.g. 7.5',
          icon: FontAwesomeIcons.bed,
          keyboard: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 12),
        _buildMetricField(
          label: 'Standing time (hours)',
          controller: _standController,
          hint: 'e.g. 0.8',
          icon: FontAwesomeIcons.user,
          keyboard: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 12),
        _buildMetricField(
          label: 'Heart rate avg (bpm)',
          controller: _hrController,
          hint: 'e.g. 72',
          icon: FontAwesomeIcons.heart,
          keyboard: TextInputType.number,
        ),
        const SizedBox(height: 16),
        _buildSleepTimePicker(),
      ],
    );
  }

  Widget _buildMetricField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required TextInputType keyboard,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: controller,
                keyboardType: keyboard,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  hintText: hint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSleepTimePicker() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.sleep.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const FaIcon(
            FontAwesomeIcons.moon,
            color: AppColors.sleep,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sleep start time',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: _isLoading ? null : _pickSleepTime,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _sleepStart == null
                        ? 'Pick time'
                        : _formatTime(_sleepStart!),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: _sleepStart == null
                          ? Theme.of(context).hintColor
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ],
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
          backgroundColor: AppColors.accent,
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
                'Save Metrics',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Future<void> _pickSleepTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _sleepStart ?? const TimeOfDay(hour: 22, minute: 0),
    );
    if (picked != null) {
      setState(() => _sleepStart = picked);
    }
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _handleSave() async {
    setState(() => _isLoading = true);

    try {
      final steps = int.tryParse(
        _stepsController.text.replaceAll(',', '').trim(),
      );
      final kcal = int.tryParse(
        _kcalController.text.replaceAll(',', '').trim(),
      );
      final standingTime = double.tryParse(
        _standingTimeController.text.replaceAll(',', '.').trim(),
      );
      final sleep = double.tryParse(
        _sleepController.text.replaceAll(',', '.').trim(),
      );
      final stand = double.tryParse(
        _standController.text.replaceAll(',', '.').trim(),
      );
      final hr = int.tryParse(_hrController.text.replaceAll(',', '').trim());
      final sleepTimeStr = _sleepStart == null
          ? null
          : _formatTime(_sleepStart!);

      await widget.onSave(
        steps: steps,
        calories: kcal,
        standingTimeMinutes: standingTime != null
            ? (standingTime * 60).round()
            : null,
        sleepHours: sleep,
        standingMinutes: stand != null ? (stand * 60).round() : null,
        heartRateAvg: hr,
        sleepStartTime: sleepTimeStr,
      );

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
}
