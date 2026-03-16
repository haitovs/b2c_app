import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../services/travel_info_service.dart';

/// Provider for [TravelInfoService].
final travelInfoServiceProvider = Provider<TravelInfoService>((ref) {
  return TravelInfoService(ref.watch(authApiClientProvider));
});

/// Fetch team members with travel status for a given event.
final travelTeamMembersProvider =
    FutureProvider.family<List<Map<String, dynamic>>, int>((ref, eventId) {
  return ref.watch(travelInfoServiceProvider).getTeamMembersWithStatus(eventId);
});

/// Fetch travel info for a specific member + event combination.
final travelInfoProvider = FutureProvider.family<Map<String, dynamic>,
    ({String memberId, int eventId})>((ref, params) {
  return ref
      .watch(travelInfoServiceProvider)
      .getTravelInfo(params.memberId, params.eventId);
});

/// Fetch the list of available airports.
final airportsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(travelInfoServiceProvider).getAirports();
});

/// Fetch the list of available hotels.
final hotelsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(travelInfoServiceProvider).getHotels();
});
