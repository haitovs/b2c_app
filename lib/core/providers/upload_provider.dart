import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../services/upload_service.dart';

/// Provides a shared [UploadService] backed by the current auth token.
final uploadServiceProvider = Provider<UploadService>((ref) {
  final authNotifier = ref.watch(authNotifierProvider.notifier);
  return UploadService(authNotifier);
});
