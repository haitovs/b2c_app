import 'package:flutter/foundation.dart';

import '../../../core/services/api_client.dart';
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
  final ApiClient _api;

  List<NotificationItem> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;

  List<NotificationItem> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  NotificationService(AuthService authService) : _api = ApiClient(authService);

  /// Fetch all notifications for current user
  Future<List<NotificationItem>> getNotifications() async {
    _isLoading = true;
    notifyListeners();

    final result = await _api.get<List<dynamic>>('/api/v1/notifications/');

    if (result.isSuccess && result.data != null) {
      _notifications = result.data!
          .map((json) => NotificationItem.fromJson(json))
          .toList();
      _updateUnreadCount();
    }

    _isLoading = false;
    notifyListeners();
    return _notifications;
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
    final result = await _api.patch<Map<String, dynamic>>(
      '/api/v1/notifications/$id/read',
    );

    if (result.isSuccess) {
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
