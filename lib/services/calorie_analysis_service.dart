import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ItemMacros {
  final double? proteinG;
  final double? carbsG;
  final double? fatG;
  final double? fiberG;
  final double? sugarG;
  final double? saturatedFatG;
  final double? sodiumMg;

  const ItemMacros({
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.fiberG,
    this.sugarG,
    this.saturatedFatG,
    this.sodiumMg,
  });
}

class FoodItemEstimate {
  final String name;
  final String? portionSize;
  final double calories;
  final ItemMacros? macros;
  const FoodItemEstimate({
    required this.name,
    required this.calories,
    this.portionSize,
    this.macros,
  });
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
  final double? fiberG;
  final double? saturatedFatG;
  final double? sodiumMg;
  final String? confidenceLevel;
  final MealQuality? mealQuality;

  const CalorieAnalysisResult({
    required this.success,
    required this.totalKcal,
    required this.items,
    this.reasoning,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.sugarG,
    this.fiberG,
    this.saturatedFatG,
    this.sodiumMg,
    this.confidenceLevel,
    this.mealQuality,
  });
}

class MealQuality {
  final int? balanceScore;
  final String? notes;
  const MealQuality({this.balanceScore, this.notes});
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
    final totalStr = (data['total_calories'] ?? data['total'] ?? data['total_kcal'] ?? '0').toString();
    final total = double.tryParse(totalStr) ?? 0.0;
    final itemsRaw = data['food_items'];
    final items = <FoodItemEstimate>[];
    if (itemsRaw is List) {
      for (final it in itemsRaw) {
        if (it is Map) {
          final m = Map<String, dynamic>.from(it);
          // Parse per-item macros if provided
          double? _asD(dynamic v) {
            if (v == null) return null;
            if (v is num) return v.toDouble();
            return double.tryParse(v.toString());
          }
          final mm = (m['macros'] is Map)
              ? Map<String, dynamic>.from(m['macros'] as Map)
              : const <String, dynamic>{};
          final macros = (mm.isNotEmpty)
              ? ItemMacros(
                  proteinG: _asD(mm['protein_g']),
                  carbsG: _asD(mm['carbs_g']),
                  fatG: _asD(mm['fat_g']),
                  fiberG: _asD(mm['fiber_g']),
                  sugarG: _asD(mm['sugar_g'] ?? mm['sugars_g']),
                  saturatedFatG: _asD(mm['saturated_fat_g']),
                  sodiumMg: _asD(mm['sodium_mg']),
                )
              : null;
          items.add(
            FoodItemEstimate(
              name: (m['name'] ?? '').toString(),
              calories: double.tryParse((m['calories'] ?? '0').toString()) ?? 0.0,
              portionSize: (m['portion_size']?.toString()),
              macros: macros,
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
    final fiberG = _asDouble(macros['fiber_g']);
    final saturatedFatG = _asDouble(macros['saturated_fat_g']);
    final sodiumMg = _asDouble(macros['sodium_mg']);
    MealQuality? mealQuality;
    if (data['meal_quality'] is Map) {
      final mq = Map<String, dynamic>.from(data['meal_quality'] as Map);
      mealQuality = MealQuality(
        balanceScore: (mq['balance_score'] is num) ? (mq['balance_score'] as num).toInt() : int.tryParse('${mq['balance_score']}'),
        notes: mq['notes']?.toString(),
      );
    }
    final confidenceLevel = data['confidence_level']?.toString();
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
      fiberG: fiberG,
      saturatedFatG: saturatedFatG,
      sodiumMg: sodiumMg,
      confidenceLevel: confidenceLevel,
      mealQuality: mealQuality,
    );
  }
}
