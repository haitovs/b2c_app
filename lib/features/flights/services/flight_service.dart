import '../../../core/services/api_client.dart';
import '../../auth/services/auth_service.dart';
import '../models/flight.dart';
import '../models/flight_booking.dart';

/// Service for flight search and booking operations.
class FlightService {
  final AuthService _authService;
  late final ApiClient _client;

  FlightService(this._authService) {
    _client = ApiClient(_authService);
  }

  /// Search for flights with optional filters.
  Future<List<Flight>> searchFlights({
    String? origin,
    String? destination,
    String? date,
    int passengers = 1,
  }) async {
    final queryParams = <String, String>{};
    if (origin != null && origin.isNotEmpty) queryParams['origin'] = origin;
    if (destination != null && destination.isNotEmpty) {
      queryParams['destination'] = destination;
    }
    if (date != null && date.isNotEmpty) queryParams['date'] = date;
    queryParams['passengers'] = passengers.toString();

    final result = await _client.get<List<dynamic>>(
      '/api/v1/flights/search',
      queryParams: queryParams,
      parser: (json) => json as List<dynamic>,
    );

    if (result.isSuccess && result.data != null) {
      return result.data!
          .map((json) => Flight.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to search flights: ${result.error?.message}');
  }

  /// Get flight details by ID.
  Future<Flight> getFlightDetails(int flightId) async {
    final result = await _client.get<Map<String, dynamic>>(
      '/api/v1/flights/$flightId',
      parser: (json) => json as Map<String, dynamic>,
    );

    if (result.isSuccess && result.data != null) {
      return Flight.fromJson(result.data!);
    }
    throw Exception('Failed to get flight: ${result.error?.message}');
  }

  /// Create a flight booking.
  Future<BookingResult> createBooking({
    required int flightId,
    required int passengers,
    required TravelerInfo traveler,
    required String paymentMethod,
  }) async {
    final body = {
      'flight_id': flightId,
      'passengers': passengers,
      'traveler': traveler.toJson(),
      'payment_method': paymentMethod,
    };

    final result = await _client.post<Map<String, dynamic>>(
      '/api/v1/flights/bookings',
      body: body,
      parser: (json) => json as Map<String, dynamic>,
    );

    if (result.isSuccess && result.data != null) {
      return BookingResult.fromJson(result.data!);
    }
    throw Exception('Failed to create booking: ${result.error?.message}');
  }

  /// Get current user's flight bookings.
  Future<List<FlightBooking>> getMyBookings() async {
    final result = await _client.get<List<dynamic>>(
      '/api/v1/flights/bookings/mine',
      parser: (json) => json as List<dynamic>,
    );

    if (result.isSuccess && result.data != null) {
      return result.data!
          .map((json) => FlightBooking.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to get bookings: ${result.error?.message}');
  }

  /// Get a specific booking by ID.
  Future<FlightBooking> getBooking(String bookingId) async {
    final result = await _client.get<Map<String, dynamic>>(
      '/api/v1/flights/bookings/$bookingId',
      parser: (json) => json as Map<String, dynamic>,
    );

    if (result.isSuccess && result.data != null) {
      return FlightBooking.fromJson(result.data!);
    }
    throw Exception('Failed to get booking: ${result.error?.message}');
  }
}
