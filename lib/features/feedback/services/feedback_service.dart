import '../../../core/services/api_client.dart';
import '../../auth/services/auth_service.dart';

/// Model for a feedback item
class FeedbackItem {
  final String id;
  final int eventId;
  final String userName;
  final String content;
  final String createdAt;

  FeedbackItem({
    required this.id,
    required this.eventId,
    required this.userName,
    required this.content,
    required this.createdAt,
  });

  factory FeedbackItem.fromJson(Map<String, dynamic> json) {
    return FeedbackItem(
      id: json['id'] ?? '',
      eventId: json['event_id'] ?? 0,
      userName: json['user_name'] ?? 'Anonymous',
      content: json['content'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}

/// Service for managing event feedback
class FeedbackService {
  final ApiClient _api;

  FeedbackService(AuthService authService) : _api = ApiClient(authService);

  /// Get feedback status (open/closed) for an event
  Future<bool> getFeedbackStatus(int eventId) async {
    final result = await _api.get<Map<String, dynamic>>(
      '/api/v1/feedbacks/$eventId/status',
    );

    if (result.isSuccess && result.data != null) {
      return result.data!['is_open'] ?? false;
    }
    return false;
  }

  /// Get all feedback for an event
  Future<List<FeedbackItem>> getFeedbacks(int eventId) async {
    final result = await _api.get<List<dynamic>>('/api/v1/feedbacks/$eventId');

    if (result.isSuccess && result.data != null) {
      return result.data!.map((item) => FeedbackItem.fromJson(item)).toList();
    }
    return [];
  }

  /// Submit feedback for an event
  Future<bool> submitFeedback(int eventId, String content) async {
    final result = await _api.post<Map<String, dynamic>>(
      '/api/v1/feedbacks/$eventId',
      body: {'content': content},
    );

    return result.isSuccess;
  }
}
