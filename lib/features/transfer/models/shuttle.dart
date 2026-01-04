/// Shuttle model for transfer feature
class Shuttle {
  final int id;
  final String name;
  final String? imageUrl;
  final String? routeDescription;
  final String? access;
  final String? driverName;
  final List<ShuttleRoute> routes;

  Shuttle({
    required this.id,
    required this.name,
    this.imageUrl,
    this.routeDescription,
    this.access,
    this.driverName,
    this.routes = const [],
  });

  factory Shuttle.fromJson(Map<String, dynamic> json) {
    return Shuttle(
      id: json['id'] as int,
      name: json['name'] as String,
      imageUrl: json['image_url'] as String?,
      routeDescription: json['route_description'] as String?,
      access: json['access'] as String?,
      driverName: json['driver_name'] as String?,
      routes:
          (json['routes'] as List<dynamic>?)
              ?.map((r) => ShuttleRoute.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Get formatted route string (e.g., "Airport → Venue")
  String get routeString {
    if (routes.isEmpty) return routeDescription ?? '';
    if (routes.length == 1) return routes.first.stopName;
    return '${routes.first.stopName} → ${routes.last.stopName}';
  }

  /// Get all stop times as a formatted string
  String get scheduleString {
    if (routes.isEmpty) return '';
    return routes.map((r) => r.stopTime).join(', ');
  }
}

class ShuttleRoute {
  final String stopName;
  final String stopTime;
  final double? locationLat;
  final double? locationLng;

  ShuttleRoute({
    required this.stopName,
    required this.stopTime,
    this.locationLat,
    this.locationLng,
  });

  factory ShuttleRoute.fromJson(Map<String, dynamic> json) {
    return ShuttleRoute(
      stopName: json['stop_name'] as String,
      stopTime: json['stop_time'] as String,
      locationLat: (json['location_lat'] as num?)?.toDouble(),
      locationLng: (json['location_lng'] as num?)?.toDouble(),
    );
  }
}
