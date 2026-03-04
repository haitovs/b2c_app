import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/ui/create_password_page.dart';
import '../../features/auth/ui/forgot_password_page.dart';
import '../../features/auth/ui/forgot_password_verify_code_page.dart';
import '../../features/auth/ui/login_page.dart';
import '../../features/auth/ui/registration_page.dart';
import '../../features/auth/ui/reset_password_page.dart';
import '../../features/auth/ui/verification_code_page.dart';
import '../../features/auth/ui/verification_pending_page.dart';
import '../../features/auth/ui/verify_email_page.dart';
import '../../features/company/ui/company_preview_page.dart';
import '../../features/company/ui/company_profile_page.dart';
import '../../features/events/ui/agenda_page.dart';
import '../../features/events/ui/event_calendar_page.dart';
import '../../features/events/ui/event_details_page.dart';
import '../../features/events/ui/event_menu_page.dart';
import '../../features/events/ui/participant_detail_page.dart';
import '../../features/events/ui/participant_list_page.dart';
import '../../features/events/ui/speaker_detail_page.dart';
import '../../features/events/ui/speaker_list_page.dart';
import '../../features/faq/ui/faq_page.dart';
import '../../features/feedback/ui/feedback_page.dart';
import '../../features/flights/ui/flight_booking_page.dart';
import '../../features/flights/ui/flights_page.dart';
import '../../features/hotline/ui/hotline_page.dart';
import '../../features/networking/ui/meeting_b2g_request_page.dart';
import '../../features/networking/ui/meeting_edit_page.dart';
import '../../features/networking/ui/meeting_gate_page.dart';
import '../../features/networking/ui/meeting_request_page.dart';
import '../../features/networking/ui/meeting_review_page.dart';
import '../../features/networking/ui/new_meeting_page.dart';
import '../../features/news/ui/news_detail_page.dart';
import '../../features/news/ui/news_page.dart';
import '../../features/profile/ui/profile_page.dart';
import '../../features/shop/ui/event_services_page.dart';
import '../../features/shop/ui/service_detail_page.dart';
import '../../features/shop/ui/shopping_cart_page.dart';
import '../../features/team/ui/add_team_member_page.dart';
import '../../features/team/ui/team_members_page.dart';
import '../../features/transfer/ui/transfer_page.dart';
import '../../features/visa/ui/visa_application_form_page.dart';
import '../../features/visa/ui/visa_details_page.dart';
import '../../features/visa/ui/visa_status_page.dart';
import '../../shared/ui/coming_soon_page.dart';
import '../../shared/widgets/legal_document_page.dart';
import '../error_page.dart';
import 'auth_refresh_notifier.dart';

