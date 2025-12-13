import 'package:b2c_app/features/profile/ui/profile_page.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/services/auth_service.dart';
import '../features/auth/ui/login_page.dart';
import '../features/auth/ui/registration_page.dart';
import '../features/contact/ui/contact_us_page.dart';
import '../features/events/ui/agenda_page.dart';
import '../features/events/ui/event_calendar_page.dart';
import '../features/events/ui/event_details_page.dart';
import '../features/events/ui/event_menu_page.dart';
import '../features/events/ui/participant_detail_page.dart';
import '../features/events/ui/participant_list_page.dart';
import '../features/events/ui/speaker_detail_page.dart';
import '../features/events/ui/speaker_list_page.dart';
import '../features/faq/ui/faq_page.dart';
import '../features/hotline/ui/hotline_page.dart';
import '../features/networking/ui/meeting_b2g_request_page.dart';
import '../features/networking/ui/meeting_edit_page.dart';
import '../features/networking/ui/meeting_gate_page.dart';
import '../features/networking/ui/meeting_request_page.dart';
import '../features/networking/ui/meeting_review_page.dart';
import '../features/networking/ui/new_meeting_page.dart';
import '../features/news/ui/news_detail_page.dart';
import '../features/news/ui/news_page.dart';

GoRouter createRouter(AuthService authService) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: authService,
    redirect: (context, state) {
      // Wait for auth to initialize before redirecting
      if (!authService.isInitialized) {
        return null; // Stay on current route until auth is ready
      }

      final isAuthenticated = authService.isAuthenticated;
      final location = state.uri.toString();
      final isLoggingIn = location == '/login';
      final isRegistering = location == '/register';

      if (!isAuthenticated && !isLoggingIn && !isRegistering) {
        return '/login';
      }

      if (isAuthenticated && (isLoggingIn || isRegistering)) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegistrationPage(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const EventCalendarPage(),
      ),
      GoRoute(
        path: '/events/:id',
        builder: (context, state) =>
            EventDetailsPage(id: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'menu',
            builder: (context, state) {
              final idStr = state.pathParameters['id']!;
              return EventMenuPage(eventId: int.tryParse(idStr) ?? 0);
            },
          ),
          GoRoute(
            path: 'agenda',
            builder: (context, state) =>
                AgendaPage(eventId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: 'speakers',
            builder: (context, state) =>
                SpeakerListPage(eventId: state.pathParameters['id']!),
            routes: [
              GoRoute(
                path: ':speakerId',
                builder: (context, state) {
                  final eventId = state.pathParameters['id']!;
                  final speakerId = state.pathParameters['speakerId']!;
                  final speakerData = state.extra as Map<String, dynamic>?;
                  return SpeakerDetailPage(
                    eventId: eventId,
                    speakerId: speakerId,
                    speakerData: speakerData,
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: 'participants',
            builder: (context, state) =>
                ParticipantListPage(eventId: state.pathParameters['id']!),
            routes: [
              GoRoute(
                path: ':participantId',
                builder: (context, state) {
                  final eventId = state.pathParameters['id']!;
                  final participantId = state.pathParameters['participantId']!;
                  final participantData = state.extra as Map<String, dynamic>?;
                  return ParticipantDetailPage(
                    eventId: eventId,
                    participantId: participantId,
                    participantData: participantData,
                  );
                },
              ),
            ],
          ),
          // Meetings routes
          GoRoute(
            path: 'meetings',
            builder: (context, state) =>
                MeetingGatePage(eventId: state.pathParameters['id']!),
            routes: [
              // New meeting - participant/entity selection grid
              GoRoute(
                path: 'new',
                builder: (context, state) =>
                    NewMeetingPage(eventId: state.pathParameters['id']!),
              ),
              // Create B2B meeting with selected participant
              GoRoute(
                path: 'new/:participantId',
                builder: (context, state) {
                  final eventId = state.pathParameters['id']!;
                  final participantId = state.pathParameters['participantId']!;
                  final participantData = state.extra as Map<String, dynamic>?;
                  return MeetingRequestPage(
                    eventId: eventId,
                    participantId: participantId,
                    participantData: participantData,
                  );
                },
              ),
              // B2G meeting request route
              GoRoute(
                path: 'b2g/new/:govEntityId',
                builder: (context, state) {
                  final eventId = state.pathParameters['id']!;
                  final govEntityId = state.pathParameters['govEntityId']!;
                  final govEntityData = state.extra as Map<String, dynamic>?;
                  return MeetingB2GRequestPage(
                    eventId: eventId,
                    govEntityId: govEntityId,
                    govEntityData: govEntityData,
                  );
                },
              ),
              // View/Review meeting (for incoming requests)
              GoRoute(
                path: ':meetingId',
                builder: (context, state) {
                  final eventId = state.pathParameters['id']!;
                  final meetingId = state.pathParameters['meetingId']!;
                  final meetingData = state.extra as Map<String, dynamic>?;
                  return MeetingReviewPage(
                    eventId: eventId,
                    meetingId: meetingId,
                    meetingData: meetingData,
                  );
                },
                routes: [
                  // Edit meeting (only for PENDING meetings)
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) {
                      final eventId = state.pathParameters['id']!;
                      final meetingId = state.pathParameters['meetingId']!;
                      final meetingData = state.extra as Map<String, dynamic>?;
                      return MeetingEditPage(
                        eventId: eventId,
                        meetingId: meetingId,
                        meetingData: meetingData,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          // News route
          GoRoute(
            path: 'news',
            builder: (context, state) =>
                NewsPage(eventId: state.pathParameters['id']!),
            routes: [
              GoRoute(
                path: ':newsId',
                builder: (context, state) {
                  final eventId = state.pathParameters['id']!;
                  final newsId = state.pathParameters['newsId']!;
                  final newsData = state.extra as Map<String, dynamic>?;
                  return NewsDetailPage(
                    eventId: eventId,
                    newsId: newsId,
                    newsData: newsData,
                  );
                },
              ),
            ],
          ),
          // Contact Us route
          GoRoute(
            path: 'contact',
            builder: (context, state) =>
                ContactUsPage(eventId: state.pathParameters['id']!),
          ),
          // Hotline route (nested under events)
          GoRoute(
            path: 'hotline',
            builder: (context, state) => const HotlinePage(),
          ),
          // FAQ route
          GoRoute(
            path: 'faq',
            builder: (context, state) =>
                FAQPage(eventId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/hotline',
        builder: (context, state) => const HotlinePage(),
      ),
    ],
  );
}

// We need to inject AuthService. 
// Since router is defined globally, we might need a workaround or dependency injection setup.
// For now, let's assume we can pass it or change how router is initialized.

