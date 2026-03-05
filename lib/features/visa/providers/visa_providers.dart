import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../services/visa_service.dart';

/// Provider for VisaService.
final visaServiceProvider = Provider<VisaService>((ref) {
  return VisaService(ref.watch(authNotifierProvider.notifier));
});

/// List all visa applications for a given event.
final visaListProvider = FutureProvider.family<List<Map<String, dynamic>>, int?>((ref, eventId) {
  return ref.watch(visaServiceProvider).listMyVisas(eventId: eventId);
});

/// Fetch visa details (for APPROVED/DECLINED status).
final visaDetailsProvider = FutureProvider.family<Map<String, dynamic>,
    ({int eventId, String participantId})>((ref, args) {
  return ref
      .watch(visaServiceProvider)
      .getMyVisa(participantId: args.participantId, eventId: args.eventId);
});

/// Fetch visa status (for PENDING status).
final visaStatusProvider = FutureProvider.family<Map<String, dynamic>,
    ({int eventId, String participantId})>((ref, args) {
  return ref
      .watch(visaServiceProvider)
      .getMyVisa(participantId: args.participantId, eventId: args.eventId);
});
