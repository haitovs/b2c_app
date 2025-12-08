import 'package:b2c_app/features/profile/ui/profile_page.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/services/auth_service.dart';
import '../features/auth/ui/login_page.dart';
import '../features/auth/ui/registration_page.dart';
import '../features/events/ui/agenda_page.dart';
import '../features/events/ui/event_calendar_page.dart';
import '../features/events/ui/event_details_page.dart';
import '../features/events/ui/event_menu_page.dart';
import '../features/events/ui/speaker_detail_page.dart';
import '../features/events/ui/speaker_list_page.dart';
import '../features/networking/ui/meeting_list_page.dart';
import '../features/networking/ui/meeting_request_page.dart';

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
      final isLoggingIn = state.uri.toString() == '/login';
      final isRegistering = state.uri.toString() == '/register';

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
        ],
      ),
      GoRoute(
        path: '/meetings',
        builder: (context, state) => const MeetingListPage(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const MeetingRequestPage(),
          ),
        ],
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfilePage(),
      ),
    ],
  );
}

// We need to inject AuthService. 
// Since router is defined globally, we might need a workaround or dependency injection setup.
// For now, let's assume we can pass it or change how router is initialized.

