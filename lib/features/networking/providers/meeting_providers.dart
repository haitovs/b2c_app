import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../services/meeting_service.dart';

/// Provider for MeetingService.
final meetingServiceProvider = Provider<MeetingService>((ref) {
  return MeetingService(ref.watch(authApiClientProvider));
});

/// Fetch current user's meetings, optionally filtered by event.
final myMeetingsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, int?>((ref, eventId) {
  return ref.watch(meetingServiceProvider).fetchMyMeetings(eventId: eventId);
});

/// Fetch meeting locations for an event.
final meetingLocationsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, int>((ref, eventId) {
  return ref.watch(meetingServiceProvider).fetchLocations(eventId);
});

/// Fetch government entities.
final govEntitiesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(meetingServiceProvider).fetchGovEntities();
});

/// Fetch participants for meetings, optionally by site.
final meetingParticipantsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, int?>((ref, siteId) {
  return ref.watch(meetingServiceProvider).fetchParticipants(siteId: siteId);
});
