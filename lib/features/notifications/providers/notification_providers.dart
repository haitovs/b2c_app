import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../services/notification_service.dart';

/// Provider for NotificationService.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref.watch(authApiClientProvider));
});

/// Fetch notifications.
final notificationsProvider =
    FutureProvider<List<NotificationItem>>((ref) {
  return ref.watch(notificationServiceProvider).getNotifications();
});

/// Unread notification count.
final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider);
  return notifications.maybeWhen(
    data: (items) => items.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});
