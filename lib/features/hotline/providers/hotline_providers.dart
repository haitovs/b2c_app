import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../services/hotline_service.dart';

/// Provider for HotlineService.
final hotlineServiceProvider = Provider<HotlineService>((ref) {
  final api = ref.watch(authApiClientProvider);
  final tokenProvider = ref.watch(authNotifierProvider.notifier);
  return HotlineService(api, tokenProvider);
});
