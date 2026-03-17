import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/faq_item.dart';
import '../services/faq_service.dart';

/// Provider for FAQService.
final faqServiceProvider = Provider<FAQService>((ref) {
  return FAQService(ref.watch(authApiClientProvider));
});

/// Fetch FAQs for a given event.
final faqListProvider =
    FutureProvider.family<List<FAQItem>, int?>((ref, eventId) {
  return ref.watch(faqServiceProvider).getFAQs(eventId: eventId);
});
