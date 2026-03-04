/// Company model representing a business profile within an event.
class Company {
  final String id;
  final String ownerId;
  final int eventId;
  final String name;
  final List<String>? categories;
  final String? website;
  final String? about;
  final String? country;
  final String? city;
  final String? email;
  final String? mobile;
  final String? brandIconUrl;
  final String? fullLogoUrl;
  final String? coverImageUrl;
  final List<String>? galleryUrls;
  final Map<String, dynamic>? socialLinks;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;
  final List<Map<String, dynamic>>? teamMembers;

  Company({
    required this.id,
    required this.ownerId,
    required this.eventId,
    required this.name,
    this.categories,
    this.website,
    this.about,
    this.country,
    this.city,
    this.email,
    this.mobile,
    this.brandIconUrl,
    this.fullLogoUrl,
    this.coverImageUrl,
    this.galleryUrls,
    this.socialLinks,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
    this.teamMembers,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      eventId: json['event_id'] as int,
      name: json['name'] as String,
      categories: (json['categories'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      website: json['website'] as String?,
      about: json['about'] as String?,
      country: json['country'] as String?,
      city: json['city'] as String?,
      email: json['email'] as String?,
      mobile: json['mobile'] as String?,
      brandIconUrl: json['brand_icon_url'] as String?,
      fullLogoUrl: json['full_logo_url'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      galleryUrls: (json['gallery_urls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      socialLinks: json['social_links'] as Map<String, dynamic>?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      teamMembers: (json['team_members'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'event_id': eventId,
      'name': name,
      'categories': categories,
      'website': website,
      'about': about,
      'country': country,
      'city': city,
      'email': email,
      'mobile': mobile,
      'brand_icon_url': brandIconUrl,
      'full_logo_url': fullLogoUrl,
      'cover_image_url': coverImageUrl,
      'gallery_urls': galleryUrls,
      'social_links': socialLinks,
      'is_active': isActive,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'team_members': teamMembers,
    };
  }
}
