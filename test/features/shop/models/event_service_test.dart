import 'package:flutter_test/flutter_test.dart';
import 'package:b2c_app/features/shop/models/event_service.dart';

void main() {
  group('EventServiceItem', () {
    final fullJson = {
      'id': 1,
      'event_id': 10,
      'name': 'VIP Pass',
      'subtitle': 'Premium',
      'description': 'Full access',
      'image_url': 'https://cdn.example.com/img.jpg',
      'price': 299.50,
      'currency': 'USD',
      'category': 'tickets',
      'min_order': 2,
      'included': ['Lunch'],
      'not_included': ['Hotel'],
      'discount_percent': 15.5,
      'is_package': true,
      'is_active': false,
      'display_order': 3,
    };

    test('fromJson parses all fields correctly', () {
      final item = EventServiceItem.fromJson(fullJson);

      expect(item.id, 1);
      expect(item.eventId, 10);
      expect(item.name, 'VIP Pass');
      expect(item.subtitle, 'Premium');
      expect(item.description, 'Full access');
      expect(item.imageUrl, 'https://cdn.example.com/img.jpg');
      expect(item.price, 299.50);
      expect(item.currency, 'USD');
      expect(item.category, 'tickets');
      expect(item.minOrder, 2);
      expect(item.included, ['Lunch']);
      expect(item.notIncluded, ['Hotel']);
      expect(item.discountPercent, 15.5);
      expect(item.isPackage, isTrue);
      expect(item.isActive, isFalse);
      expect(item.displayOrder, 3);
    });

    test('fromJson uses defaults for optional fields', () {
      final minimalJson = {
        'id': 1,
        'event_id': 10,
        'name': 'Basic',
        'price': 50,
        'category': 'expo',
      };

      final item = EventServiceItem.fromJson(minimalJson);

      expect(item.currency, 'USD');
      expect(item.minOrder, 1);
      expect(item.discountPercent, 0);
      expect(item.isPackage, isFalse);
      expect(item.isActive, isTrue);
      expect(item.displayOrder, 0);
      expect(item.subtitle, isNull);
      expect(item.imageUrl, isNull);
    });

    test('fromJson handles integer price (num to double)', () {
      final json = {
        'id': 1,
        'event_id': 10,
        'name': 'Test',
        'price': 100,
        'category': 'expo',
      };

      final item = EventServiceItem.fromJson(json);
      expect(item.price, 100.0);
      expect(item.price, isA<double>());
    });

    test('toJson round-trips correctly', () {
      final item = EventServiceItem.fromJson(fullJson);
      final json = item.toJson();

      expect(json['id'], fullJson['id']);
      expect(json['name'], fullJson['name']);
      expect(json['price'], fullJson['price']);
      expect(json['is_package'], fullJson['is_package']);
    });

    test('resolves relative image URL to absolute', () {
      final json = {
        'id': 1,
        'event_id': 10,
        'name': 'Test',
        'price': 50,
        'category': 'expo',
        'image_url': '/files/img.jpg',
      };

      final item = EventServiceItem.fromJson(json);

      // Should prepend base URL
      expect(item.imageUrl, isNotNull);
      expect(item.imageUrl!, contains('/files/img.jpg'));
    });

    test('keeps absolute image URL as-is', () {
      final json = {
        'id': 1,
        'event_id': 10,
        'name': 'Test',
        'price': 50,
        'category': 'expo',
        'image_url': 'https://cdn.example.com/img.jpg',
      };

      final item = EventServiceItem.fromJson(json);
      expect(item.imageUrl, 'https://cdn.example.com/img.jpg');
    });
  });

  group('CartItem', () {
    test('fromJson parses correctly with nested service', () {
      final json = {
        'id': 'c-1',
        'user_id': 'u-1',
        'event_id': 10,
        'service_id': 1,
        'quantity': 3,
        'unit_price': 99.99,
        'currency': 'TMT',
        'service': {
          'id': 1,
          'event_id': 10,
          'name': 'Item',
          'price': 99.99,
          'category': 'expo',
        },
        'created_at': '2025-06-01T12:00:00',
      };

      final item = CartItem.fromJson(json);

      expect(item.id, 'c-1');
      expect(item.quantity, 3);
      expect(item.unitPrice, 99.99);
      expect(item.currency, 'TMT');
      expect(item.service, isNotNull);
      expect(item.service!.name, 'Item');
    });

    test('fromJson handles null service', () {
      final json = {
        'id': 'c-2',
        'user_id': 'u-1',
        'event_id': 10,
        'service_id': 1,
        'quantity': 1,
        'unit_price': 50.0,
      };

      final item = CartItem.fromJson(json);

      expect(item.service, isNull);
      expect(item.currency, 'USD'); // default
    });
  });

  group('CartSummary', () {
    test('fromJson parses totals and items', () {
      final json = {
        'items': <dynamic>[],
        'total_usd': 500.00,
        'total_tmt': 1750.00,
        'discount_usd': 50.00,
        'discount_tmt': 175.00,
        'item_count': 0,
      };

      final summary = CartSummary.fromJson(json);

      expect(summary.totalUsd, 500.00);
      expect(summary.totalTmt, 1750.00);
      expect(summary.discountUsd, 50.00);
      expect(summary.discountTmt, 175.00);
      expect(summary.itemCount, 0);
      expect(summary.items, isEmpty);
    });

    test('fromJson defaults discount to 0', () {
      final json = {
        'items': <dynamic>[],
        'total_usd': 100.0,
        'total_tmt': 350.0,
        'item_count': 0,
      };

      final summary = CartSummary.fromJson(json);

      expect(summary.discountUsd, 0);
      expect(summary.discountTmt, 0);
    });
  });

  group('Order', () {
    test('fromJson parses order with items', () {
      final json = {
        'id': 'ord-1',
        'user_id': 'u-1',
        'event_id': 10,
        'status': 'approved',
        'total_usd': 300.0,
        'total_tmt': 1050.0,
        'items': [
          {
            'id': 'oi-1',
            'service_id': 1,
            'quantity': 2,
            'unit_price': 150.0,
            'currency': 'USD',
          },
        ],
        'created_at': '2025-06-01',
      };

      final order = Order.fromJson(json);

      expect(order.id, 'ord-1');
      expect(order.status, 'approved');
      expect(order.totalUsd, 300.0);
      expect(order.items, hasLength(1));
      expect(order.items.first.quantity, 2);
    });
  });

  group('OrderItem', () {
    test('fromJson parses with optional service', () {
      final json = {
        'id': 'oi-1',
        'service_id': null,
        'quantity': 1,
        'unit_price': 25.0,
        'currency': 'TMT',
      };

      final item = OrderItem.fromJson(json);

      expect(item.serviceId, isNull);
      expect(item.service, isNull);
      expect(item.currency, 'TMT');
    });
  });
}
