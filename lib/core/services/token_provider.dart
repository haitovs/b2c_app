/// Abstract interface for providing authentication tokens.
/// This breaks the circular dependency between ApiClient and AuthService.
abstract class TokenProvider {
  /// Returns the current auth token, or null if not authenticated.
  Future<String?> getToken();

  /// Attempt to refresh an expired access token.
  /// Returns the new token on success, or null if refresh is not possible.
  Future<String?> refreshAccessToken() async => null;
}
