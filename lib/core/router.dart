import 'package:go_router/go_router.dart';

import '../features/agenda/ui/agenda_page.dart';
import '../features/auth/ui/login_page.dart';
import '../features/auth/ui/registration_page.dart';
import '../features/events/ui/event_calendar_page.dart';
import '../features/events/ui/event_details_page.dart';
import '../features/events/ui/event_menu_page.dart';

final router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegistrationPage(),
    ),
    GoRoute(path: '/', builder: (context, state) => const EventCalendarPage()),
    GoRoute(
      path: '/events/:id',
      builder: (context, state) =>
          EventDetailsPage(id: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/events/:id/menu',
      builder: (context, state) =>
          EventMenuPage(id: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/events/:id/agenda',
      builder: (context, state) => AgendaPage(id: state.pathParameters['id']!),
    ),
  ],
);
