import '../../../core/services/api_client.dart';
import '../models/company.dart';
import '../models/user_limits.dart';

/// Service for managing company profiles via the B2C backend.
class CompanyService {
  final ApiClient _api;

  CompanyService(this._api);

  /// Get all companies owned by the current user for a given event.
  Future<List<Company>> getMyCompanies(int eventId) async {
    final result = await _api.get<List<dynamic>>(
      '/api/v1/companies/mine',
      queryParams: {'event_id': eventId.toString()},
    );

    if (result.isSuccess && result.data != null) {
      return result.data!
          .map((json) => Company.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    throw result.error ?? Exception('Failed to load companies');
  }

  /// Get a single company by ID.
  Future<Company> getCompany(String companyId) async {
    final result = await _api.get<Map<String, dynamic>>(
      '/api/v1/companies/$companyId',
    );

    if (result.isSuccess && result.data != null) {
      return Company.fromJson(result.data!);
    }
    throw result.error ?? Exception('Failed to load company');
  }

  /// Create a new company profile.
  Future<Company> createCompany(Map<String, dynamic> data) async {
    final result = await _api.post<Map<String, dynamic>>(
      '/api/v1/companies',
      body: data,
    );

    if (result.isSuccess && result.data != null) {
      return Company.fromJson(result.data!);
    }
    throw result.error ?? Exception('Failed to create company');
  }

  /// Update an existing company profile.
  Future<Company> updateCompany(
    String companyId,
    Map<String, dynamic> data,
  ) async {
    final result = await _api.put<Map<String, dynamic>>(
      '/api/v1/companies/$companyId',
      body: data,
    );

    if (result.isSuccess && result.data != null) {
      return Company.fromJson(result.data!);
    }
    throw result.error ?? Exception('Failed to update company');
  }

  /// Delete a company by ID.
  Future<void> deleteCompany(String companyId) async {
    final result = await _api.delete<Map<String, dynamic>>(
      '/api/v1/companies/$companyId',
    );

    if (!result.isSuccess) {
      throw result.error ?? Exception('Failed to delete company');
    }
  }

  /// Get the current user's limits for an event.
  Future<UserLimits> getLimits(int eventId) async {
    final result = await _api.get<Map<String, dynamic>>(
      '/api/v1/companies/limits',
      queryParams: {'event_id': eventId.toString()},
    );

    if (result.isSuccess && result.data != null) {
      return UserLimits.fromJson(result.data!);
    }
    throw result.error ?? Exception('Failed to load limits');
  }

  /// Get a public preview of a company profile.
  Future<Company> getCompanyPreview(String companyId) async {
    final result = await _api.get<Map<String, dynamic>>(
      '/api/v1/companies/$companyId/preview',
    );

    if (result.isSuccess && result.data != null) {
      return Company.fromJson(result.data!);
    }
    throw result.error ?? Exception('Failed to load company preview');
  }
}
