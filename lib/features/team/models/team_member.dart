/// Enum representing a team member's role within a company.
enum TeamMemberRole { user, administrator }

/// Team member model representing a person within a company profile.
class TeamMember {
  final String id;
  final String companyId;
  final String? createdByUserId;
  final String? userId;
  final String firstName;
  final String lastName;
  final String email;
  final String? mobile;
  final String? country;
  final String? city;
  final String? position;
  final String? profilePhotoUrl;
  final Map<String, dynamic>? socialLinks;
  final TeamMemberRole role;
  final bool isActive;
  final bool passwordTokenUsed;
  final String? createdAt;
  final String? updatedAt;

  TeamMember({
    required this.id,
    required this.companyId,
    this.createdByUserId,
    this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.mobile,
    this.country,
    this.city,
    this.position,
    this.profilePhotoUrl,
    this.socialLinks,
    required this.role,
    required this.isActive,
    required this.passwordTokenUsed,
    this.createdAt,
    this.updatedAt,
  });

  /// Full display name.
  String get fullName => '$firstName $lastName';

  /// Whether this member has an administrator role.
  bool get isAdmin => role == TeamMemberRole.administrator;

  /// Parse a role string from the API (e.g. "USER", "ADMINISTRATOR") into enum.
  static TeamMemberRole _parseRole(String? role) {
    switch (role?.toUpperCase()) {
      case 'ADMINISTRATOR':
        return TeamMemberRole.administrator;
      case 'USER':
      default:
        return TeamMemberRole.user;
    }
  }

  /// Convert role enum back to API string.
  static String _roleToString(TeamMemberRole role) {
    switch (role) {
      case TeamMemberRole.administrator:
        return 'ADMINISTRATOR';
      case TeamMemberRole.user:
        return 'USER';
    }
  }

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      createdByUserId: json['created_by_user_id'] as String?,
      userId: json['user_id'] as String?,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      email: json['email'] as String,
      mobile: json['mobile'] as String?,
      country: json['country'] as String?,
      city: json['city'] as String?,
      position: json['position'] as String?,
      profilePhotoUrl: json['profile_photo_url'] as String?,
      socialLinks: json['social_links'] as Map<String, dynamic>?,
      role: _parseRole(json['role'] as String?),
      isActive: json['is_active'] as bool? ?? true,
      passwordTokenUsed: json['password_token_used'] as bool? ?? false,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'created_by_user_id': createdByUserId,
      'user_id': userId,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'mobile': mobile,
      'country': country,
      'city': city,
      'position': position,
      'profile_photo_url': profilePhotoUrl,
      'social_links': socialLinks,
      'role': _roleToString(role),
      'is_active': isActive,
      'password_token_used': passwordTokenUsed,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
