import 'package:b2c_app/core/services/api_client.dart';
import 'package:b2c_app/core/services/token_provider.dart';
import 'package:b2c_app/core/models/api_exception.dart';

/// A mock TokenProvider that returns a fixed token.
class MockTokenProvider implements TokenProvider {
  String? token = 'mock-token';

  @override
  Future<String?> getToken() async => token;

  @override
  Future<String?> refreshAccessToken() async => null;
}

/// Recorded call information for verification.
class RecordedCall {
  final String method;
  final String path;
  final dynamic body;
  final Map<String, String>? queryParams;
  final bool auth;

  RecordedCall({
    required this.method,
    required this.path,
    this.body,
    this.queryParams,
    this.auth = true,
  });
}

/// Stub entry storing raw data and error separately so we can reconstruct
/// a properly-typed ApiResult<T> at lookup time.
class _StubEntry {
  final dynamic data;
  final ApiException? error;

  _StubEntry.success(this.data) : error = null;
  _StubEntry.failure(this.error) : data = null;
}

/// A fake ApiClient that returns preconfigured responses.
///
/// Usage:
/// ```dart
/// final api = FakeApiClient();
/// api.stubGet('/api/v1/foo', {'key': 'value'});
/// final result = await api.get<Map<String, dynamic>>('/api/v1/foo');
/// expect(result.data, {'key': 'value'});
/// ```
class FakeApiClient extends ApiClient {
  final Map<String, _StubEntry> _stubs = {};
  final List<RecordedCall> calls = [];

  FakeApiClient() : super(MockTokenProvider());

  String _key(String method, String path) => '$method:$path';

  void stubGet(String path, dynamic data) {
    _stubs[_key('GET', path)] = _StubEntry.success(data);
  }

  void stubGetError(String path, {int statusCode = 400, String message = 'Error'}) {
    _stubs[_key('GET', path)] = _StubEntry.failure(
      ApiException(statusCode: statusCode, message: message),
    );
  }

  void stubPost(String path, dynamic data) {
    _stubs[_key('POST', path)] = _StubEntry.success(data);
  }

  void stubPostError(String path, {int statusCode = 400, String message = 'Error'}) {
    _stubs[_key('POST', path)] = _StubEntry.failure(
      ApiException(statusCode: statusCode, message: message),
    );
  }

  void stubPut(String path, dynamic data) {
    _stubs[_key('PUT', path)] = _StubEntry.success(data);
  }

  void stubPutError(String path, {int statusCode = 400, String message = 'Error'}) {
    _stubs[_key('PUT', path)] = _StubEntry.failure(
      ApiException(statusCode: statusCode, message: message),
    );
  }

  void stubDelete(String path, [dynamic data]) {
    _stubs[_key('DELETE', path)] = _StubEntry.success(data);
  }

  void stubDeleteError(String path, {int statusCode = 400, String message = 'Error'}) {
    _stubs[_key('DELETE', path)] = _StubEntry.failure(
      ApiException(statusCode: statusCode, message: message),
    );
  }

  void stubPatch(String path, dynamic data) {
    _stubs[_key('PATCH', path)] = _StubEntry.success(data);
  }

  void stubPatchError(String path, {int statusCode = 400, String message = 'Error'}) {
    _stubs[_key('PATCH', path)] = _StubEntry.failure(
      ApiException(statusCode: statusCode, message: message),
    );
  }

  /// Reconstruct a properly-typed ApiResult<T> from the stub entry.
  ApiResult<T> _lookup<T>(String method, String path) {
    final entry = _stubs[_key(method, path)];
    if (entry == null) {
      throw StateError(
        'No stub for $method $path. Available stubs: ${_stubs.keys.join(', ')}',
      );
    }
    if (entry.error != null) {
      return ApiResult<T>.failure(entry.error!);
    }
    return ApiResult<T>.success(entry.data as T);
  }

  @override
  Future<ApiResult<T>> get<T>(
    String path, {
    bool auth = true,
    Map<String, String>? queryParams,
    T Function(dynamic json)? parser,
  }) async {
    calls.add(RecordedCall(method: 'GET', path: path, queryParams: queryParams, auth: auth));
    return _lookup<T>('GET', path);
  }

  @override
  Future<ApiResult<T>> post<T>(
    String path, {
    dynamic body,
    bool auth = true,
    Map<String, String>? queryParams,
    T Function(dynamic json)? parser,
  }) async {
    calls.add(RecordedCall(method: 'POST', path: path, body: body, queryParams: queryParams, auth: auth));
    return _lookup<T>('POST', path);
  }

  @override
  Future<ApiResult<T>> put<T>(
    String path, {
    dynamic body,
    bool auth = true,
    Map<String, String>? queryParams,
    T Function(dynamic json)? parser,
  }) async {
    calls.add(RecordedCall(method: 'PUT', path: path, body: body, queryParams: queryParams, auth: auth));
    return _lookup<T>('PUT', path);
  }

  @override
  Future<ApiResult<T>> delete<T>(
    String path, {
    bool auth = true,
    T Function(dynamic json)? parser,
  }) async {
    calls.add(RecordedCall(method: 'DELETE', path: path, auth: auth));
    return _lookup<T>('DELETE', path);
  }

  @override
  Future<ApiResult<T>> patch<T>(
    String path, {
    dynamic body,
    bool auth = true,
    T Function(dynamic json)? parser,
  }) async {
    calls.add(RecordedCall(method: 'PATCH', path: path, body: body, auth: auth));
    return _lookup<T>('PATCH', path);
  }

  @override
  Future<ApiResult<T>> postForm<T>(
    String path, {
    required Map<String, String> body,
    bool auth = false,
    T Function(dynamic json)? parser,
  }) async {
    calls.add(RecordedCall(method: 'POST', path: path, body: body, auth: auth));
    return _lookup<T>('POST', path);
  }
}
