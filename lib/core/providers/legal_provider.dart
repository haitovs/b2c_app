import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../services/legal_service.dart';

/// Provider for LegalService.
final legalServiceProvider = Provider<LegalService>((ref) {
  return LegalService(ref.watch(authApiClientProvider));
});
