import 'package:final_project/model/message.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService extends ChangeNotifier {
  final _supabaseClient = Supabase.instance.client;
  // Chat service implementation
  Stream<List<Message>> getMessages() {
    final userId = _supabaseClient.auth.currentUser?.id ?? '';
    return _supabaseClient
        .from('message')
        .stream(primaryKey: ['id'])
        .order('timestamp', ascending: true)
        .map(
          (maps) => maps
              .map(
                (map) => Message.fromJson(map as Map<String, dynamic>, userId),
              )
              .toList(),
        );
  }

  Future<void> sendMessage(String content) async {
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw Exception('Not authenticated');
    }
    final payload = {
      'content': content,
      'userFrom': userId,
      // Let database default fill timestamp if configured; else send now
      'timestamp': DateTime.now().toIso8601String(),
    };
    await _supabaseClient.from('message').insert(payload);
  }
}
