// User-scoped analytics data models for the Flutter analytics page.

class LabelCount {
  final String label;
  final int count;

  LabelCount({required this.label, required this.count});

  factory LabelCount.fromJson(Map<String, dynamic> json) => LabelCount(
        label: json['label'] as String,
        count: json['count'] as int,
      );
}

class UserViewsSummary {
  final int totalProfileViews;
  final int companyProfileViews;
  final int b2bMeetingsCount;
  final int b2gMeetingsCount;

  UserViewsSummary({
    required this.totalProfileViews,
    required this.companyProfileViews,
    required this.b2bMeetingsCount,
    required this.b2gMeetingsCount,
  });

  factory UserViewsSummary.fromJson(Map<String, dynamic> json) =>
      UserViewsSummary(
        totalProfileViews: json['total_profile_views'] as int,
        companyProfileViews: json['company_profile_views'] as int,
        b2bMeetingsCount: json['b2b_meetings_count'] as int,
        b2gMeetingsCount: json['b2g_meetings_count'] as int,
      );
}

class TeamMemberViewRow {
  final String id;
  final String firstName;
  final String lastName;
  final String? photoUrl;
  final int viewCount;

  TeamMemberViewRow({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.photoUrl,
    required this.viewCount,
  });

  factory TeamMemberViewRow.fromJson(Map<String, dynamic> json) =>
      TeamMemberViewRow(
        id: json['id'] as String,
        firstName: json['first_name'] as String,
        lastName: json['last_name'] as String,
        photoUrl: json['photo_url'] as String?,
        viewCount: json['view_count'] as int,
      );
}

class UserMeetingSummary {
  final int b2bTotal;
  final int b2gTotal;
  final List<LabelCount> byStatus;

  UserMeetingSummary({
    required this.b2bTotal,
    required this.b2gTotal,
    required this.byStatus,
  });

  factory UserMeetingSummary.fromJson(Map<String, dynamic> json) =>
      UserMeetingSummary(
        b2bTotal: json['b2b_total'] as int,
        b2gTotal: json['b2g_total'] as int,
        byStatus: (json['by_status'] as List)
            .map((e) => LabelCount.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class UserOrderSummary {
  final int totalOrders;
  final int approvedOrders;
  final double totalSpentUsd;

  UserOrderSummary({
    required this.totalOrders,
    required this.approvedOrders,
    required this.totalSpentUsd,
  });

  factory UserOrderSummary.fromJson(Map<String, dynamic> json) =>
      UserOrderSummary(
        totalOrders: json['total_orders'] as int,
        approvedOrders: json['approved_orders'] as int,
        totalSpentUsd: (json['total_spent_usd'] as num).toDouble(),
      );
}

class UserVisaSummary {
  final int totalApplications;
  final List<LabelCount> byStatus;

  UserVisaSummary({
    required this.totalApplications,
    required this.byStatus,
  });

  factory UserVisaSummary.fromJson(Map<String, dynamic> json) =>
      UserVisaSummary(
        totalApplications: json['total_applications'] as int,
        byStatus: (json['by_status'] as List)
            .map((e) => LabelCount.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class UserRegistrationSummary {
  final int total;
  final List<LabelCount> byStatus;

  UserRegistrationSummary({
    required this.total,
    required this.byStatus,
  });

  factory UserRegistrationSummary.fromJson(Map<String, dynamic> json) =>
      UserRegistrationSummary(
        total: json['total'] as int,
        byStatus: (json['by_status'] as List)
            .map((e) => LabelCount.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class UserAnalyticsData {
  final int eventId;
  final int dateRangeDays;
  final UserViewsSummary summary;
  final UserMeetingSummary meetings;
  final List<TeamMemberViewRow> teamMemberViews;
  final UserOrderSummary orders;
  final UserVisaSummary visa;
  final UserRegistrationSummary registration;
  final bool hasCompany;

  UserAnalyticsData({
    required this.eventId,
    required this.dateRangeDays,
    required this.summary,
    required this.meetings,
    required this.teamMemberViews,
    required this.orders,
    required this.visa,
    required this.registration,
    required this.hasCompany,
  });

  factory UserAnalyticsData.fromJson(Map<String, dynamic> json) =>
      UserAnalyticsData(
        eventId: json['event_id'] as int,
        dateRangeDays: json['date_range_days'] as int,
        summary: UserViewsSummary.fromJson(
            json['summary'] as Map<String, dynamic>),
        meetings: UserMeetingSummary.fromJson(
            json['meetings'] as Map<String, dynamic>),
        teamMemberViews: (json['team_member_views'] as List)
            .map((e) =>
                TeamMemberViewRow.fromJson(e as Map<String, dynamic>))
            .toList(),
        orders: UserOrderSummary.fromJson(
            json['orders'] as Map<String, dynamic>),
        visa: UserVisaSummary.fromJson(
            json['visa'] as Map<String, dynamic>),
        registration: UserRegistrationSummary.fromJson(
            json['enrollment'] as Map<String, dynamic>),
        hasCompany: json['has_company'] as bool,
      );
}
