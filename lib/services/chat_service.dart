import 'dart:async';
import 'dart:convert';
import 'package:final_project/model/message.dart';
// ChangeNotifier is in foundation; no need for material
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ChatService extends ChangeNotifier {
  final _supabaseClient = Supabase.instance.client;
  static final http.Client _httpClient = http.Client();
  // Build API URL strictly from .env: CHAT_SERVER must be a full endpoint
  static String get _apiUrl {
    final url = (dotenv.env['CHAT_SERVER'] ?? '').trim();
    if (url.isEmpty) {
      throw StateError('CHAT_SERVER is not configured in .env');
    }
    if (kDebugMode) {
      if (url.endsWith('/mcp')) {
        debugPrint(
          '[ChatService] CHAT_SERVER points to /mcp. The chat page expects the full chat endpoint (e.g., "/chat_health"). Current: $url',
        );
      }
      if (!url.startsWith('http')) {
        debugPrint(
          '[ChatService] CHAT_SERVER does not look like a valid URL: $url',
        );
      }
    }
    return url;
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
        .limit(100)
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
    // Fire-and-forget insert to reduce perceived latency
    // Errors are logged but do not block the chat request
    unawaited(
      _supabaseClient.from('messages').insert(userMessagePayload).catchError((
        e,
      ) {
        if (kDebugMode)
          debugPrint('[ChatService] insert user message failed: $e');
      }),
    );

    // Add user message to conversation history
    _conversationHistory.add({'role': 'user', 'content': content});

    // Call healthcare chat API
    try {
      if (kDebugMode) {
        debugPrint('[ChatService] POST $_apiUrl');
      }
      final response = await _httpClient
          .post(
            Uri.parse(_apiUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'messages': _conversationHistory,
              'mode': mode.toLowerCase(),
              'temperature': 0.2,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        var aiResponse = data['response'] as String;

        // Remove asterisks (markdown formatting)
        aiResponse = aiResponse.replaceAll('*', '');

        // Add AI response to conversation history
        _conversationHistory.add({'role': 'assistant', 'content': aiResponse});

        // Save AI response to database with current user's ID (owner)
        // Use role=assistant to distinguish bot messages; user_id satisfies RLS
        final aiMessagePayload = {
          'content': aiResponse,
          'user_id': userId,
          'role': 'assistant',
        };
        // Fire-and-forget insert of AI response
        unawaited(
          _supabaseClient.from('messages').insert(aiMessagePayload).catchError((
            e,
          ) {
            if (kDebugMode) {
              debugPrint('[ChatService] insert AI message failed: $e');
            }
          }),
        );
      } else {
        final snippet = response.body.length > 200
            ? '${response.body.substring(0, 200)}...'
            : response.body;
        throw Exception(
          'API request failed ${response.statusCode} @ $_apiUrl: $snippet',
        );
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
