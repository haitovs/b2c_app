import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../services/feedback_service.dart';

/// Provider for FeedbackService.
final feedbackServiceProvider = Provider<FeedbackService>((ref) {
  return FeedbackService(ref.watch(authApiClientProvider));
});
