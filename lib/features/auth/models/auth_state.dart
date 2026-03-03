/// Immutable state class for authentication.
class AuthState {
  final String? token;
  final Map<String, dynamic>? currentUser;
  final bool isInitialized;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.token,
    this.currentUser,
    this.isInitialized = false,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => token != null;
  bool get hasAgreedTerms => currentUser?['has_agreed_terms'] ?? false;

  AuthState copyWith({
    String? token,
    Map<String, dynamic>? currentUser,
    bool? isInitialized,
    bool? isLoading,
    String? error,
    bool clearToken = false,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      token: clearToken ? null : (token ?? this.token),
      currentUser: clearUser ? null : (currentUser ?? this.currentUser),
      isInitialized: isInitialized ?? this.isInitialized,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
