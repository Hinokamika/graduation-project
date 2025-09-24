import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Healthcare MCP API client for making HTTP requests to healthcare services
class HealthcareMcpApi {
  static final String _mcp_server = dotenv.env['MCP_SERVER'] ?? '';
  static final String _chat_server = dotenv.env['CHAT_SERVER'] ?? '';
  static const Duration _timeout = Duration(seconds: 30);

  /// Headers for HTTP requests
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Handles HTTP response and converts to Map
  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final decodedResponse = json.decode(response.body);
        if (decodedResponse is Map<String, dynamic>) {
          return decodedResponse;
        } else {
          return {'data': decodedResponse};
        }
      } catch (e) {
        throw Exception('Failed to parse response: $e');
      }
    } else {
      String errorMessage = 'Request failed';
      try {
        final errorData = json.decode(response.body);
        if (errorData is Map && errorData.containsKey('message')) {
          errorMessage = errorData['message'];
        }
      } catch (_) {
        errorMessage = 'Request failed with status: ${response.statusCode}';
      }
      throw Exception(errorMessage);
    }
  }

  /// Generate personalized health plan based on user parameters
  static Future<Map<String, dynamic>> generatePlan({
    required int age,
    required num weight,
    required num height,
    required String goal,
    required String dietType,
    required String fitnessLevel,
  }) async {
    try {
      final data = {
        'age': age,
        'weight': weight,
        'height': height,
        'goal': goal,
        'diet_type': dietType,
        'fitness_level': fitnessLevel,
      };

      final url = Uri.parse('$_mcp_server/generate_plan');

      final response = await http
          .post(url, headers: _headers, body: json.encode(data))
          .timeout(_timeout);

      return _handleResponse(response);
    } on SocketException {
      throw Exception('No internet connection');
    } on HttpException catch (e) {
      throw Exception('HTTP error: ${e.message}');
    } on FormatException {
      throw Exception('Invalid response format');
    } catch (e) {
      throw Exception('Generate plan request failed: $e');
    }
  }

  /// Send messages to healthcare chat server
  static Future<Map<String, dynamic>> sendChatMessage({
    required List<Map<String, String>> messages,
    required String mode,
  }) async {
    try {
      final data = {'messages': messages, 'mode': mode};

      final url = Uri.parse('$_chat_server/chat');

      final response = await http
          .post(url, headers: _headers, body: json.encode(data))
          .timeout(_timeout);

      return _handleResponse(response);
    } on SocketException {
      throw Exception('No internet connection');
    } on HttpException catch (e) {
      throw Exception('HTTP error: ${e.message}');
    } on FormatException {
      throw Exception('Invalid response format');
    } catch (e) {
      throw Exception('Chat request failed: $e');
    }
  }
}
