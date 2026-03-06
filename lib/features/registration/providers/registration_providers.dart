import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../services/registration_service.dart';

/// Provider for RegistrationService.
final registrationServiceProvider = Provider<RegistrationService>((ref) {
  return RegistrationService(ref.watch(authApiClientProvider));
});
