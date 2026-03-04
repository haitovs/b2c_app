import '../../../core/services/api_client.dart';
import '../models/team_member.dart';

/// Service for managing team members within a company via the B2C backend.
class TeamService {
  final ApiClient _api;

  TeamService(this._api);

  /// Get all team members for a given company.
  Future<List<TeamMember>> getTeamMembers(String companyId) async {
    final result = await _api.get<List<dynamic>>(
      '/api/v1/team-members/',
      queryParams: {'company_id': companyId},
    );

    if (result.isSuccess && result.data != null) {
      return result.data!
          .map((json) => TeamMember.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    throw result.error ?? Exception('Failed to load team members');
  }

  /// Get a single team member by ID.
  Future<TeamMember> getTeamMember(String memberId) async {
    final result = await _api.get<Map<String, dynamic>>(
      '/api/v1/team-members/$memberId',
    );

    if (result.isSuccess && result.data != null) {
      return TeamMember.fromJson(result.data!);
    }
    throw result.error ?? Exception('Failed to load team member');
  }

  /// Create a new team member.
  Future<TeamMember> createTeamMember(Map<String, dynamic> data) async {
    final result = await _api.post<Map<String, dynamic>>(
      '/api/v1/team-members/',
      body: data,
    );

    if (result.isSuccess && result.data != null) {
      return TeamMember.fromJson(result.data!);
    }
    throw result.error ?? Exception('Failed to create team member');
  }

  /// Update an existing team member.
  Future<TeamMember> updateTeamMember(
    String memberId,
    Map<String, dynamic> data,
  ) async {
    final result = await _api.put<Map<String, dynamic>>(
      '/api/v1/team-members/$memberId',
      body: data,
    );

    if (result.isSuccess && result.data != null) {
      return TeamMember.fromJson(result.data!);
    }
    throw result.error ?? Exception('Failed to update team member');
  }

  /// Delete a team member by ID.
  Future<void> deleteTeamMember(String memberId) async {
    final result = await _api.delete<Map<String, dynamic>>(
      '/api/v1/team-members/$memberId',
    );

    if (!result.isSuccess) {
      throw result.error ?? Exception('Failed to delete team member');
    }
  }

  /// Change a team member's role.
  Future<TeamMember> changeRole(String memberId, String role) async {
    final result = await _api.patch<Map<String, dynamic>>(
      '/api/v1/team-members/$memberId/role',
      body: {'role': role},
    );

    if (result.isSuccess && result.data != null) {
      return TeamMember.fromJson(result.data!);
    }
    throw result.error ?? Exception('Failed to change team member role');
  }
}
