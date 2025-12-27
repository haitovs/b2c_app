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

      return _handleResponse(response, parser);
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
      final response = await http.post(
        Uri.parse('$baseUrl$path'),
        headers: await _headers(auth: auth),
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse(response, parser);
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
      final response = await http.patch(
        Uri.parse('$baseUrl$path'),
        headers: await _headers(auth: auth),
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse(response, parser);
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
      final response = await http.put(
        Uri.parse('$baseUrl$path'),
        headers: await _headers(auth: auth),
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse(response, parser);
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
      final response = await http.delete(
        Uri.parse('$baseUrl$path'),
        headers: await _headers(auth: auth),
      );

      return _handleResponse(response, parser);
    } catch (e) {
      return ApiResult.failure(
        ApiException(statusCode: 0, message: 'Network error: $e'),
      );
    }
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
