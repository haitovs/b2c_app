import 'package:flutter_test/flutter_test.dart';
import 'package:b2c_app/features/shop/services/shop_service.dart';
import 'package:b2c_app/features/shop/models/event_service.dart';
import '../../../helpers/mock_api_client.dart';

void main() {
  late FakeApiClient api;
  late ShopService shopService;

  setUp(() {
    api = FakeApiClient();
    shopService = ShopService(api);
  });

  // ---- Sample JSON fixtures ----
  final serviceJson = {
    'id': 1,
    'event_id': 10,
    'name': 'VIP Pass',
    'subtitle': 'Premium access',
    'description': 'Full event access',
    'image_url': null,
    'price': 199.99,
    'currency': 'USD',
    'category': 'tickets',
    'min_order': 1,
    'included': ['Lunch', 'Dinner'],
    'not_included': ['Hotel'],
    'discount_percent': 10,
    'is_package': false,
    'is_active': true,
    'display_order': 1,
  };

  final cartItemJson = {
    'id': 'cart-1',
    'user_id': 'user-1',
    'event_id': 10,
    'service_id': 1,
    'quantity': 2,
    'unit_price': 199.99,
    'currency': 'USD',
    'service': serviceJson,
    'created_at': '2025-01-01T00:00:00',
  };

  final cartSummaryJson = {
    'items': [cartItemJson],
    'total_usd': 399.98,
    'total_tmt': 1399.93,
    'discount_usd': 40.00,
    'discount_tmt': 140.00,
    'item_count': 1,
  };

  final orderItemJson = {
    'id': 'oi-1',
    'service_id': 1,
    'quantity': 2,
    'unit_price': 199.99,
    'currency': 'USD',
    'service': serviceJson,
  };

  final orderJson = {
    'id': 'order-1',
    'user_id': 'user-1',
    'event_id': 10,
    'status': 'pending',
    'total_usd': 399.98,
    'total_tmt': 1399.93,
    'discount_usd': 40.00,
    'discount_tmt': 140.00,
    'items': [orderItemJson],
    'created_at': '2025-01-01T00:00:00',
  };

  group('ShopService.getServices', () {
    test('returns list of services on success', () async {
      api.stubGet('/api/v1/shop/services', [serviceJson]);

      final services = await shopService.getServices(10);

      expect(services, hasLength(1));
      expect(services.first.id, 1);
      expect(services.first.name, 'VIP Pass');
      expect(services.first.price, 199.99);
      expect(services.first.discountPercent, 10);
    });

    test('passes category query param when provided', () async {
      api.stubGet('/api/v1/shop/services', []);

      await shopService.getServices(10, category: 'tickets');

      expect(api.calls.last.queryParams?['category'], 'tickets');
      expect(api.calls.last.queryParams?['event_id'], '10');
    });

    test('throws on error response', () async {
      api.stubGetError('/api/v1/shop/services', message: 'Server error');

      expect(
        () => shopService.getServices(10),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('ShopService.getServiceDetail', () {
    test('returns service detail on success', () async {
      api.stubGet('/api/v1/shop/services/1', serviceJson);

      final service = await shopService.getServiceDetail(1);

      expect(service.id, 1);
      expect(service.name, 'VIP Pass');
      expect(service.category, 'tickets');
    });

    test('throws on error response', () async {
      api.stubGetError('/api/v1/shop/services/1', statusCode: 404, message: 'Not found');

      expect(
        () => shopService.getServiceDetail(1),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('ShopService.getCart', () {
    test('returns cart summary on success', () async {
      api.stubGet('/api/v1/shop/cart', cartSummaryJson);

      final cart = await shopService.getCart(10);

      expect(cart.items, hasLength(1));
      expect(cart.totalUsd, 399.98);
      expect(cart.totalTmt, 1399.93);
      expect(cart.discountUsd, 40.00);
      expect(cart.itemCount, 1);
    });

    test('throws on error response', () async {
      api.stubGetError('/api/v1/shop/cart', message: 'Failed');

      expect(
        () => shopService.getCart(10),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('ShopService.addToCart', () {
    test('returns cart item on success', () async {
      api.stubPost('/api/v1/shop/cart?event_id=10', cartItemJson);

      final item = await shopService.addToCart(10, 1, quantity: 2);

      expect(item.id, 'cart-1');
      expect(item.quantity, 2);
      expect(item.unitPrice, 199.99);
      expect(item.service?.name, 'VIP Pass');
    });

    test('sends correct body with service_id and quantity', () async {
      api.stubPost('/api/v1/shop/cart?event_id=10', cartItemJson);

      await shopService.addToCart(10, 1, quantity: 3);

      final body = api.calls.last.body as Map<String, dynamic>;
      expect(body['service_id'], 1);
      expect(body['quantity'], 3);
    });

    test('defaults quantity to 1', () async {
      api.stubPost('/api/v1/shop/cart?event_id=10', cartItemJson);

      await shopService.addToCart(10, 1);

      final body = api.calls.last.body as Map<String, dynamic>;
      expect(body['quantity'], 1);
    });
  });

  group('ShopService.updateCartItem', () {
    test('returns updated cart item on success', () async {
      api.stubPut('/api/v1/shop/cart/cart-1', cartItemJson);

      final item = await shopService.updateCartItem('cart-1', 5);

      expect(item.id, 'cart-1');
      final body = api.calls.last.body as Map<String, dynamic>;
      expect(body['quantity'], 5);
    });

    test('throws on error response', () async {
      api.stubPutError('/api/v1/shop/cart/cart-1', message: 'Invalid quantity');

      expect(
        () => shopService.updateCartItem('cart-1', 0),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('ShopService.removeCartItem', () {
    test('completes without error on success', () async {
      api.stubDelete('/api/v1/shop/cart/cart-1');

      await expectLater(shopService.removeCartItem('cart-1'), completes);
    });

    test('throws on error response', () async {
      api.stubDeleteError('/api/v1/shop/cart/cart-1', message: 'Not found');

      expect(
        () => shopService.removeCartItem('cart-1'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('ShopService.checkout', () {
    test('returns order on success', () async {
      api.stubPost('/api/v1/shop/checkout?event_id=10', orderJson);

      final order = await shopService.checkout(10);

      expect(order.id, 'order-1');
      expect(order.status, 'pending');
      expect(order.totalUsd, 399.98);
      expect(order.items, hasLength(1));
      expect(order.items.first.quantity, 2);
    });

    test('sends promocode in body when provided', () async {
      api.stubPost('/api/v1/shop/checkout?event_id=10', orderJson);

      await shopService.checkout(10, promocode: 'SAVE20');

      final body = api.calls.last.body as Map<String, dynamic>;
      expect(body['promocode'], 'SAVE20');
    });

    test('throws on error response', () async {
      api.stubPostError('/api/v1/shop/checkout?event_id=10', message: 'Cart is empty');

      expect(
        () => shopService.checkout(10),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('ShopService.getOrders', () {
    test('returns list of orders on success', () async {
      api.stubGet('/api/v1/shop/orders', [orderJson]);

      final orders = await shopService.getOrders(10);

      expect(orders, hasLength(1));
      expect(orders.first.id, 'order-1');
      expect(orders.first.status, 'pending');
    });

    test('returns empty list when no orders', () async {
      api.stubGet('/api/v1/shop/orders', <dynamic>[]);

      final orders = await shopService.getOrders(10);

      expect(orders, isEmpty);
    });
  });

  group('ShopService.hasPurchasedService', () {
    test('returns true when has approved purchase', () async {
      api.stubGet(
        '/api/v1/shop/purchase-status',
        {'has_approved_purchase': true},
      );

      final result = await shopService.hasPurchasedService(10);

      expect(result, isTrue);
    });

    test('returns false when no approved purchase', () async {
      api.stubGet(
        '/api/v1/shop/purchase-status',
        {'has_approved_purchase': false},
      );

      final result = await shopService.hasPurchasedService(10);

      expect(result, isFalse);
    });

    test('returns false on error', () async {
      api.stubGetError('/api/v1/shop/purchase-status', message: 'Error');

      final result = await shopService.hasPurchasedService(10);

      expect(result, isFalse);
    });
  });
}
