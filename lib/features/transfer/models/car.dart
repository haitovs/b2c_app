/// Car model for transfer feature
class Car {
  final int id;
  final String name;
  final String carType; // "rental" or "individual"
  final String? imageUrl;
  final String? transmission;
  final int? seats;
  final int? baggage;
  final String? mileageLimit;
  final double pricePerDay;
  final double? pricePerHour;
  final double? price9Hours;
  // Driver info (for individual cars)
  final String? driverName;
  final String? driverPhoto;
  final String? driverLanguages;
  final List<String> features;

  Car({
    required this.id,
    required this.name,
    required this.carType,
    this.imageUrl,
    this.transmission,
    this.seats,
    this.baggage,
    this.mileageLimit,
    required this.pricePerDay,
    this.pricePerHour,
    this.price9Hours,
    this.driverName,
    this.driverPhoto,
    this.driverLanguages,
    this.features = const [],
  });

  factory Car.fromJson(Map<String, dynamic> json) {
    return Car(
      id: json['id'] as int,
      name: json['name'] as String,
      carType: json['car_type'] as String? ?? 'rental',
      imageUrl: json['image_url'] as String?,
      transmission: json['transmission'] as String?,
      seats: json['seats'] as int?,
      baggage: json['baggage'] as int?,
      mileageLimit: json['mileage_limit'] as String?,
      pricePerDay: (json['price_per_day'] as num?)?.toDouble() ?? 0,
      pricePerHour: (json['price_per_hour'] as num?)?.toDouble(),
      price9Hours: (json['price_9_hours'] as num?)?.toDouble(),
      driverName: json['driver_name'] as String?,
      driverPhoto: json['driver_photo'] as String?,
      driverLanguages: json['driver_languages'] as String?,
      features:
          (json['features'] as List<dynamic>?)
              ?.map((f) => f as String)
              .toList() ??
          [],
    );
  }

  bool get isIndividual => carType == 'individual';
  bool get isRental => carType == 'rental';

  /// Format price display
  String get priceDisplay => '\$${pricePerDay.toStringAsFixed(0)}/day';
}
