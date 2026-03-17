import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../services/flight_service.dart';

/// Provider for FlightService.
final flightServiceProvider = Provider<FlightService>((ref) {
  return FlightService(ref.watch(authApiClientProvider));
});
