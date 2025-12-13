import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../auth/services/auth_service.dart';

class ChatMessage {
  final int? id;
  final String content;
  final String role; // USER or ADMIN
  final DateTime? createdAt;
  final String? mediaUrl;

  ChatMessage({
    this.id,
    required this.content,
    required this.role,
    this.createdAt,
    this.mediaUrl,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      content: json['content'] ?? '',
      role: json['role'] ?? 'USER',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      mediaUrl: json['media_url'],
    );
  }

  bool get isFromUser => role == 'USER';
  bool get isFromAdmin => role == 'ADMIN';
}

class HotlineService {
  static const String baseUrl = 'http://127.0.0.1:8000/api/v1';

  final AuthService _authService;

  HotlineService(this._authService);

  Future<String?> _getToken() async {
    // Get token from AuthService (checks both memory and SharedPreferences)
    return await _authService.getToken();
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Get chat history
  Future<List<ChatMessage>> getChatHistory({
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final headers = await _getHeaders();
      final url = '$baseUrl/chat/history?skip=$skip&limit=$limit';
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ChatMessage.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  /// Send a message via REST API
  Future<bool> sendMessage(String content) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/chat/send?content=${Uri.encodeComponent(content)}'),
        headers: headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Exception sending message: $e');
      return false;
    }
  }

  /// Get WebSocket URL for real-time chat
  Future<String?> getWebSocketUrl() async {
    final token = await _getToken();
    if (token == null) return null;
    return 'ws://127.0.0.1:8000/api/v1/chat/ws?token=$token';
  }
}
