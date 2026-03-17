import 'package:flutter_test/flutter_test.dart';
import 'package:b2c_app/features/auth/models/auth_state.dart';

void main() {
  group('AuthState', () {
    test('default state is unauthenticated and uninitialized', () {
      const state = AuthState();

      expect(state.token, isNull);
      expect(state.currentUser, isNull);
      expect(state.isInitialized, isFalse);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.isAuthenticated, isFalse);
    });

    test('isAuthenticated is true when token is present', () {
      const state = AuthState(token: 'some-token');

      expect(state.isAuthenticated, isTrue);
    });

    test('isAuthenticated is false when token is null', () {
      const state = AuthState();

      expect(state.isAuthenticated, isFalse);
    });

    test('hasAgreedTerms returns true when user has agreed', () {
      const state = AuthState(
        currentUser: {'has_agreed_terms': true, 'name': 'Test'},
      );

      expect(state.hasAgreedTerms, isTrue);
    });

    test('hasAgreedTerms returns false when user has not agreed', () {
      const state = AuthState(
        currentUser: {'has_agreed_terms': false},
      );

      expect(state.hasAgreedTerms, isFalse);
    });

    test('hasAgreedTerms returns false when no user', () {
      const state = AuthState();

      expect(state.hasAgreedTerms, isFalse);
    });

    group('copyWith', () {
      test('updates token', () {
        const original = AuthState();
        final updated = original.copyWith(token: 'new-token');

        expect(updated.token, 'new-token');
        expect(updated.isInitialized, isFalse);
      });

      test('preserves existing values when not overridden', () {
        const original = AuthState(
          token: 'old-token',
          isInitialized: true,
          isLoading: false,
        );
        final updated = original.copyWith(isLoading: true);

        expect(updated.token, 'old-token');
        expect(updated.isInitialized, isTrue);
        expect(updated.isLoading, isTrue);
      });

      test('clearToken removes token', () {
        const original = AuthState(token: 'my-token');
        final updated = original.copyWith(clearToken: true);

        expect(updated.token, isNull);
        expect(updated.isAuthenticated, isFalse);
      });

      test('clearUser removes currentUser', () {
        const original = AuthState(
          currentUser: {'name': 'Test User'},
        );
        final updated = original.copyWith(clearUser: true);

        expect(updated.currentUser, isNull);
      });

      test('clearError removes error', () {
        const original = AuthState(error: 'Something went wrong');
        final updated = original.copyWith(clearError: true);

        expect(updated.error, isNull);
      });

      test('clearToken takes precedence over new token value', () {
        const original = AuthState(token: 'old');
        final updated = original.copyWith(token: 'new', clearToken: true);

        expect(updated.token, isNull);
      });

      test('sets currentUser data', () {
        const original = AuthState();
        final updated = original.copyWith(
          currentUser: {'id': '1', 'email': 'test@test.com'},
        );

        expect(updated.currentUser?['id'], '1');
        expect(updated.currentUser?['email'], 'test@test.com');
      });

      test('sets error message', () {
        const original = AuthState();
        final updated = original.copyWith(error: 'Login failed');

        expect(updated.error, 'Login failed');
      });

      test('transitions through login flow states', () {
        // Initial state
        const state1 = AuthState(isInitialized: true);
        expect(state1.isAuthenticated, isFalse);
        expect(state1.isLoading, isFalse);

        // Start login
        final state2 = state1.copyWith(isLoading: true, clearError: true);
        expect(state2.isLoading, isTrue);
        expect(state2.error, isNull);

        // Login success
        final state3 = state2.copyWith(
          token: 'jwt-token',
          isLoading: false,
        );
        expect(state3.isAuthenticated, isTrue);
        expect(state3.isLoading, isFalse);

        // Fetch user
        final state4 = state3.copyWith(
          currentUser: {'id': '1', 'email': 'user@test.com'},
        );
        expect(state4.isAuthenticated, isTrue);
        expect(state4.currentUser?['email'], 'user@test.com');
      });

      test('transitions through login failure states', () {
        const state1 = AuthState(isInitialized: true);

        // Start login
        final state2 = state1.copyWith(isLoading: true, clearError: true);
        expect(state2.isLoading, isTrue);

        // Login failed
        final state3 = state2.copyWith(
          isLoading: false,
          error: 'Incorrect email or password',
        );
        expect(state3.isLoading, isFalse);
        expect(state3.isAuthenticated, isFalse);
        expect(state3.error, 'Incorrect email or password');
      });
    });
  });
}
