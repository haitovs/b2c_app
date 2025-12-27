import 'dart:convert';

/// API Exception for centralized error handling
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String? code;
  final dynamic data;

  ApiException({
    required this.statusCode,
    required this.message,
    this.code,
    this.data,
  });

  /// Check if this is a specific error code (e.g., EMAIL_NOT_VERIFIED)
  bool hasCode(String errorCode) => code == errorCode;

  /// Check if authentication failed (401)
  bool get isUnauthorized => statusCode == 401;

  /// Check if forbidden (403)
  bool get isForbidden => statusCode == 403;

  /// Check if not found (404)
  bool get isNotFound => statusCode == 404;

  /// Check if server error (5xx)
  bool get isServerError => statusCode >= 500;

  @override
  String toString() => 'ApiException($statusCode): $message';

  /// Create from HTTP response body
  factory ApiException.fromResponse(int statusCode, String body) {
    String message = 'Request failed';
    String? code;
    dynamic data;

    try {
      final json = _parseJson(body);
      if (json is Map<String, dynamic>) {
        // Handle FastAPI error format
        if (json.containsKey('detail')) {
          final detail = json['detail'];
          if (detail is String) {
            message = detail;
            code = detail; // Some codes like EMAIL_NOT_VERIFIED are in detail
          } else if (detail is Map) {
            message = detail['msg'] ?? detail.toString();
            code = detail['type'];
          }
        }
        data = json;
      }
    } catch (_) {
      message = body.isNotEmpty ? body : 'Unknown error';
    }

    return ApiException(
      statusCode: statusCode,
      message: message,
      code: code,
      data: data,
    );
  }

  static dynamic _parseJson(String body) {
    try {
      return const JsonDecoder().convert(body);
    } catch (_) {
      return null;
    }
  }
}
