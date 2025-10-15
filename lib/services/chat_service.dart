import 'dart:convert';
import 'package:final_project/model/message.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ChatService extends ChangeNotifier {
  final _supabaseClient = Supabase.instance.client;
  // Build API URL from .env: CHAT_SERVER + '/chat_health'; fallback to default base
  static String get _apiUrl {
    final raw = (dotenv.env['CHAT_SERVER'] ?? '').trim();
    if (raw.isNotEmpty) {
      final base = raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
      // If the env already includes the endpoint, use as-is
      if (base.endsWith('/chat_health')) return base;
      return "$base/chat_health";
    }
    // Fallback base + path
    return 'https://healthcare-chat-ghmf5cq3za-de.a.run.app/chat_health';
  }

  // Store conversation history in memory
  final List<Map<String, String>> _conversationHistory = [];

  // Chat service implementation
  Stream<List<Message>> getMessages() {
    final userId = _supabaseClient.auth.currentUser?.id ?? '';
    return _supabaseClient
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: true)
        .map(
          (maps) => maps.map((map) => Message.fromJson(map, userId)).toList(),
        );
  }

  Future<void> sendMessage(String content, {String mode = 'meal'}) async {
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw Exception('Not authenticated');
    }

    // Save user message to database (RLS: own rows by user_id)
    final userMessagePayload = {
      'content': content,
      'user_id': userId,
      'role': 'user',
      // rely on DB default now() for created_at
    };
    await _supabaseClient.from('messages').insert(userMessagePayload);

    // Add user message to conversation history
    _conversationHistory.add({'role': 'user', 'content': content});

    // Call healthcare chat API
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'messages': _conversationHistory,
          'mode': mode.toLowerCase(),
          'temperature': 0.2,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponse = data['response'] as String;

        // Add AI response to conversation history
        _conversationHistory.add({'role': 'assistant', 'content': aiResponse});

        // Save AI response to database with current user's ID (owner)
        // Use role=assistant to distinguish bot messages; user_id satisfies RLS
        final aiMessagePayload = {
          'content': aiResponse,
          'user_id': userId,
          'role': 'assistant',
        };
        await _supabaseClient.from('messages').insert(aiMessagePayload);
      } else {
        throw Exception('API request failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get AI response: $e');
    }
  }

  // Clear conversation history
  void clearHistory() {
    _conversationHistory.clear();
    notifyListeners();
  }

  // Get conversation history
  List<Map<String, String>> get conversationHistory =>
      List.unmodifiable(_conversationHistory);
}
