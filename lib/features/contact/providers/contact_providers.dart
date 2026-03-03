import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../services/contact_service.dart';

/// Provider for ContactService.
final contactServiceProvider = Provider<ContactService>((ref) {
  return ContactService(ref.watch(authApiClientProvider));
});
