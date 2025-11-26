import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:final_project/api/healthcare_mcp_api.dart';
import 'package:final_project/features/plan/plan_result_page.dart';

class PlanLoadingPage extends StatefulWidget {
  final Map<String, dynamic> survey;

  const PlanLoadingPage({super.key, required this.survey});

  @override
  State<PlanLoadingPage> createState() => _PlanLoadingPageState();
}

class _PlanLoadingPageState extends State<PlanLoadingPage> {
  String? _error;
  static const Duration _minLoadingDuration = Duration(seconds: 60);

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    setState(() => _error = null);
    final startTime = DateTime.now();
    try {
      final payload = _buildPayload(widget.survey);
      final plan = await HealthcareMcpApi.generatePlan(
        age: payload['age'] as int,
        weight: payload['weight'] as num,
        height: payload['height'] as num,
        goal: payload['goal'] as String,
        dietType: payload['diet_type'] as String,
        fitnessLevel: payload['fitness_level'] as String,
      );
      // Ensure a minimum loading time for better UX / AI response feel
      final elapsed = DateTime.now().difference(startTime);
      if (elapsed < _minLoadingDuration) {
        await Future.delayed(_minLoadingDuration - elapsed);
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PlanResultPage(survey: widget.survey, plan: plan),
        ),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Map<String, dynamic> _buildPayload(Map<String, dynamic> survey) {
    final age = (survey['age'] is num)
        ? (survey['age'] as num).toInt()
        : int.tryParse('${survey['age']}') ?? 30;
    final weight = (survey['weight'] is num)
        ? (survey['weight'] as num)
        : num.tryParse('${survey['weight']}') ?? 70;
    var height = (survey['height'] is num)
        ? (survey['height'] as num)
        : num.tryParse('${survey['height']}') ?? 1.7;
    // If height looks like centimeters, convert to meters
    if (height > 3) height = height / 100.0;

    // Survey currently stores weight goal under `diet_type` values.
    final rawGoal = (survey['diet_type'] ?? survey['goal'])?.toString() ?? '';
    final goal = switch (rawGoal) {
      'lost_weight' => 'lose_weight',
      'lose_weight' => 'lose_weight',
      'maintain_weight' => 'maintain_weight',
      'gain_weight' => 'gain_weight',
      _ => 'maintain_weight',
    };

    final fitness = (survey['activity_level']?.toString() ?? 'beginner');
    // No dietary preference captured yet; default to omnivore
    const dietType = 'omnivore';

    return {
      'age': age,
      'weight': weight,
      'height': height,
      'goal': goal,
      'diet_type': dietType,
      'fitness_level': fitness,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 18),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        title: const Text('Generating Your Plan'),
      ),
      body: Center(
        child: _error == null
            ? const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Please wait while we build your plan...'),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.circleExclamation,
                      color: Colors.red,
                      size: 44,
                    ),
                    const SizedBox(height: 12),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _start,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