/// Riverpod provider for the app's GoRouter instance.
final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = AuthRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshNotifier,
    errorBuilder: (context, state) =>
        ErrorPage(error: state.error?.message, path: state.uri.toString()),
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);

      // Wait for auth to initialize before redirecting
      if (!authState.isInitialized) {
        return null;
      }

      final isAuthenticated = authState.token != null;
      final location = state.uri.toString();
      final isLoggingIn = location == '/login';
      final isSigningUp = location == '/signup';
      final isVerifyingCode = location.startsWith('/verify-code');
      final isVerifyingEmail = location.startsWith('/verify-email');
      final isForgotPassword = location.startsWith('/forgot-password');
      final isResetPassword = location.startsWith('/reset-password');
      final isLegalPage = location.startsWith('/legal');
      final isCreatePassword = location.startsWith('/create-password');

      // Public pages: home (/), event details (/events/:id), legal, create-password
      final isHome = location == '/';
      final isEventDetails = RegExp(r'^/events/\d+$').hasMatch(location);
      final isPublicPage =
          isHome || isEventDetails || isLegalPage || isCreatePassword;

      final isVerificationPending =
          location.startsWith('/verification-pending');

      // Auth pages that don't require login
      final isAuthPage = isLoggingIn ||
          isSigningUp ||
          isVerifyingCode ||
          isVerifyingEmail ||
          isForgotPassword ||
          isResetPassword ||
          isVerificationPending;

      // Redirect to login if not authenticated and not on a public/auth page
      if (!isAuthenticated && !isPublicPage && !isAuthPage) {
        return '/login';
      }

      // After login/register, redirect to home (user picks event → menu)
      if (isAuthenticated && (isLoggingIn || isSigningUp)) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/legal/:docType',
        builder: (context, state) =>
            LegalDocumentPage(docType: state.pathParameters['docType']!),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/create-password',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return CreatePasswordPage(token: token);
        },
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const RegistrationPage(),
      ),
      GoRoute(
        path: '/verify-code',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          final password = state.uri.queryParameters['password'];
          return VerificationCodePage(email: email, password: password);
        },
      ),
      GoRoute(
        path: '/verification-pending',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return VerificationPendingPage(email: email);
        },
      ),
      GoRoute(
        path: '/forgot-password/verify',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return ForgotPasswordVerifyCodePage(email: email);
        },
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          final code = state.uri.queryParameters['code'] ?? '';
          return ResetPasswordPage(email: email, code: code);
        },
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return VerifyEmailPage(token: token);
        },
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
          // --- NEW: Company Profile ---
          GoRoute(
            path: 'company-profile',
            builder: (context, state) => const CompanyProfilePage(),
            routes: [
              GoRoute(
                path: ':companyId/preview',
                builder: (context, state) => CompanyPreviewPage(
                  companyId: state.pathParameters['companyId']!,
                ),
              ),
            ],
          ),
          // --- NEW: Team Members ---
          GoRoute(
            path: 'team',
            builder: (context, state) => const TeamMembersPage(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (context, state) => const AddTeamMemberPage(),
              ),
              GoRoute(
                path: ':memberId/edit',
                builder: (context, state) => AddTeamMemberPage(
                  memberId: state.pathParameters['memberId'],
                ),
              ),
            ],
          ),
          // --- NEW: Event Services (Shop) ---
          GoRoute(
            path: 'services',
            builder: (context, state) => const EventServicesPage(),
            routes: [
              GoRoute(
                path: 'cart',
                builder: (context, state) => const ShoppingCartPage(),
              ),
              GoRoute(
                path: ':serviceId',
                builder: (context, state) => ServiceDetailPage(
                  serviceId: state.pathParameters['serviceId']!,
                ),
              ),
            ],
          ),
          // --- NEW: Visa & Travel Center (replaces visa-apply) ---
          GoRoute(
            path: 'visa-travel',
            builder: (context, state) {
              final idStr = state.pathParameters['id']!;
              return VisaApplicationFormPage(
                eventId: int.tryParse(idStr) ?? 0,
              );
            },
          ),
          // --- Services & Add-Ons (same as Event Services) ---
          GoRoute(
            path: 'services-addons',
            builder: (context, state) => const EventServicesPage(),
          ),
          // --- RENAMED: Schedule & Meetings (was meetings) ---
          GoRoute(
            path: 'schedule',
            builder: (context, state) =>
                MeetingGatePage(eventId: state.pathParameters['id']!),
          ),
          // --- NEW: Coming Soon pages ---
          GoRoute(
            path: 'financial',
            builder: (context, state) =>
                const ComingSoonPage(featureName: 'Financial Section'),
          ),
          GoRoute(
            path: 'analytics',
            builder: (context, state) =>
                const ComingSoonPage(featureName: 'Analytics'),
          ),
          GoRoute(
            path: 'hotels',
            builder: (context, state) =>
                const ComingSoonPage(featureName: 'Hotels'),
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
                  final participantId =
                      state.pathParameters['participantId']!;
                  final participantData =
                      state.extra as Map<String, dynamic>?;
                  return ParticipantDetailPage(
                    eventId: eventId,
                    participantId: participantId,
                    participantData: participantData,
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: 'meetings',
            builder: (context, state) =>
                MeetingGatePage(eventId: state.pathParameters['id']!),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) {
                  final isB2G = state.uri.queryParameters['type'] == 'b2g';
                  return NewMeetingPage(
                    eventId: state.pathParameters['id']!,
                    initialIsB2G: isB2G,
                  );
                },
              ),
              GoRoute(
                path: 'new/:participantId',
                builder: (context, state) {
                  final eventId = state.pathParameters['id']!;
                  final participantId =
                      state.pathParameters['participantId']!;
                  final participantData =
                      state.extra as Map<String, dynamic>?;
                  return MeetingRequestPage(
                    eventId: eventId,
                    participantId: participantId,
                    participantData: participantData,
                  );
                },
              ),
              GoRoute(
                path: 'b2g/new/:govEntityId',
                builder: (context, state) {
                  final eventId = state.pathParameters['id']!;
                  final govEntityId = state.pathParameters['govEntityId']!;
                  final govEntityData =
                      state.extra as Map<String, dynamic>?;
                  return MeetingB2GRequestPage(
                    eventId: eventId,
                    govEntityId: govEntityId,
                    govEntityData: govEntityData,
                  );
                },
              ),
              GoRoute(
                path: ':meetingId',
                builder: (context, state) {
                  final eventId = state.pathParameters['id']!;
                  final meetingId = state.pathParameters['meetingId']!;
                  final meetingData =
                      state.extra as Map<String, dynamic>?;
                  return MeetingReviewPage(
                    eventId: eventId,
                    meetingId: meetingId,
                    meetingData: meetingData,
                  );
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) {
                      final eventId = state.pathParameters['id']!;
                      final meetingId = state.pathParameters['meetingId']!;
                      final meetingData =
                          state.extra as Map<String, dynamic>?;
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
          GoRoute(
            path: 'hotline',
            builder: (context, state) => const HotlinePage(),
          ),
          GoRoute(
            path: 'faq',
            builder: (context, state) =>
                FAQPage(eventId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: 'feedback',
            builder: (context, state) =>
                FeedbackPage(eventId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: 'transfer',
            builder: (context, state) {
              final idStr = state.pathParameters['id']!;
              return TransferPage(eventId: int.tryParse(idStr) ?? 0);
            },
          ),
          GoRoute(
            path: 'flights',
            builder: (context, state) {
              final idStr = state.pathParameters['id']!;
              return FlightsPage(eventId: int.tryParse(idStr));
            },
          ),
          GoRoute(
            path: 'visa/form/:participantId',
            builder: (context, state) {
              final eventIdStr = state.pathParameters['id']!;
              final participantId =
                  state.pathParameters['participantId']!;
              return VisaApplicationFormPage(
                eventId: int.tryParse(eventIdStr) ?? 0,
                participantId: participantId,
              );
            },
          ),
          GoRoute(
            path: 'visa/status/:participantId',
            builder: (context, state) {
              final eventIdStr = state.pathParameters['id']!;
              final participantId =
                  state.pathParameters['participantId']!;
              return VisaStatusPage(
                eventId: int.tryParse(eventIdStr) ?? 0,
                participantId: participantId,
              );
            },
          ),
          GoRoute(
            path: 'visa/details/:participantId',
            builder: (context, state) {
              final eventIdStr = state.pathParameters['id']!;
              final participantId =
                  state.pathParameters['participantId']!;
              return VisaDetailsPage(
                eventId: int.tryParse(eventIdStr) ?? 0,
                participantId: participantId,
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/flights/:flightId/book',
        builder: (context, state) {
          final flightId = int.parse(state.pathParameters['flightId']!);
          return FlightBookingPage(flightId: flightId);
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) {
          final tab =
              int.tryParse(state.uri.queryParameters['tab'] ?? '1') ?? 1;
          final returnTo = state.uri.queryParameters['returnTo'];
          final highlight = tab == 0;
          return ProfilePage(
            initialTab: tab,
            returnTo: returnTo,
            highlightConfirmButton: highlight,
          );
        },
      ),
      GoRoute(
        path: '/hotline',
        builder: (context, state) => const HotlinePage(),
      ),
    ],
  );
});
