/// Abstract interface for providing authentication tokens.
/// This breaks the circular dependency between ApiClient and AuthService.
abstract class TokenProvider {
  /// Returns the current auth token, or null if not authenticated.
  Future<String?> getToken();
}
