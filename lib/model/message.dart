// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/cupertino.dart';

class Message {
  final String id;
  final String content;
  final DateTime timestamp;
  final String userFrom;
  final bool isMine;
  Message({
    required this.id,
    required this.content,
    required this.timestamp,
    required this.userFrom,
    required this.isMine,
  });

  Message.create({
    required this.content,
    required this.userFrom,
  }) : id = '',
        isMine = true,
       timestamp = DateTime.now();

  Message.fromJson(Map<String, dynamic> json, String currentUserId)
      : id = json['id'] as String,
        content = json['content'] as String,
        timestamp = DateTime.parse(json['timestamp'] as String),
        userFrom = json['userFrom'] as String,
        isMine = (json['userFrom'] as String) == currentUserId;

  Map toMap() {
    return {
      'content': content,
      'userFrom': userFrom,
    };
  }
}
