import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/registration_data_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/registration_service.dart';

/// Provider for RegistrationService.
final registrationServiceProvider = Provider<RegistrationService>((ref) {
  return RegistrationService(ref.watch(authApiClientProvider));
});

/// Provider for RegistrationDataService.
final registrationDataServiceProvider =
    Provider<RegistrationDataService>((ref) {
  return RegistrationDataService(ref.watch(authApiClientProvider));
});
