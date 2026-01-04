import 'flight.dart';

/// Traveler information for flight booking.
class TravelerInfo {
  final String name;
  final String surname;
  final String gender;
  final DateTime dateOfBirth;
  final String email;
  final String phone;

  TravelerInfo({
    required this.name,
    required this.surname,
    required this.gender,
    required this.dateOfBirth,
    required this.email,
    required this.phone,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'surname': surname,
      'gender': gender,
      'date_of_birth':
          '${dateOfBirth.year}-${dateOfBirth.month.toString().padLeft(2, '0')}-${dateOfBirth.day.toString().padLeft(2, '0')}',
      'email': email,
      'phone': phone,
    };
  }
}

/// Flight booking record.
class FlightBooking {
  final String id;
  final int flightId;
  final String bookingReference;
  final String status;
  final String travelerName;
  final String travelerSurname;
  final String travelerEmail;
  final int passengers;
  final double amountFlight;
  final double serviceFee;
  final double amountTotal;
  final String? paymentMethod;
  final DateTime createdAt;
  final Flight? flight;

  FlightBooking({
    required this.id,
    required this.flightId,
    required this.bookingReference,
    required this.status,
    required this.travelerName,
    required this.travelerSurname,
    required this.travelerEmail,
    required this.passengers,
    required this.amountFlight,
    required this.serviceFee,
    required this.amountTotal,
    this.paymentMethod,
    required this.createdAt,
    this.flight,
  });

  String get travelerFullName => '$travelerName $travelerSurname';

  factory FlightBooking.fromJson(Map<String, dynamic> json) {
    return FlightBooking(
      id: json['id'] as String,
      flightId: json['flight_id'] as int,
      bookingReference: json['booking_reference'] as String,
      status: json['status'] as String,
      travelerName: json['traveler_name'] as String,
      travelerSurname: json['traveler_surname'] as String,
      travelerEmail: json['traveler_email'] as String,
      passengers: json['passengers'] as int,
      amountFlight: (json['amount_flight'] as num).toDouble(),
      serviceFee: (json['service_fee'] as num).toDouble(),
      amountTotal: (json['amount_total'] as num).toDouble(),
      paymentMethod: json['payment_method'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      flight: json['flight'] != null
          ? Flight.fromJson(json['flight'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Booking creation result.
class BookingResult {
  final String bookingId;
  final String bookingReference;
  final String? clientSecret;
  final double amountTotal;

  BookingResult({
    required this.bookingId,
    required this.bookingReference,
    this.clientSecret,
    required this.amountTotal,
  });

  factory BookingResult.fromJson(Map<String, dynamic> json) {
    return BookingResult(
      bookingId: json['booking_id'] as String,
      bookingReference: json['booking_reference'] as String,
      clientSecret: json['client_secret'] as String?,
      amountTotal: (json['amount_total'] as num).toDouble(),
    );
  }
}
