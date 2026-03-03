import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../services/news_service.dart';

/// Provider for NewsService.
final newsServiceProvider = Provider<NewsService>((ref) {
  return NewsService(ref.watch(authApiClientProvider));
});
