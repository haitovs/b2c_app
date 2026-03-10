import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../features/auth/services/auth_service.dart';
import '../config/app_config.dart';
import '../models/api_exception.dart';

/// Result type for API calls - Success or Error
class ApiResult<T> {
  final T? data;
  final ApiException? error;

  ApiResult.success(this.data) : error = null;
  ApiResult.failure(this.error) : data = null;

  bool get isSuccess => error == null;
  bool get isError => error != null;
}

/// Centralized API client for all HTTP requests.
/// Handles authentication, headers, and error parsing.
class ApiClient {
  final AuthService _authService;

  static const String _contentTypeJson = 'application/json';

  ApiClient(this._authService);

  /// Base URL for B2C backend
  String get baseUrl => AppConfig.b2cApiBaseUrl;

  /// Base URL for Tourism backend
  String get tourismUrl => AppConfig.tourismApiBaseUrl;

  /// Build headers with optional authentication
  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{'Content-Type': _contentTypeJson};

    if (auth) {
      final token = await _authService.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  /// GET request
  Future<ApiResult<T>> get<T>(
    String path, {
    bool auth = true,
    Map<String, String>? queryParams,
    T Function(dynamic json)? parser,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl$path');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final response = await http.get(uri, headers: await _headers(auth: auth));

      return _handleResponseWithRetry(response, parser, retryRequest: auth
          ? () async => http.get(uri, headers: await _headers(auth: true))
          : null);
    } catch (e) {
      return ApiResult.failure(
        ApiException(statusCode: 0, message: 'Network error: $e'),
      );
    }
  }

  /// POST request
  Future<ApiResult<T>> post<T>(
    String path, {
    dynamic body,
    bool auth = true,
    T Function(dynamic json)? parser,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final encodedBody = body != null ? jsonEncode(body) : null;

      final response = await http.post(
        uri,
        headers: await _headers(auth: auth),
        body: encodedBody,
      );

      return _handleResponseWithRetry(response, parser, retryRequest: auth
          ? () async => http.post(uri, headers: await _headers(auth: true), body: encodedBody)
          : null);
    } catch (e) {
      return ApiResult.failure(
        ApiException(statusCode: 0, message: 'Network error: $e'),
      );
    }
  }

  /// POST with form data (for login)
  Future<ApiResult<T>> postForm<T>(
    String path, {
    required Map<String, String> body,
    bool auth = false,
    T Function(dynamic json)? parser,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$path'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          if (auth) ...await _headers(auth: true),
        },
        body: body,
      );

      return _handleResponse(response, parser);
    } catch (e) {
      return ApiResult.failure(
        ApiException(statusCode: 0, message: 'Network error: $e'),
      );
    }
  }

  /// PATCH request
  Future<ApiResult<T>> patch<T>(
    String path, {
    dynamic body,
    bool auth = true,
    T Function(dynamic json)? parser,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final encodedBody = body != null ? jsonEncode(body) : null;

      final response = await http.patch(
        uri,
        headers: await _headers(auth: auth),
        body: encodedBody,
      );

      return _handleResponseWithRetry(response, parser, retryRequest: auth
          ? () async => http.patch(uri, headers: await _headers(auth: true), body: encodedBody)
          : null);
    } catch (e) {
      return ApiResult.failure(
        ApiException(statusCode: 0, message: 'Network error: $e'),
      );
    }
  }

  /// PUT request
  Future<ApiResult<T>> put<T>(
    String path, {
    dynamic body,
    bool auth = true,
    T Function(dynamic json)? parser,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final encodedBody = body != null ? jsonEncode(body) : null;

      final response = await http.put(
        uri,
        headers: await _headers(auth: auth),
        body: encodedBody,
      );

      return _handleResponseWithRetry(response, parser, retryRequest: auth
          ? () async => http.put(uri, headers: await _headers(auth: true), body: encodedBody)
          : null);
    } catch (e) {
      return ApiResult.failure(
        ApiException(statusCode: 0, message: 'Network error: $e'),
      );
    }
  }

  /// DELETE request
  Future<ApiResult<T>> delete<T>(
    String path, {
    bool auth = true,
    T Function(dynamic json)? parser,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$path');

      final response = await http.delete(
        uri,
        headers: await _headers(auth: auth),
      );

      return _handleResponseWithRetry(response, parser, retryRequest: auth
          ? () async => http.delete(uri, headers: await _headers(auth: true))
          : null);
    } catch (e) {
      return ApiResult.failure(
        ApiException(statusCode: 0, message: 'Network error: $e'),
      );
    }
  }

  /// Check if response indicates an expired/invalid token
  bool _isAuthError(http.Response response) {
    return response.statusCode == 401 || response.statusCode == 403;
  }

  /// Handle HTTP response, with automatic token refresh on auth errors.
  /// [retryRequest] is called to retry the original request after token refresh.
  Future<ApiResult<T>> _handleResponseWithRetry<T>(
    http.Response response,
    T Function(dynamic json)? parser, {
    Future<http.Response> Function()? retryRequest,
  }) async {
    // If auth error and we have a retry function, try refreshing the token
    if (_isAuthError(response) && retryRequest != null) {
      final refreshed = await _authService.tryRefreshToken();
      if (refreshed) {
        final retryResponse = await retryRequest();
        return _handleResponse(retryResponse, parser);
      } else {
        // Refresh failed — force logout so user gets redirected to login
        await _authService.logout();
      }
    }

    return _handleResponse(response, parser);
  }

  /// Handle HTTP response
  ApiResult<T> _handleResponse<T>(
    http.Response response,
    T Function(dynamic json)? parser,
  ) {
    if (kDebugMode) {
      debugPrint(
        'API ${response.request?.method} ${response.request?.url}: ${response.statusCode}',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return ApiResult.success(null);
      }

      try {
        final json = jsonDecode(response.body);
        if (parser != null) {
          return ApiResult.success(parser(json));
        }
        return ApiResult.success(json as T);
      } catch (e) {
        return ApiResult.failure(
          ApiException(
            statusCode: response.statusCode,
            message: 'Parse error: $e',
          ),
        );
      }
    } else {
      return ApiResult.failure(
        ApiException.fromResponse(response.statusCode, response.body),
      );
    }
  }
}
