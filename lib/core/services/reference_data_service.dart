import 'api_client.dart';

/// Service for fetching reference data (categories, positions, countries, cities).
class ReferenceDataService {
  final ApiClient _api;

  ReferenceDataService(this._api);

  Future<List<String>> getCompanyCategories() async {
    final result = await _api.get<Map<String, dynamic>>(
      '/api/v1/reference/company-categories',
      auth: false,
    );

    if (result.isSuccess && result.data != null) {
      final list = result.data!['categories'] as List<dynamic>?;
      return list?.map((e) => e.toString()).toList() ?? [];
    }
    throw result.error ?? Exception('Failed to load company categories');
  }

  Future<List<String>> getPositions() async {
    final result = await _api.get<Map<String, dynamic>>(
      '/api/v1/reference/positions',
      auth: false,
    );

    if (result.isSuccess && result.data != null) {
      final list = result.data!['positions'] as List<dynamic>?;
      return list?.map((e) => e.toString()).toList() ?? [];
    }
    throw result.error ?? Exception('Failed to load positions');
  }

  Future<List<String>> getCountries() async {
    final result = await _api.get<Map<String, dynamic>>(
      '/api/v1/reference/countries',
      auth: false,
    );

    if (result.isSuccess && result.data != null) {
      final list = result.data!['countries'] as List<dynamic>?;
      return list?.map((e) => e.toString()).toList() ?? [];
    }
    throw result.error ?? Exception('Failed to load countries');
  }

  Future<List<String>> getCities(String country) async {
    final result = await _api.get<Map<String, dynamic>>(
      '/api/v1/reference/cities',
      auth: false,
      queryParams: {'country': country},
    );

    if (result.isSuccess && result.data != null) {
      final list = result.data!['cities'] as List<dynamic>?;
      return list?.map((e) => e.toString()).toList() ?? [];
    }
    throw result.error ?? Exception('Failed to load cities');
  }
}
