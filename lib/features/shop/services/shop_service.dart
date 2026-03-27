import '../../../core/services/api_client.dart';
import '../models/event_service.dart';

class ShopService {
  final ApiClient _api;

  ShopService(this._api);

  // ---------------------------------------------------------------------------
  // Services
  // ---------------------------------------------------------------------------

  Future<List<EventServiceItem>> getServices(int eventId,
      {String? category}) async {
    final queryParams = <String, String>{
      'event_id': eventId.toString(),
      if (category != null) 'category': category,
    };

    final result = await _api.get<List<dynamic>>(
      '/api/v1/shop/services',
      queryParams: queryParams,
      auth: true,
    );

    if (!result.isSuccess) {
      throw Exception(result.error ?? 'Failed to load services');
    }

    return result.data!
        .map((e) => EventServiceItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<EventServiceItem> getServiceDetail(int serviceId) async {
    final result = await _api.get<Map<String, dynamic>>(
      '/api/v1/shop/services/$serviceId',
      auth: true,
    );

    if (!result.isSuccess) {
      throw Exception(result.error ?? 'Failed to load service detail');
    }

    return EventServiceItem.fromJson(result.data!);
  }

  // ---------------------------------------------------------------------------
  // Cart
  // ---------------------------------------------------------------------------

  Future<CartSummary> getCart(int eventId) async {
    final result = await _api.get<Map<String, dynamic>>(
      '/api/v1/shop/cart',
      queryParams: {'event_id': eventId.toString()},
      auth: true,
    );

    if (!result.isSuccess) {
      throw Exception(result.error ?? 'Failed to load cart');
    }

    return CartSummary.fromJson(result.data!);
  }

  Future<CartItem> addToCart(int eventId, int serviceId,
      {int quantity = 1}) async {
    final result = await _api.post<Map<String, dynamic>>(
      '/api/v1/shop/cart?event_id=$eventId',
      body: {
        'service_id': serviceId,
        'quantity': quantity,
      },
      auth: true,
    );

    if (!result.isSuccess) {
      throw Exception(result.error ?? 'Failed to add item to cart');
    }

    return CartItem.fromJson(result.data!);
  }

  Future<CartItem> updateCartItem(String itemId, int quantity) async {
    final result = await _api.put<Map<String, dynamic>>(
      '/api/v1/shop/cart/$itemId',
      body: {'quantity': quantity},
      auth: true,
    );

    if (!result.isSuccess) {
      throw Exception(result.error ?? 'Failed to update cart item');
    }

    return CartItem.fromJson(result.data!);
  }

  Future<void> removeCartItem(String itemId) async {
    final result = await _api.delete<void>(
      '/api/v1/shop/cart/$itemId',
      auth: true,
    );

    if (!result.isSuccess) {
      throw Exception(result.error ?? 'Failed to remove cart item');
    }
  }

  Future<void> clearCart(int eventId) async {
    final result = await _api.delete<void>(
      '/api/v1/shop/cart/clear?event_id=$eventId',
      auth: true,
    );

    if (!result.isSuccess) {
      throw Exception(result.error ?? 'Failed to clear cart');
    }
  }

  // ---------------------------------------------------------------------------
  // Promocode
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> applyPromocode(
      int eventId, String code) async {
    final result = await _api.post<Map<String, dynamic>>(
      '/api/v1/shop/promocode/apply?event_id=$eventId',
      body: {'code': code},
      auth: true,
    );

    if (!result.isSuccess) {
      throw result.error ?? Exception('Failed to apply promocode');
    }

    return result.data!;
  }

  // ---------------------------------------------------------------------------
  // Checkout
  // ---------------------------------------------------------------------------

  Future<Order> checkout(int eventId, {String? promocode}) async {
    final result = await _api.post<Map<String, dynamic>>(
      '/api/v1/shop/checkout?event_id=$eventId',
      body: {
        if (promocode != null) 'promocode': promocode,
      },
      auth: true,
    );

    if (!result.isSuccess) {
      throw Exception(result.error ?? 'Checkout failed');
    }

    return Order.fromJson(result.data!);
  }

  // ---------------------------------------------------------------------------
  // Orders
  // ---------------------------------------------------------------------------

  Future<bool> hasPurchasedService(int eventId) async {
    final result = await _api.get<Map<String, dynamic>>(
      '/api/v1/shop/purchase-status',
      queryParams: {'event_id': eventId.toString()},
      auth: true,
    );
    return result.isSuccess && result.data?['has_approved_purchase'] == true;
  }

  Future<List<Order>> getOrders(int eventId) async {
    final result = await _api.get<List<dynamic>>(
      '/api/v1/shop/orders',
      queryParams: {'event_id': eventId.toString()},
      auth: true,
    );

    if (!result.isSuccess) {
      throw Exception(result.error ?? 'Failed to load orders');
    }

    return result.data!
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
