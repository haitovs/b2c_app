import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../models/event_context_state.dart';
import 'shared_preferences_provider.dart';

/// Riverpod notifier for event context state.
/// Replaces both EventContextService (singleton) and SiteContextNotifier.
class EventContextNotifier extends Notifier<EventContextState> {
  static const String _siteIdKey = 'current_site_id';
  static const String _eventIdKey = 'current_event_id';
  static const String _eventNameKey = 'current_event_name';
  static const String _logoUrlKey = 'current_logo_url';

  late final SharedPreferences _prefs;

  @override
  EventContextState build() {
    _prefs = ref.read(sharedPreferencesProvider);
    // Restore from storage synchronously
    final siteId = _prefs.getInt(_siteIdKey);
    final eventId = _prefs.getInt(_eventIdKey);
    final eventName = _prefs.getString(_eventNameKey);
    final logoUrl = _prefs.getString(_logoUrlKey);
    return EventContextState(
      eventId: eventId,
      siteId: siteId,
      eventName: eventName,
      logoUrl: logoUrl,
      isInitialized: true,
    );
  }

  /// Ensure the event context is loaded for the given event ID.
  /// Fetches from API if needed. Returns true on success.
  Future<bool> ensureEventContext(int requiredEventId) async {
    if (state.eventId == requiredEventId &&
        state.eventName != null) {
      return true;
    }

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.b2cApiBaseUrl}/api/v1/events/$requiredEventId'),
      );

      if (response.statusCode == 200) {
        final eventData = jsonDecode(response.body);
        final tourismSiteId = eventData['tourism_site_id'] as int?;
        final name =
            eventData['name'] as String? ?? eventData['title'] as String?;
        final logoUrl = eventData['logo_url'] as String?;
        await setEventContext(
          eventId: requiredEventId,
          tourismSiteId: tourismSiteId,
          eventName: name,
          logoUrl: logoUrl,
        );
        return true;
      } else {
        debugPrint(
          'Failed to fetch event $requiredEventId: ${response.statusCode}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error fetching event context: $e');
      return false;
    }
  }

  /// Set the event context when user enters an event.
  Future<void> setEventContext({
    required int eventId,
    required int? tourismSiteId,
    String? eventName,
    String? logoUrl,
  }) async {
    state = EventContextState(
      eventId: eventId,
      siteId: tourismSiteId,
      eventName: eventName,
      logoUrl: logoUrl,
      isInitialized: true,
    );

    await _prefs.setInt(_eventIdKey, eventId);
    if (tourismSiteId != null) {
      await _prefs.setInt(_siteIdKey, tourismSiteId);
    } else {
      await _prefs.remove(_siteIdKey);
    }
    if (eventName != null) {
      await _prefs.setString(_eventNameKey, eventName);
    } else {
      await _prefs.remove(_eventNameKey);
    }
    if (logoUrl != null) {
      await _prefs.setString(_logoUrlKey, logoUrl);
    } else {
      await _prefs.remove(_logoUrlKey);
    }
  }

  /// Clear the event context.
  Future<void> clearContext() async {
    state = const EventContextState(isInitialized: true);
    await _prefs.remove(_eventIdKey);
    await _prefs.remove(_siteIdKey);
    await _prefs.remove(_eventNameKey);
    await _prefs.remove(_logoUrlKey);
  }

  /// Get site_id or throw if not available.
  int get requireSiteId {
    if (state.siteId == null) {
      throw StateError(
        'No Tourism site_id available. User must enter an event first.',
      );
    }
    return state.siteId!;
  }
}

/// The main event context provider.
final eventContextProvider =
    NotifierProvider<EventContextNotifier, EventContextState>(
      EventContextNotifier.new,
    );

/// Convenience provider: current site ID.
final currentSiteIdProvider = Provider<int?>((ref) {
  return ref.watch(eventContextProvider).siteId;
});

/// Convenience provider: current event ID.
final currentEventIdProvider = Provider<int?>((ref) {
  return ref.watch(eventContextProvider).eventId;
});
