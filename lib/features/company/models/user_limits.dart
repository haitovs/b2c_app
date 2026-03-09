/// Model representing the current user's limits for an event.
class UserLimits {
  final int maxCompanies;
  final int maxTeamMembersPerCompany;
  final int maxVisas;
  final bool visasUnlimited;
  final String source;
  final int currentCompanies;

  const UserLimits({
    required this.maxCompanies,
    required this.maxTeamMembersPerCompany,
    required this.maxVisas,
    required this.visasUnlimited,
    required this.source,
    required this.currentCompanies,
  });

  factory UserLimits.fromJson(Map<String, dynamic> json) {
    return UserLimits(
      maxCompanies: json['max_companies'] as int? ?? 5,
      maxTeamMembersPerCompany:
          json['max_team_members_per_company'] as int? ?? 5,
      maxVisas: json['max_visas'] as int? ?? 0,
      visasUnlimited: json['visas_unlimited'] as bool? ?? false,
      source: json['source'] as String? ?? 'default',
      currentCompanies: json['current_companies'] as int? ?? 0,
    );
  }

  /// Default limits used as fallback.
  static const UserLimits defaults = UserLimits(
    maxCompanies: 5,
    maxTeamMembersPerCompany: 5,
    maxVisas: 0,
    visasUnlimited: false,
    source: 'default',
    currentCompanies: 0,
  );
}
