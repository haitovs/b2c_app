/// Flight model for displaying flight information.
class Flight {
  final int id;
  final String airlineName;
  final String? airlineLogo;
  final String flightNumber;
  final String originCode;
  final String originCity;
  final String destinationCode;
  final String destinationCity;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final int durationMinutes;
  final int stops;
  final double basePrice;
  final String currency;
  final bool personalItem;
  final bool carryOn;
  final bool checkedBag;
  final int? checkedBagWeight;
  final String status;

  Flight({
    required this.id,
    required this.airlineName,
    this.airlineLogo,
    required this.flightNumber,
    required this.originCode,
    required this.originCity,
    required this.destinationCode,
    required this.destinationCity,
    required this.departureTime,
    required this.arrivalTime,
    required this.durationMinutes,
    required this.stops,
    required this.basePrice,
    required this.currency,
    required this.personalItem,
    required this.carryOn,
    required this.checkedBag,
    this.checkedBagWeight,
    required this.status,
  });

  /// Duration formatted as "Xh Ym"
  String get durationFormatted {
    final hours = durationMinutes ~/ 60;
    final mins = durationMinutes % 60;
    return '${hours}h ${mins}m';
  }

  /// Price formatted with currency
  String get priceFormatted => 'US\$${basePrice.toStringAsFixed(2)}';

  /// Stop label (Direct or X stop(s))
  String get stopLabel =>
      stops == 0 ? 'Direct' : '$stops stop${stops > 1 ? 's' : ''}';

  factory Flight.fromJson(Map<String, dynamic> json) {
    return Flight(
      id: json['id'] as int,
      airlineName: json['airline_name'] as String,
      airlineLogo: json['airline_logo'] as String?,
      flightNumber: json['flight_number'] as String,
      originCode: json['origin_code'] as String,
      originCity: json['origin_city'] as String,
      destinationCode: json['destination_code'] as String,
      destinationCity: json['destination_city'] as String,
      departureTime: DateTime.parse(json['departure_time'] as String),
      arrivalTime: DateTime.parse(json['arrival_time'] as String),
      durationMinutes: json['duration_minutes'] as int,
      stops: json['stops'] as int,
      basePrice: (json['base_price'] as num).toDouble(),
      currency: json['currency'] as String,
      personalItem: json['personal_item'] as bool,
      carryOn: json['carry_on'] as bool,
      checkedBag: json['checked_bag'] as bool,
      checkedBagWeight: json['checked_bag_weight'] as int?,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'airline_name': airlineName,
      'airline_logo': airlineLogo,
      'flight_number': flightNumber,
      'origin_code': originCode,
      'origin_city': originCity,
      'destination_code': destinationCode,
      'destination_city': destinationCity,
      'departure_time': departureTime.toIso8601String(),
      'arrival_time': arrivalTime.toIso8601String(),
      'duration_minutes': durationMinutes,
      'stops': stops,
      'base_price': basePrice,
      'currency': currency,
      'personal_item': personalItem,
      'carry_on': carryOn,
      'checked_bag': checkedBag,
      'checked_bag_weight': checkedBagWeight,
      'status': status,
    };
  }
}
