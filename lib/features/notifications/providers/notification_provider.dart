import 'package:flutter/material.dart';

import '../../../core/services/api_client.dart';
import '../services/notification_service.dart';

/// Simple ChangeNotifier-based notification provider
/// Can be used with Provider package for state management
class NotificationProvider extends ChangeNotifier {
  late final NotificationService _service;

  List<NotificationItem> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;

  List<NotificationItem> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  NotificationProvider(ApiClient apiClient) {
    _service = NotificationService(apiClient);
  }

  Future<void> fetchNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _notifications = await _service.getNotifications();
      _unreadCount = _notifications.where((n) => !n.isRead).length;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(int id) async {
    await _service.markAsRead(id);
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
      _unreadCount = _notifications.where((n) => !n.isRead).length;
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    await _service.markAllAsRead();
    _notifications = _notifications.map((n) {
      return NotificationItem(
        id: n.id,
        title: n.title,
        body: n.body,
        isRead: true,
        relatedEntityType: n.relatedEntityType,
        relatedEntityId: n.relatedEntityId,
        createdAt: n.createdAt,
      );
    }).toList();
    _unreadCount = 0;
    notifyListeners();
  }
}

