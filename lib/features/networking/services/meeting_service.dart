import '../../../core/services/api_client.dart';

/// Meeting types matching the B2C backend enum
enum MeetingType { b2b, b2g }

/// Meeting status matching the B2C backend enum
enum MeetingStatus { pending, confirmed, declined, cancelled }

/// Service for managing meetings via the B2C backend
class MeetingService {
  final ApiClient _api;

  MeetingService(this._api);

  /// Get all meetings for the current user
  Future<List<Map<String, dynamic>>> fetchMyMeetings({int? eventId}) async {
    final queryParams = <String, String>{};
    if (eventId != null) queryParams['event_id'] = eventId.toString();
    final result = await _api.get<List<dynamic>>(
      '/api/v1/meetings',
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );

    if (result.isSuccess && result.data != null) {
      return result.data!.cast<Map<String, dynamic>>();
    } else {
      throw result.error ?? Exception('Failed to load meetings');
    }
  }

  /// Get a single meeting by ID
  Future<Map<String, dynamic>> fetchMeeting(String meetingId) async {
    final result = await _api.get<Map<String, dynamic>>(
      '/api/v1/meetings/$meetingId',
    );

    if (result.isSuccess && result.data != null) {
      return result.data!;
    } else {
      throw result.error ?? Exception('Failed to load meeting');
    }
  }

  /// Create a new meeting request
  Future<Map<String, dynamic>> createMeeting({
    required int eventId,
    required MeetingType type,
    required String subject,
    required DateTime startTime,
    required DateTime endTime,
    String? location,
    String? targetUserId,
    int? targetGovEntityId,
    int? targetOfficialId,
    String? attendeesText,
    String? language,
    String? message,
  }) async {
    final body = {
      'event_id': eventId,
      'type': type.name.toUpperCase(),
      'subject': subject,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      if (location != null) 'location': location,
      if (targetUserId != null) 'target_user_id': targetUserId,
      if (targetGovEntityId != null) 'target_gov_entity_id': targetGovEntityId,
      if (targetOfficialId != null) 'target_official_id': targetOfficialId,
      if (attendeesText != null) 'attendees_text': attendeesText,
      if (language != null) 'language': language,
      if (message != null) 'message': message,
    };

    final result = await _api.post<Map<String, dynamic>>(
      '/api/v1/meetings',
      body: body,
    );

    if (result.isSuccess && result.data != null) {
      return result.data!;
    } else {
      throw result.error ?? Exception('Failed to create meeting');
    }
  }

  /// Update an existing meeting
  Future<Map<String, dynamic>> updateMeeting({
    required String meetingId,
    String? subject,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    String? attendeesText,
    String? message,
  }) async {
    final body = <String, dynamic>{};
    if (subject != null) body['subject'] = subject;
    if (startTime != null) body['start_time'] = startTime.toIso8601String();
    if (endTime != null) body['end_time'] = endTime.toIso8601String();
    if (location != null) body['location'] = location;
    if (attendeesText != null) body['attendees_text'] = attendeesText;
    if (message != null) body['message'] = message;

    final result = await _api.put<Map<String, dynamic>>(
      '/api/v1/meetings/$meetingId',
      body: body,
    );

    if (result.isSuccess && result.data != null) {
      return result.data!;
    } else {
      throw result.error ?? Exception('Failed to update meeting');
    }
  }

  /// Update meeting status (confirm, decline, cancel)
  Future<Map<String, dynamic>> updateMeetingStatus({
    required String meetingId,
    required MeetingStatus status,
  }) async {
    final result = await _api.patch<Map<String, dynamic>>(
      '/api/v1/meetings/$meetingId/status?status_in=${status.name.toUpperCase()}',
    );

    if (result.isSuccess && result.data != null) {
      return result.data!;
    } else {
      throw result.error ?? Exception('Failed to update status');
    }
  }

  /// Fetch meeting locations for an event
  Future<List<Map<String, dynamic>>> fetchLocations(int eventId) async {
    final result = await _api.get<List<dynamic>>(
      '/api/v1/meetings/locations/$eventId',
    );

    if (result.isSuccess && result.data != null) {
      return result.data!.cast<Map<String, dynamic>>();
    } else {
      throw result.error ?? Exception('Failed to load meeting locations');
    }
  }

  /// Get government entities list (for B2G meetings)
  Future<List<Map<String, dynamic>>> fetchGovEntities() async {
    final result = await _api.get<List<dynamic>>(
      '/api/v1/meetings/gov-entities',
    );

    if (result.isSuccess && result.data != null) {
      return result.data!.cast<Map<String, dynamic>>();
    } else {
      throw result.error ?? Exception('Failed to load gov entities');
    }
  }

  /// Respond to a meeting request (accept/decline)
  Future<Map<String, dynamic>> respondToMeeting({
    required String meetingId,
    required String action,
  }) async {
    final result = await _api.post<Map<String, dynamic>>(
      '/api/v1/meetings/$meetingId/respond',
      body: {'action': action},
    );
    if (result.isSuccess && result.data != null) {
      return result.data!;
    } else {
      throw result.error ?? Exception('Failed to respond to meeting');
    }
  }

  /// Cancel a meeting
  Future<Map<String, dynamic>> cancelMeeting(String meetingId) async {
    return updateMeetingStatus(
      meetingId: meetingId,
      status: MeetingStatus.cancelled,
    );
  }

  /// Delete a meeting (requester can delete PENDING, admin can delete any)
  Future<void> deleteMeeting(String meetingId) async {
    final result = await _api.delete<dynamic>(
      '/api/v1/meetings/$meetingId',
    );

    if (!result.isSuccess) {
      throw result.error ?? Exception('Failed to delete meeting');
    }
  }

  /// Fetch public companies for meeting target selection
  Future<List<Map<String, dynamic>>> fetchPublicCompanies({
    required int eventId,
  }) async {
    final result = await _api.get<List<dynamic>>(
      '/api/v1/companies/public',
      queryParams: {'event_id': eventId.toString()},
    );

    if (result.isSuccess && result.data != null) {
      return result.data!.cast<Map<String, dynamic>>();
    } else {
      throw result.error ?? Exception('Failed to load companies');
    }
  }

  /// Fetch a single public company with team members
  Future<Map<String, dynamic>> fetchPublicCompany(String companyId) async {
    final result = await _api.get<Map<String, dynamic>>(
      '/api/v1/companies/public/$companyId',
    );

    if (result.isSuccess && result.data != null) {
      return result.data!;
    } else {
      throw result.error ?? Exception('Failed to load company');
    }
  }

  /// Fetch participants (companies) from B2C backend (for B2B target selection)
  Future<List<Map<String, dynamic>>> fetchParticipants({int? siteId, int? eventId}) async {
    final queryParams = <String, String>{};
    if (eventId != null) {
      queryParams['event_id'] = eventId.toString();
    }

    final result = await _api.get<List<dynamic>>(
      '/api/v1/companies/public',
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );

    if (result.isSuccess && result.data != null) {
      return result.data!.cast<Map<String, dynamic>>();
    } else {
      throw result.error ?? Exception('Failed to load participants');
    }
  }
}
