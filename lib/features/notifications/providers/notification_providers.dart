import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../services/notification_service.dart';

/// Provider for NotificationService.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref.watch(authApiClientProvider));
});

/// Fetch notifications — auto-refreshes every 30 seconds.
final notificationsProvider =
    FutureProvider<List<NotificationItem>>((ref) async {
  final notifications = await ref.watch(notificationServiceProvider).getNotifications();

  // Set up periodic refresh every 30 seconds
  final timer = Timer(const Duration(seconds: 30), () {
    ref.invalidateSelf();
  });
  ref.onDispose(timer.cancel);

  return notifications;
});

/// Unread notification count.
final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider);
  return notifications.maybeWhen(
    data: (items) => items.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});
