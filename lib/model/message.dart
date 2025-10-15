// ignore_for_file: public_member_api_docs, sort_constructors_first

class Message {
  final String id;
  final String content;
  final DateTime timestamp;
  final String userFrom; // owner/user_id in DB
  final bool isMine;
  final bool isBot; // true if role is assistant/system

  Message({
    required this.id,
    required this.content,
    required this.timestamp,
    required this.userFrom,
    required this.isMine,
    this.isBot = false,
  });

  Message.create({required this.content, required this.userFrom})
    : id = '',
      isMine = true,
      isBot = false,
      timestamp = DateTime.now();

  Message.fromJson(Map<String, dynamic> json, String currentUserId)
    : id = json['id'] as String,
      content = _extractContent(json['content'] as String),
      timestamp = _parseTimestamp(json),
      userFrom = _parseUserFrom(json),
      isBot = _parseIsBot(json),
      isMine = _parseUserFrom(json) == currentUserId && !_parseIsBot(json);

  static String _extractContent(String rawContent) {
    if (rawContent.startsWith('[AI] ')) {
      return rawContent.substring(5); // Backward-compat: remove '[AI] ' prefix
    }
    return rawContent;
  }

  static DateTime _parseTimestamp(Map<String, dynamic> json) {
    final ts = (json['created_at'] ?? json['timestamp']) as String?;
    if (ts != null) return DateTime.parse(ts);
    return DateTime.now();
  }

  static String _parseUserFrom(Map<String, dynamic> json) {
    final userId = (json['user_id'] ?? json['userFrom']) as String?;
    return userId ?? '';
  }

  static bool _parseIsBot(Map<String, dynamic> json) {
    final role = json['role'] as String?;
    if (role != null) {
      return role.toLowerCase() == 'assistant' ||
          role.toLowerCase() == 'system';
    }
    final content = json['content'] as String? ?? '';
    return content.startsWith('[AI] ');
  }

  Map toMap() {
    return {
      'content': content,
      'user_id': userFrom,
      // Caller may add 'role' if needed
    };
  }
}
