import '../../../core/config/app_config.dart';
import '../../../core/services/api_client.dart';
import '../../auth/services/auth_service.dart';

class ChatMessage {
  final int? id;
  final String content;
  final String role; // USER or ADMIN
  final DateTime? createdAt;
  final String? mediaUrl;

  ChatMessage({
    this.id,
    required this.content,
    required this.role,
    this.createdAt,
    this.mediaUrl,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      content: json['content'] ?? '',
      role: json['role'] ?? 'USER',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      mediaUrl: json['media_url'],
    );
  }

  bool get isFromUser => role == 'USER';
  bool get isFromAdmin => role == 'ADMIN';
}

class HotlineService {
  final ApiClient _api;
  final AuthService _authService;

  HotlineService(this._authService) : _api = ApiClient(_authService);

  /// Get chat history
  Future<List<ChatMessage>> getChatHistory({
    int skip = 0,
    int limit = 100,
  }) async {
    final result = await _api.get<List<dynamic>>(
      '/api/v1/chat/history',
      queryParams: {'skip': skip.toString(), 'limit': limit.toString()},
    );

    if (result.isSuccess && result.data != null) {
      return result.data!.map((json) => ChatMessage.fromJson(json)).toList();
    }
    return [];
  }

  /// Send a message via REST API
  Future<bool> sendMessage(String content) async {
    final result = await _api.post<Map<String, dynamic>>(
      '/api/v1/chat/send?content=${Uri.encodeComponent(content)}',
    );

    return result.isSuccess;
  }

  /// Get WebSocket URL for real-time chat
  Future<String?> getWebSocketUrl() async {
    final token = await _authService.getToken();
    if (token == null) return null;
    // Convert http(s) to ws(s)
    final wsUrl = AppConfig.b2cApiBaseUrl.replaceFirst('http', 'ws');
    return '$wsUrl/api/v1/chat/ws?token=$token';
  }
}
