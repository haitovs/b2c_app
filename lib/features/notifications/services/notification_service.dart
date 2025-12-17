import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../auth/services/auth_service.dart';

/// Notification model
class NotificationItem {
  final int id;
  final String title;
  final String body;
  final bool isRead;
  final String? relatedEntityType;
  final String? relatedEntityId;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    this.relatedEntityType,
    this.relatedEntityId,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      isRead: json['is_read'] ?? false,
      relatedEntityType: json['related_entity_type'],
      relatedEntityId: json['related_entity_id'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}

/// Service for managing notifications
class NotificationService extends ChangeNotifier {
  final String baseUrl = '${AppConfig.b2cApiBaseUrl}/api/v1';
  final AuthService _authService;

  List<NotificationItem> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;

  List<NotificationItem> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  NotificationService(this._authService);

  /// Get authorization headers
  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Fetch all notifications for current user
  Future<List<NotificationItem>> getNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/notifications/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _notifications = data
            .map((json) => NotificationItem.fromJson(json))
            .toList();
        _updateUnreadCount();
        _isLoading = false;
        notifyListeners();
        return _notifications;
      }

      _isLoading = false;
      notifyListeners();
      return [];
    } catch (e) {
      debugPrint("Error fetching notifications: $e");
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

  /// Get unread notification count
  int getUnreadCount() {
    return _notifications.where((n) => !n.isRead).length;
  }

  void _updateUnreadCount() {
    _unreadCount = getUnreadCount();
  }

  /// Mark a notification as read
  Future<bool> markAsRead(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/notifications/$id/read'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        // Update local state
        final index = _notifications.indexWhere((n) => n.id == id);
        if (index != -1) {
          _notifications[index] = NotificationItem(
            id: _notifications[index].id,
            title: _notifications[index].title,
            body: _notifications[index].body,
            isRead: true,
            relatedEntityType: _notifications[index].relatedEntityType,
            relatedEntityId: _notifications[index].relatedEntityId,
            createdAt: _notifications[index].createdAt,
          );
          _updateUnreadCount();
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error marking notification as read: $e");
      return false;
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    for (var notification in _notifications.where((n) => !n.isRead)) {
      await markAsRead(notification.id);
    }
  }

  /// Clear all notifications (local only)
  void clearNotifications() {
    _notifications = [];
    _unreadCount = 0;
    notifyListeners();
  }
}
