import '../../../core/config/app_config.dart';

enum ServiceCategory {
  expo,
  forum,
  sponsors,
  promotional,
  print,
  transfer,
  tickets,
  flight,
  catering,
}

class EventServiceItem {
  final int id;
  final int eventId;
  final String name;
  final String? subtitle;
  final String? description;
  final String? imageUrl;
  final double price;
  final String currency; // USD or TMT
  final String category;
  final int minOrder;
  final List<dynamic>? included;
  final List<dynamic>? notIncluded;
  final double discountPercent;
  final bool isPackage;
  final bool isActive;
  final int displayOrder;

  const EventServiceItem({
    required this.id,
    required this.eventId,
    required this.name,
    this.subtitle,
    this.description,
    this.imageUrl,
    required this.price,
    required this.currency,
    required this.category,
    this.minOrder = 1,
    this.included,
    this.notIncluded,
    this.discountPercent = 0,
    this.isPackage = false,
    this.isActive = true,
    this.displayOrder = 0,
  });

  static String? _resolveImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http')) return url;
    return '${AppConfig.b2cApiBaseUrl}$url';
  }

  factory EventServiceItem.fromJson(Map<String, dynamic> json) {
    return EventServiceItem(
      id: json['id'] as int,
      eventId: json['event_id'] as int,
      name: json['name'] as String,
      subtitle: json['subtitle'] as String?,
      description: json['description'] as String?,
      imageUrl: _resolveImageUrl(json['image_url'] as String?),
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      category: json['category'] as String,
      minOrder: json['min_order'] as int? ?? 1,
      included: json['included'] as List<dynamic>?,
      notIncluded: json['not_included'] as List<dynamic>?,
      discountPercent: (json['discount_percent'] as num?)?.toDouble() ?? 0,
      isPackage: json['is_package'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      displayOrder: json['display_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'name': name,
      'subtitle': subtitle,
      'description': description,
      'image_url': imageUrl,
      'price': price,
      'currency': currency,
      'category': category,
      'min_order': minOrder,
      'included': included,
      'not_included': notIncluded,
      'discount_percent': discountPercent,
      'is_package': isPackage,
      'is_active': isActive,
      'display_order': displayOrder,
    };
  }
}

class CartItem {
  final String id;
  final String userId;
  final int eventId;
  final int serviceId;
  final int quantity;
  final double unitPrice;
  final String currency; // USD or TMT
  final EventServiceItem? service;
  final String? createdAt;

  const CartItem({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.serviceId,
    required this.quantity,
    required this.unitPrice,
    required this.currency,
    this.service,
    this.createdAt,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      eventId: json['event_id'] as int,
      serviceId: json['service_id'] as int,
      quantity: json['quantity'] as int,
      unitPrice: (json['unit_price'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      service: json['service'] != null
          ? EventServiceItem.fromJson(json['service'] as Map<String, dynamic>)
          : null,
      createdAt: json['created_at'] as String?,
    );
  }
}

class CartSummary {
  final List<CartItem> items;
  final double totalUsd;
  final double totalTmt;
  final double discountUsd;
  final double discountTmt;
  final int itemCount;

  const CartSummary({
    required this.items,
    required this.totalUsd,
    required this.totalTmt,
    this.discountUsd = 0,
    this.discountTmt = 0,
    required this.itemCount,
  });

  factory CartSummary.fromJson(Map<String, dynamic> json) {
    return CartSummary(
      items: (json['items'] as List<dynamic>)
          .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalUsd: (json['total_usd'] as num).toDouble(),
      totalTmt: (json['total_tmt'] as num).toDouble(),
      discountUsd: (json['discount_usd'] as num?)?.toDouble() ?? 0,
      discountTmt: (json['discount_tmt'] as num?)?.toDouble() ?? 0,
      itemCount: json['item_count'] as int,
    );
  }
}

class Order {
  final String id;
  final String userId;
  final int eventId;
  final String status;
  final double totalUsd;
  final double totalTmt;
  final double discountUsd;
  final double discountTmt;
  final List<OrderItem> items;
  final String? createdAt;

  const Order({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.status,
    required this.totalUsd,
    required this.totalTmt,
    this.discountUsd = 0,
    this.discountTmt = 0,
    required this.items,
    this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      eventId: json['event_id'] as int,
      status: json['status'] as String,
      totalUsd: (json['total_usd'] as num).toDouble(),
      totalTmt: (json['total_tmt'] as num).toDouble(),
      discountUsd: (json['discount_usd'] as num?)?.toDouble() ?? 0,
      discountTmt: (json['discount_tmt'] as num?)?.toDouble() ?? 0,
      items: (json['items'] as List<dynamic>)
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['created_at'] as String?,
    );
  }
}

class OrderItem {
  final String id;
  final int? serviceId;
  final int quantity;
  final double unitPrice;
  final String currency; // USD or TMT
  final EventServiceItem? service;

  const OrderItem({
    required this.id,
    this.serviceId,
    required this.quantity,
    required this.unitPrice,
    required this.currency,
    this.service,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String,
      serviceId: json['service_id'] as int?,
      quantity: json['quantity'] as int,
      unitPrice: (json['unit_price'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      service: json['service'] != null
          ? EventServiceItem.fromJson(json['service'] as Map<String, dynamic>)
          : null,
    );
  }
}
