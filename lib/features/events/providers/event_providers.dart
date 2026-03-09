import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../services/event_service.dart';
import '../services/agenda_service.dart';
import '../services/speaker_service.dart';
import '../services/sponsor_service.dart';

/// Provider for EventService.
final eventServiceProvider = Provider<EventService>((ref) {
  return EventService(ref.watch(authApiClientProvider));
});

/// Provider for AgendaService.
final agendaServiceProvider = Provider<AgendaService>((ref) {
  return AgendaService(ref.watch(authApiClientProvider));
});

/// Provider for SpeakerService.
final speakerServiceProvider = Provider<SpeakerService>((ref) {
  return SpeakerService(ref.watch(authApiClientProvider));
});

/// Provider for SponsorService.
final sponsorServiceProvider = Provider<SponsorService>((ref) {
  return SponsorService(ref.watch(authApiClientProvider));
});

/// Fetch all events, optionally filtered by site ID.
final eventListProvider =
    FutureProvider.family<List<dynamic>, int?>((ref, siteId) {
  return ref.watch(eventServiceProvider).fetchEvents(siteId: siteId);
});

/// Fetch a single event by ID.
final eventDetailProvider =
    FutureProvider.family<Map<String, dynamic>?, int>((ref, eventId) {
  return ref.watch(eventServiceProvider).fetchEvent(eventId);
});

/// Fetch agenda days for an event.
final agendaDaysProvider =
    FutureProvider.family<List<dynamic>, int>((ref, eventId) {
  return ref.watch(agendaServiceProvider).fetchAgendaDays(eventId: eventId);
});

/// Fetch speakers.
final speakerListProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.watch(speakerServiceProvider).fetchSpeakers();
});

/// Fetch sponsors.
final sponsorListProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.watch(sponsorServiceProvider).fetchSponsors();
});
