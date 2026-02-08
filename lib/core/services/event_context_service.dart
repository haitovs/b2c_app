import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

/// Service to manage the current event context across the app.
/// This includes the B2C event_id and the Tourism site_id.
///
/// Usage:
/// - Initialize at app startup: `await EventContextService().init()`
/// - Ensure context for a page: `await EventContextService().ensureEventContext(eventId)`
/// - Set context when entering event: `EventContextService().setEventContext(...)`
/// - Read context anywhere: `EventContextService().siteId` or `EventContextService().eventId`
class EventContextService extends ChangeNotifier {
  static final EventContextService _instance = EventContextService._internal();
  factory EventContextService() => _instance;
  EventContextService._internal();

  static const String _siteIdKey = 'current_site_id';
  static const String _eventIdKey = 'current_event_id';

  int? _siteId;
  int? _eventId;
  bool _isInitialized = false;
  bool _isFetching = false;

  /// The current Tourism site_id for API calls
  int? get siteId => _siteId;

  /// The current B2C event_id
  int? get eventId => _eventId;

  /// Whether the service has been initialized from storage
  bool get isInitialized => _isInitialized;

  /// Initialize the service by loading saved context from storage.
  /// Call this in main.dart before runApp().
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _siteId = prefs.getInt(_siteIdKey);
      _eventId = prefs.getInt(_eventIdKey);
      _isInitialized = true;
    } catch (e) {
      debugPrint('EventContextService init error: $e');
      _isInitialized = true; // Mark as initialized even on error
    }
  }

  /// Ensure the event context is loaded for the given event ID.
  /// If the current event_id doesn't match, fetch the event from the API
  /// and update the context. This handles direct navigation and page refreshes.
  ///
  /// Returns true if context was successfully loaded/verified.
  Future<bool> ensureEventContext(int requiredEventId) async {
    // If already have the correct context, return immediately
    if (_eventId == requiredEventId && _siteId != null) {
      debugPrint('EventContext already correct for event $requiredEventId');
      return true;
    }

    // Prevent concurrent fetches
    if (_isFetching) {
      debugPrint('EventContext fetch already in progress');
      return false;
    }

    _isFetching = true;
    debugPrint('Fetching event $requiredEventId to get site_id...');

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.b2cApiBaseUrl}/api/v1/events/$requiredEventId'),
      );

      if (response.statusCode == 200) {
        final eventData = jsonDecode(response.body);
        final tourismSiteId = eventData['tourism_site_id'] as int?;

        // Update context
        await setEventContext(
          eventId: requiredEventId,
          tourismSiteId: tourismSiteId,
        );

        debugPrint(
          'EventContext updated from API: eventId=$requiredEventId, siteId=$tourismSiteId',
        );
        _isFetching = false;
        return true;
      } else {
        debugPrint(
          'Failed to fetch event $requiredEventId: ${response.statusCode}',
        );
        _isFetching = false;
        return false;
      }
    } catch (e) {
      debugPrint('Error fetching event context: $e');
      _isFetching = false;
      return false;
    }
  }

  /// Set the event context when user enters an event.
  /// This saves to SharedPreferences and updates in-memory values.
  Future<void> setEventContext({
    required int eventId,
    required int? tourismSiteId,
  }) async {
    _eventId = eventId;
    _siteId = tourismSiteId;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_eventIdKey, eventId);
      if (tourismSiteId != null) {
        await prefs.setInt(_siteIdKey, tourismSiteId);
      } else {
        await prefs.remove(_siteIdKey);
      }
      debugPrint('EventContext saved: eventId=$eventId, siteId=$tourismSiteId');
    } catch (e) {
      debugPrint('EventContextService save error: $e');
    }
  }

  /// Clear the event context (e.g., when logging out).
  Future<void> clearContext() async {
    _eventId = null;
    _siteId = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_eventIdKey);
      await prefs.remove(_siteIdKey);
    } catch (e) {
      debugPrint('EventContextService clear error: $e');
    }
  }

  /// Check if we have a valid site_id for Tourism API calls
  bool get hasSiteId => _siteId != null;

  /// Get site_id or throw if not available
  /// Get site_id or throw if not available
  int get requireSiteId {
    if (_siteId == null) {
      throw StateError(
        'No Tourism site_id available. User must enter an event first.',
      );
    }
    return _siteId!;
  }

  /// Whether there's an active event context
  bool get hasEventContext => _eventId != null;

  /// The path to the event menu for the current event
  String get eventMenuPath => hasEventContext ? '/events/$_eventId/menu' : '/';
}

/// Global instance for easy access
final eventContextService = EventContextService();
