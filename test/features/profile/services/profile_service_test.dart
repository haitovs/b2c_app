import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:b2c_app/features/profile/services/profile_service.dart';
import '../../../helpers/mock_api_client.dart';

void main() {
  late FakeApiClient api;
  late MockTokenProvider tokenProvider;
  late ProfileService profileService;

  setUp(() {
    api = FakeApiClient();
    tokenProvider = MockTokenProvider();
    profileService = ProfileService(api, tokenProvider);
  });

  group('ProfileService.changePassword', () {
    test('returns null on success', () async {
      api.stubPatch('/api/v1/users/me/password', {'message': 'Password updated'});

      final result = await profileService.changePassword(
        currentPassword: 'oldPass123',
        newPassword: 'newPass456',
      );

      expect(result, isNull);
    });

    test('sends correct body with current and new password', () async {
      api.stubPatch('/api/v1/users/me/password', {'message': 'OK'});

      await profileService.changePassword(
        currentPassword: 'current',
        newPassword: 'newpass',
      );

      final body = api.calls.last.body as Map<String, dynamic>;
      expect(body['current_password'], 'current');
      expect(body['new_password'], 'newpass');
    });

    test('returns error message on failure', () async {
      api.stubPatchError(
        '/api/v1/users/me/password',
        message: 'Current password is incorrect',
      );

      final result = await profileService.changePassword(
        currentPassword: 'wrong',
        newPassword: 'newpass',
      );

      expect(result, 'Current password is incorrect');
    });

    test('returns fallback message when error has no message', () async {
      api.stubPatchError(
        '/api/v1/users/me/password',
        message: '',
      );

      final result = await profileService.changePassword(
        currentPassword: 'old',
        newPassword: 'new',
      );

      expect(result, 'Failed to change password');
    });
  });

  group('ProfileService.uploadProfilePhoto', () {
    // Note: uploadProfilePhoto uses http.MultipartRequest directly,
    // which bypasses FakeApiClient. We test the tokenProvider check only.

    test('throws when not authenticated', () async {
      tokenProvider.token = null;

      expect(
        () => profileService.uploadProfilePhoto(
          // Provide a minimal Uint8List
          Uint8List.fromList([0, 0, 0]),
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Not authenticated'),
        )),
      );
    });
  });
}
