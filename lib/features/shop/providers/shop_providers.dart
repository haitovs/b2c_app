import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/event_service.dart';
import '../services/shop_service.dart';

final shopServiceProvider = Provider<ShopService>((ref) {
  return ShopService(ref.watch(authApiClientProvider));
});

final eventServicesProvider =
    FutureProvider.family<List<EventServiceItem>, int>((ref, eventId) {
  return ref.watch(shopServiceProvider).getServices(eventId);
});

final cartProvider =
    FutureProvider.family<CartSummary, int>((ref, eventId) {
  return ref.watch(shopServiceProvider).getCart(eventId);
});

/// Badge count for cart icon.
final cartBadgeCountProvider = Provider.family<int, int>((ref, eventId) {
  final cartAsync = ref.watch(cartProvider(eventId));
  return cartAsync.when(
    data: (cart) => cart.itemCount,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

final ordersProvider =
    FutureProvider.family<List<Order>, int>((ref, eventId) {
  return ref.watch(shopServiceProvider).getOrders(eventId);
});

/// Fetch a single service detail by ID.
final serviceDetailProvider =
    FutureProvider.family<EventServiceItem, int>((ref, serviceId) {
  return ref.watch(shopServiceProvider).getServiceDetail(serviceId);
});
