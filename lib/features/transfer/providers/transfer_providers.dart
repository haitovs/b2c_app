import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../services/transfer_service.dart';

/// Provider for TransferService.
final transferServiceProvider = Provider<TransferService>((ref) {
  return TransferService(ref.watch(authApiClientProvider));
});
