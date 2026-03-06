/// Immutable state for the current event context.
class EventContextState {
  final int? eventId;
  final int? siteId;
  final String? eventName;
  final String? logoUrl;
  final bool isInitialized;

  const EventContextState({
    this.eventId,
    this.siteId,
    this.eventName,
    this.logoUrl,
    this.isInitialized = false,
  });

  bool get hasSiteId => siteId != null;
  bool get hasEventContext => eventId != null;

  /// The path to the event menu for the current event.
  String get eventMenuPath => hasEventContext ? '/events/$eventId/menu' : '/';

  EventContextState copyWith({
    int? eventId,
    int? siteId,
    String? eventName,
    String? logoUrl,
    bool? isInitialized,
    bool clearEventId = false,
    bool clearSiteId = false,
  }) {
    return EventContextState(
      eventId: clearEventId ? null : (eventId ?? this.eventId),
      siteId: clearSiteId ? null : (siteId ?? this.siteId),
      eventName: eventName ?? this.eventName,
      logoUrl: logoUrl ?? this.logoUrl,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}
