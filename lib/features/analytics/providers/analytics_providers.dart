import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/analytics_data.dart';
import '../services/analytics_service.dart';

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService(ref.watch(authApiClientProvider));
});

/// Parameters for the user analytics query.
class AnalyticsParams {
  final int eventId;
  final int days;

  const AnalyticsParams({required this.eventId, this.days = 30});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalyticsParams &&
          other.eventId == eventId &&
          other.days == days;

  @override
  int get hashCode => Object.hash(eventId, days);
}

final userAnalyticsProvider =
    FutureProvider.family<UserAnalyticsData, AnalyticsParams>(
        (ref, params) {
  return ref
      .watch(analyticsServiceProvider)
      .getUserAnalytics(params.eventId, days: params.days);
});

/// Session-level dedup set — prevents re-recording the same view in one session.
/// Stored as a static set on AnalyticsService (see analytics_service.dart).
