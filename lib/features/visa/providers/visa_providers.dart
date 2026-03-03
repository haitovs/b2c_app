import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../services/visa_service.dart';

/// Provider for VisaService.
final visaServiceProvider = Provider<VisaService>((ref) {
  return VisaService(ref.watch(authNotifierProvider.notifier));
});
