import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/company.dart';
import '../models/user_limits.dart';
import '../services/company_service.dart';

/// Provider for CompanyService.
final companyServiceProvider = Provider<CompanyService>((ref) {
  return CompanyService(ref.watch(authApiClientProvider));
});

/// Fetch all companies owned by the current user for a given event.
final myCompaniesProvider =
    FutureProvider.family<List<Company>, int>((ref, eventId) {
  return ref.watch(companyServiceProvider).getMyCompanies(eventId);
});

/// Fetch the current user's limits for a given event.
final userLimitsProvider =
    FutureProvider.family<UserLimits, int>((ref, eventId) {
  return ref.watch(companyServiceProvider).getLimits(eventId);
});

/// Fetch a single company by ID.
final companyDetailProvider =
    FutureProvider.family<Company, String>((ref, companyId) {
  return ref.watch(companyServiceProvider).getCompany(companyId);
});
