import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../auth/services/auth_service.dart';

/// Model for a feedback item
class FeedbackItem {
  final String id;
  final int eventId;
  final String userName;
  final String content;
  final String createdAt;

  FeedbackItem({
    required this.id,
    required this.eventId,
    required this.userName,
    required this.content,
    required this.createdAt,
  });

  factory FeedbackItem.fromJson(Map<String, dynamic> json) {
    return FeedbackItem(
      id: json['id'] ?? '',
      eventId: json['event_id'] ?? 0,
      userName: json['user_name'] ?? 'Anonymous',
      content: json['content'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}

/// Service for managing event feedback
class FeedbackService {
  final String _baseUrl = AppConfig.b2cApiBaseUrl;
  final AuthService _authService = AuthService();

  /// Get feedback status (open/closed) for an event
  Future<bool> getFeedbackStatus(int eventId) async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/feedbacks/$eventId/status'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['is_open'] ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('Error getting feedback status: $e');
      return false;
    }
  }

  /// Get all feedback for an event
  Future<List<FeedbackItem>> getFeedbacks(int eventId) async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/feedbacks/$eventId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => FeedbackItem.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting feedbacks: $e');
      return [];
    }
  }

  /// Submit feedback for an event
  Future<bool> submitFeedback(int eventId, String content) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        debugPrint('No auth token for feedback submission');
        return false;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/feedbacks/$eventId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'content': content}),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        debugPrint(
          'Failed to submit feedback: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error submitting feedback: $e');
      return false;
    }
  }
}
