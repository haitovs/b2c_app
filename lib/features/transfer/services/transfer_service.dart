import '../../../core/services/api_client.dart';
import '../../auth/services/auth_service.dart';
import '../models/booking.dart';
import '../models/car.dart';
import '../models/shuttle.dart';

/// Service for transfer API operations
class TransferService {
  final ApiClient _api;

  TransferService(AuthService authService) : _api = ApiClient(authService);

  /// Get all shuttles
  Future<List<Shuttle>> getShuttles() async {
    final result = await _api.get<List<dynamic>>('/api/v1/transfers/shuttles');
    if (result.isSuccess && result.data != null) {
      return result.data!.map((json) => Shuttle.fromJson(json)).toList();
    }
    throw result.error ?? Exception('Failed to load shuttles');
  }

  /// Get shuttle by ID
  Future<Shuttle> getShuttle(int id) async {
    final result = await _api.get<Map<String, dynamic>>(
      '/api/v1/transfers/shuttles/$id',
    );
    if (result.isSuccess && result.data != null) {
      return Shuttle.fromJson(result.data!);
    }
    throw result.error ?? Exception('Failed to load shuttle');
  }

  /// Get all cars, optionally filtered by type
  Future<List<Car>> getCars({String? carType}) async {
    final queryParams = <String, String>{};
    if (carType != null) {
      queryParams['car_type'] = carType;
    }

    final result = await _api.get<List<dynamic>>(
      '/api/v1/transfers/cars',
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );
    if (result.isSuccess && result.data != null) {
      return result.data!.map((json) => Car.fromJson(json)).toList();
    }
    throw result.error ?? Exception('Failed to load cars');
  }

  /// Get individual cars (with drivers)
  Future<List<Car>> getIndividualCars() async {
    return getCars(carType: 'individual');
  }

  /// Get rental cars (self-drive)
  Future<List<Car>> getRentalCars() async {
    return getCars(carType: 'rental');
  }

  /// Get car by ID
  Future<Car> getCar(int id) async {
    final result = await _api.get<Map<String, dynamic>>(
      '/api/v1/transfers/cars/$id',
    );
    if (result.isSuccess && result.data != null) {
      return Car.fromJson(result.data!);
    }
    throw result.error ?? Exception('Failed to load car');
  }

  /// Create a booking
  Future<Map<String, dynamic>> createBooking({
    required String serviceType, // "shuttle", "individual", "rental"
    required int resourceId,
    required String pickupDatetime,
    String? dropoffDatetime,
    required String pickupLocation,
    String? dropoffLocation,
    int passengerCount = 1,
    String? specialRequests,
    // For rentals
    String? licenseNumber,
    String? licenseCountry,
    String? licenseExpiry,
    String? licensePhoto,
    // Duration
    String durationType = 'daily',
    int? hours,
    int days = 1,
  }) async {
    final body = <String, dynamic>{
      'service_type': serviceType,
      'resource_id': resourceId,
      'pickup_datetime': pickupDatetime,
      'pickup_location': pickupLocation,
      'passenger_count': passengerCount,
      'duration_type': durationType,
      'days': days,
    };

    if (dropoffDatetime != null) body['dropoff_datetime'] = dropoffDatetime;
    if (dropoffLocation != null) body['dropoff_location'] = dropoffLocation;
    if (specialRequests != null) body['special_requests'] = specialRequests;
    if (hours != null) body['hours'] = hours;

    // License info for rentals
    if (serviceType == 'rental') {
      if (licenseNumber != null) body['license_number'] = licenseNumber;
      if (licenseCountry != null) body['license_country'] = licenseCountry;
      if (licenseExpiry != null) body['license_expiry'] = licenseExpiry;
      if (licensePhoto != null) body['license_photo'] = licensePhoto;
    }

    final result = await _api.post<Map<String, dynamic>>(
      '/api/v1/transfers/bookings',
      body: body,
    );
    if (result.isSuccess && result.data != null) {
      return result.data!;
    }
    throw result.error ?? Exception('Failed to create booking');
  }

  /// Get user's transfer bookings
  Future<List<TransferBooking>> getMyBookings() async {
    final result = await _api.get<List<dynamic>>('/api/v1/transfers/bookings');
    if (result.isSuccess && result.data != null) {
      return result.data!
          .map((json) => TransferBooking.fromJson(json))
          .toList();
    }
    throw result.error ?? Exception('Failed to load bookings');
  }

  /// Get booking by ID
  Future<TransferBooking> getBooking(String id) async {
    final result = await _api.get<Map<String, dynamic>>(
      '/api/v1/transfers/bookings/$id',
    );
    if (result.isSuccess && result.data != null) {
      return TransferBooking.fromJson(result.data!);
    }
    throw result.error ?? Exception('Failed to load booking');
  }
}
