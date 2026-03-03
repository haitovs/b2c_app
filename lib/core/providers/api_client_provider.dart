import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';
import '../services/token_provider.dart';

/// Provider for the centralized API client.
/// Must be overridden once AuthNotifier (which implements TokenProvider) is available.
final apiClientProvider = Provider<ApiClient>((ref) {
  throw UnimplementedError(
    'apiClientProvider must be overridden with a TokenProvider',
  );
});

/// Helper to create an ApiClient from a TokenProvider.
ApiClient createApiClient(TokenProvider tokenProvider) {
  return ApiClient(tokenProvider);
}
