import '../../../core/services/api_client.dart';
import '../models/analytics_data.dart';

class AnalyticsService {
  final ApiClient _api;

  /// Session-level dedup: prevents re-recording the same view in one app session.
  static final Set<String> _viewedTargets = {};

  AnalyticsService(this._api);

  /// Get user-scoped analytics for the current user + their company.
  Future<UserAnalyticsData> getUserAnalytics(
    int eventId, {
    int days = 30,
  }) async {
    final result = await _api.get<Map<String, dynamic>>(
      '/api/v1/analytics/me/$eventId',
      queryParams: {'days': days.toString()},
      auth: true,
    );

    if (!result.isSuccess) {
      throw Exception(result.error ?? 'Failed to load analytics');
    }

    return UserAnalyticsData.fromJson(result.data!);
  }

  /// Record a profile/company/team-member view (fire-and-forget).
  /// Deduplicates within the current app session.
  Future<void> recordView({
    required String targetType,
    required String targetId,
    required int eventId,
  }) async {
    final key = '$targetType:$targetId';
    if (_viewedTargets.contains(key)) return;
    _viewedTargets.add(key);

    try {
      await _api.post<Map<String, dynamic>>(
        '/api/v1/views',
        body: {
          'target_type': targetType,
          'target_id': targetId,
          'event_id': eventId,
        },
        auth: true,
      );
    } catch (_) {
      // Fire-and-forget — don't break the UI if tracking fails
    }
  }
}
