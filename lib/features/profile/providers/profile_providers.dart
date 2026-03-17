import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../services/profile_service.dart';

/// Provider for [ProfileService].
///
/// Uses the authenticated API client and token provider from the auth layer.
final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService(
    ref.watch(authApiClientProvider),
    ref.watch(authNotifierProvider.notifier),
  );
});
