import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class FoodItemEstimate {
  final String name;
  final double calories;
  const FoodItemEstimate({required this.name, required this.calories});
}

class CalorieAnalysisResult {
  final bool success;
  final double totalKcal;
  final List<FoodItemEstimate> items;
  final String? reasoning;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;
  final double? sugarG;

  const CalorieAnalysisResult({
    required this.success,
    required this.totalKcal,
    required this.items,
    this.reasoning,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.sugarG,
  });
}

class CalorieAnalysisService {
  static final String _endpoint = dotenv.env['FOOD_SERVER'] ?? '';

  static Future<CalorieAnalysisResult> analyzeImageBytes(
    List<int> fileBytes, {
    String filename = 'image.jpg',
  }) async {
    final uri = Uri.parse(_endpoint);
    final req = http.MultipartRequest('POST', uri)
      ..headers['Accept'] = 'application/json'
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: filename,
          contentType: null,
        ),
      );

    final streamed = await req.send();
    final resp = await http.Response.fromStream(streamed);
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Calorie analysis failed (${resp.statusCode})');
    }

    Map<String, dynamic> json;
    try {
      json = jsonDecode(resp.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Unexpected response from analyzer');
    }

    final data = (json['data'] is Map)
        ? Map<String, dynamic>.from(json['data'] as Map)
        : <String, dynamic>{};
    final totalStr = (data['total'] ?? '0').toString();
    final total = double.tryParse(totalStr) ?? 0.0;
    final itemsRaw = data['food_items'];
    final items = <FoodItemEstimate>[];
    if (itemsRaw is List) {
      for (final it in itemsRaw) {
        if (it is Map) {
          final m = Map<String, dynamic>.from(it);
          items.add(
            FoodItemEstimate(
              name: (m['name'] ?? '').toString(),
              calories:
                  double.tryParse((m['calories'] ?? '0').toString()) ?? 0.0,
            ),
          );
        }
      }
    }
    final reasoning = data['reasoning']?.toString();
    // Parse optional macros
    double? _asDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }
    final macros = (data['macros'] is Map)
        ? Map<String, dynamic>.from(data['macros'] as Map)
        : const <String, dynamic>{};
    final proteinG = _asDouble(macros['protein_g']);
    final carbsG = _asDouble(macros['carbs_g']);
    final fatG = _asDouble(macros['fat_g']);
    final sugarG = _asDouble(macros['sugar_g'] ?? macros['sugars_g']);
    final success = (json['success'] == true);
    return CalorieAnalysisResult(
      success: success,
      totalKcal: total,
      items: items,
      reasoning: reasoning,
      proteinG: proteinG,
      carbsG: carbsG,
      fatG: fatG,
      sugarG: sugarG,
    );
  }
}
