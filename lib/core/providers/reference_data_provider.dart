import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../services/reference_data_service.dart';

/// Provider for ReferenceDataService.
final referenceDataServiceProvider = Provider<ReferenceDataService>((ref) {
  return ReferenceDataService(ref.watch(authApiClientProvider));
});

/// Fetch company categories (LinkedIn industries).
final companyCategoriesProvider = FutureProvider<List<String>>((ref) {
  return ref.watch(referenceDataServiceProvider).getCompanyCategories();
});

/// Fetch standard positions.
final positionsProvider = FutureProvider<List<String>>((ref) {
  return ref.watch(referenceDataServiceProvider).getPositions();
});

/// Fetch countries list.
final countriesProvider = FutureProvider<List<String>>((ref) {
  return ref.watch(referenceDataServiceProvider).getCountries();
});

/// Fetch cities for a given country.
final citiesProvider = FutureProvider.family<List<String>, String>((ref, country) {
  return ref.watch(referenceDataServiceProvider).getCities(country);
});
