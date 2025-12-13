import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// State to hold the current Site ID and Event ID
class SiteContextNotifier extends Notifier<int?> {
  static const String _siteIdKey = 'current_site_id';
  static const String _eventIdKey = 'current_event_id';

  int? _currentEventId;
  int? get currentEventId => _currentEventId;

  @override
  int? build() {
    // Try to restore from storage on init
    _restoreFromStorage();
    return null;
  }

  Future<void> _restoreFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedSiteId = prefs.getInt(_siteIdKey);
      final storedEventId = prefs.getInt(_eventIdKey);

      if (storedSiteId != null) {
        state = storedSiteId;
      }
      if (storedEventId != null) {
        _currentEventId = storedEventId;
      }
    } catch (e) {
      // Ignore storage errors
    }
  }

  Future<void> setSiteId(int? id) async {
    state = id;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (id != null) {
        await prefs.setInt(_siteIdKey, id);
      } else {
        await prefs.remove(_siteIdKey);
      }
    } catch (e) {
      // Ignore storage errors
    }
  }

  Future<void> setEventId(int? id) async {
    _currentEventId = id;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (id != null) {
        await prefs.setInt(_eventIdKey, id);
      } else {
        await prefs.remove(_eventIdKey);
      }
    } catch (e) {
      // Ignore storage errors
    }
  }

  Future<void> clearSite() async {
    state = null;
    _currentEventId = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_siteIdKey);
      await prefs.remove(_eventIdKey);
    } catch (e) {
      // Ignore storage errors
    }
  }

  /// Ensures site context is loaded from storage
  Future<void> ensureInitialized() async {
    if (state == null) {
      await _restoreFromStorage();
    }
  }
}

final siteContextProvider = NotifierProvider<SiteContextNotifier, int?>(
  SiteContextNotifier.new,
);
