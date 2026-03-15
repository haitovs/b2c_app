import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/analytics/ui/analytics_page.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../providers/event_context_provider.dart';
import '../../features/auth/ui/create_password_page.dart';
import '../../features/auth/ui/forgot_password_page.dart';
import '../../features/auth/ui/forgot_password_verify_code_page.dart';
import '../../features/auth/ui/login_page.dart';
import '../../features/auth/ui/post_login_dispatcher_page.dart';
import '../../features/auth/ui/registration_page.dart';
import '../../features/auth/ui/reset_password_page.dart';
import '../../features/auth/ui/verification_code_page.dart';
import '../../features/auth/ui/verification_pending_page.dart';
import '../../features/auth/ui/verify_email_page.dart';
import '../../features/company/ui/company_preview_page.dart';
import '../../features/company/ui/company_list_page.dart';
import '../../features/company/ui/company_profile_page.dart';
import '../../features/events/ui/agenda_page.dart';
import '../../features/events/ui/event_calendar_page.dart';
import '../../features/events/ui/event_details_page.dart';
import '../../features/events/ui/participant_detail_page.dart';
import '../../features/events/ui/participant_list_page.dart';
import '../../features/events/ui/speaker_detail_page.dart';
import '../../features/events/ui/speaker_list_page.dart';
import '../../features/faq/ui/faq_page.dart';
import '../../features/feedback/ui/feedback_page.dart';
import '../../features/flights/ui/flight_booking_page.dart';
import '../../features/flights/ui/flights_page.dart';
import '../../features/hotline/ui/hotline_page.dart';
import '../../features/networking/ui/company_meeting_preview_page.dart';
import '../../features/networking/ui/meeting_b2g_request_page.dart';
import '../../features/networking/ui/meeting_confirmation_page.dart';
import '../../features/networking/ui/meeting_edit_page.dart';
import '../../features/networking/services/meeting_service.dart';
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
import '../../features/dashboard/ui/dashboard_page.dart';
import '../../shared/layouts/event_sidebar_layout.dart';
import '../../shared/ui/coming_soon_page.dart';
import '../../shared/widgets/legal_document_page.dart';
import '../error_page.dart';
import 'auth_refresh_notifier.dart';

/// Stores the URL the user was trying to reach before being redirected to login.
/// Simple in-memory value — consumed once by PostLoginDispatcherPage.
String? postLoginRedirectUrl;

/// Smooth fade transition for shell-route pages.
/// Sidebar stays mounted; only the content panel fades in.
Page<void> _fadeTransition(Widget child) => CustomTransitionPage<void>(
      child: child,
      transitionDuration: const Duration(milliseconds: 200),
      reverseTransitionDuration: const Duration(milliseconds: 150),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
      },
    );

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
        // Remember where the user wanted to go so we can redirect after login
        postLoginRedirectUrl = location;
        return '/login';
      }

      // After login/register, smart redirect (synchronous checks first)
      if (isAuthenticated && (isLoggingIn || isSigningUp)) {
        // 1. Stored redirect URL (user was trying to reach a protected page)
        final redirect = postLoginRedirectUrl;
        if (redirect != null) {
          postLoginRedirectUrl = null;
          return redirect;
        }
        // 2. Persisted last-visited event
        final eventId = ref.read(eventContextProvider).eventId;
        if (eventId != null) {
          return '/events/$eventId/dashboard';
        }
        // 3. Fall back to async dispatcher (checks registrations)
        return '/post-login';
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
          final eventId = state.uri.queryParameters['event'];
          return CreatePasswordPage(token: token, eventId: eventId);
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
        path: '/post-login',
        builder: (context, state) => const PostLoginDispatcherPage(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const EventCalendarPage(),
      ),
      // Event details — public, no sidebar
      GoRoute(
        path: '/events/:id',
        builder: (context, state) =>
            EventDetailsPage(id: state.pathParameters['id']!),
      ),
      // ─── Event sub-pages — all wrapped in persistent sidebar shell ───
      // Using pageBuilder + CustomTransitionPage with fade so content
      // transitions smoothly (sidebar stays, only right panel fades).
      ShellRoute(
        builder: (context, state, child) => EventShellLayout(child: child),
        routes: [
          GoRoute(
            path: '/events/:id/menu',
            redirect: (context, state) {
              final id = state.pathParameters['id'] ?? '0';
              return '/events/$id/dashboard';
            },
          ),
          GoRoute(
            path: '/events/:id/dashboard',
            pageBuilder: (context, state) =>
                _fadeTransition(const DashboardPage()),
          ),
          GoRoute(
            path: '/events/:id/company-profile',
            pageBuilder: (context, state) =>
                _fadeTransition(const CompanyListPage()),
            routes: [
              GoRoute(
                path: 'add',
                pageBuilder: (context, state) =>
                    _fadeTransition(const CompanyProfilePage()),
              ),
              GoRoute(
                path: ':companyId/edit',
                pageBuilder: (context, state) => _fadeTransition(
                  CompanyProfilePage(
                    companyId: state.pathParameters['companyId'],
                  ),
                ),
              ),
              GoRoute(
                path: ':companyId/preview',
                pageBuilder: (context, state) => _fadeTransition(
                  CompanyPreviewPage(
                    companyId: state.pathParameters['companyId']!,
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/events/:id/team',
            pageBuilder: (context, state) =>
                _fadeTransition(const TeamMembersPage()),
            routes: [
              GoRoute(
                path: 'add',
                pageBuilder: (context, state) =>
                    _fadeTransition(const AddTeamMemberPage()),
              ),
              GoRoute(
                path: ':memberId/edit',
                pageBuilder: (context, state) => _fadeTransition(
                  AddTeamMemberPage(
                    memberId: state.pathParameters['memberId'],
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/events/:id/services',
            pageBuilder: (context, state) =>
                _fadeTransition(const EventServicesPage()),
            routes: [
              GoRoute(
                path: 'cart',
                pageBuilder: (context, state) =>
                    _fadeTransition(const ShoppingCartPage()),
              ),
              GoRoute(
                path: ':serviceId',
                pageBuilder: (context, state) => _fadeTransition(
                  ServiceDetailPage(
                    serviceId: state.pathParameters['serviceId']!,
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/events/:id/visa-travel',
            pageBuilder: (context, state) {
              final idStr = state.pathParameters['id']!;
              final visaId = state.uri.queryParameters['visaId'];
              return _fadeTransition(
                VisaApplicationFormPage(
                  eventId: int.tryParse(idStr) ?? 0,
                  visaId: visaId,
                ),
              );
            },
          ),
          GoRoute(
            path: '/events/:id/services-addons',
            pageBuilder: (context, state) =>
                _fadeTransition(const EventServicesPage()),
          ),
          GoRoute(
            path: '/events/:id/schedule',
            redirect: (context, state) {
              final id = state.pathParameters['id'] ?? '0';
              return '/events/$id/meetings';
            },
          ),
          GoRoute(
            path: '/events/:id/financial',
            pageBuilder: (context, state) => _fadeTransition(
              const ComingSoonPage(featureName: 'Financial Section'),
            ),
          ),
          GoRoute(
            path: '/events/:id/analytics',
            pageBuilder: (context, state) => _fadeTransition(
              const AnalyticsPage(),
            ),
          ),
          GoRoute(
            path: '/events/:id/travel',
            pageBuilder: (context, state) => _fadeTransition(
              const ComingSoonPage(featureName: 'Travel Information'),
            ),
          ),
          GoRoute(
            path: '/events/:id/hotels',
            pageBuilder: (context, state) => _fadeTransition(
              const ComingSoonPage(featureName: 'Hotel Information'),
            ),
          ),
          GoRoute(
            path: '/events/:id/agenda',
            pageBuilder: (context, state) => _fadeTransition(
              AgendaPage(eventId: state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: '/events/:id/speakers',
            pageBuilder: (context, state) => _fadeTransition(
              SpeakerListPage(eventId: state.pathParameters['id']!),
            ),
            routes: [
              GoRoute(
                path: ':speakerId',
                pageBuilder: (context, state) {
                  final eventId = state.pathParameters['id']!;
                  final speakerId = state.pathParameters['speakerId']!;
                  final speakerData = state.extra as Map<String, dynamic>?;
                  return _fadeTransition(
                    SpeakerDetailPage(
                      eventId: eventId,
                      speakerId: speakerId,
                      speakerData: speakerData,
                    ),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/events/:id/participants',
            pageBuilder: (context, state) => _fadeTransition(
              ParticipantListPage(eventId: state.pathParameters['id']!),
            ),
            routes: [
              GoRoute(
                path: ':participantId',
                pageBuilder: (context, state) {
                  final eventId = state.pathParameters['id']!;
                  final participantId =
                      state.pathParameters['participantId']!;
                  final participantData =
                      state.extra as Map<String, dynamic>?;
                  return _fadeTransition(
                    ParticipantDetailPage(
                      eventId: eventId,
                      participantId: participantId,
                      participantData: participantData,
                    ),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/events/:id/meetings',
            pageBuilder: (context, state) => _fadeTransition(
              MeetingGatePage(eventId: state.pathParameters['id']!),
            ),
            routes: [
              // /events/:id/meetings/new — company/entity grid
              // /events/:id/meetings/new/b2b/:participantId — B2B request form
              GoRoute(
                path: 'new',
                pageBuilder: (context, state) {
                  final isB2G = state.uri.queryParameters['type'] == 'b2g';
                  return _fadeTransition(
                    NewMeetingPage(
                      eventId: state.pathParameters['id']!,
                      initialIsB2G: isB2G,
                    ),
                  );
                },
                routes: [
                  GoRoute(
                    path: 'b2b/:participantId',
                    pageBuilder: (context, state) {
                      final eventId = state.pathParameters['id']!;
                      final participantId =
                          state.pathParameters['participantId']!;
                      final participantData =
                          state.extra as Map<String, dynamic>?;
                      return _fadeTransition(
                        MeetingRequestPage(
                          eventId: eventId,
                          participantId: participantId,
                          participantData: participantData,
                        ),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'b2g/:govEntityId',
                    pageBuilder: (context, state) {
                      final eventId = state.pathParameters['id']!;
                      final govEntityId =
                          state.pathParameters['govEntityId']!;
                      final govEntityData =
                          state.extra as Map<String, dynamic>?;
                      return _fadeTransition(
                        MeetingB2GRequestPage(
                          eventId: eventId,
                          govEntityId: govEntityId,
                          govEntityData: govEntityData,
                        ),
                      );
                    },
                  ),
                ],
              ),
              // /events/:id/meetings/confirm — confirmation before sending
              GoRoute(
                path: 'confirm',
                pageBuilder: (context, state) {
                  final data = state.extra as Map<String, dynamic>;
                  final typeStr = data['meeting_type'] as String;
                  final meetingType = typeStr == 'b2g'
                      ? MeetingType.b2g
                      : MeetingType.b2b;
                  return _fadeTransition(
                    MeetingConfirmationPage(
                      meetingType: meetingType,
                      meetingData: data,
                    ),
                  );
                },
              ),
              // /events/:id/meetings/company/:companyId — company preview
              GoRoute(
                path: 'company/:companyId',
                pageBuilder: (context, state) {
                  final eventId = state.pathParameters['id']!;
                  final companyId = state.pathParameters['companyId']!;
                  final companyData =
                      state.extra as Map<String, dynamic>?;
                  return _fadeTransition(
                    CompanyMeetingPreviewPage(
                      eventId: eventId,
                      companyId: companyId,
                      companyData: companyData,
                    ),
                  );
                },
              ),
              // /events/:id/meetings/speaker/:speakerId — speaker meeting request
              GoRoute(
                path: 'speaker/:speakerId',
                pageBuilder: (context, state) {
                  final eventId = state.pathParameters['id']!;
                  final speakerId =
                      int.tryParse(state.pathParameters['speakerId']!) ?? 0;
                  final speakerData =
                      state.extra as Map<String, dynamic>?;
                  final speakerName = speakerData != null
                      ? '${speakerData['name'] ?? ''} ${speakerData['surname'] ?? ''}'.trim()
                      : null;
                  return _fadeTransition(
                    MeetingRequestPage(
                      eventId: eventId,
                      participantId: '',
                      speakerId: speakerId,
                      speakerName: speakerName,
                      participantData: speakerData,
                    ),
                  );
                },
              ),
              // /events/:id/meetings/review/:meetingId — view meeting
              GoRoute(
                path: 'review/:meetingId',
                pageBuilder: (context, state) {
                  final eventId = state.pathParameters['id']!;
                  final meetingId = state.pathParameters['meetingId']!;
                  final meetingData =
                      state.extra as Map<String, dynamic>?;
                  return _fadeTransition(
                    MeetingReviewPage(
                      eventId: eventId,
                      meetingId: meetingId,
                      meetingData: meetingData,
                    ),
                  );
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    pageBuilder: (context, state) {
                      final eventId = state.pathParameters['id']!;
                      final meetingId = state.pathParameters['meetingId']!;
                      final meetingData =
                          state.extra as Map<String, dynamic>?;
                      return _fadeTransition(
                        MeetingEditPage(
                          eventId: eventId,
                          meetingId: meetingId,
                          meetingData: meetingData,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/events/:id/news',
            pageBuilder: (context, state) => _fadeTransition(
              NewsPage(eventId: state.pathParameters['id']!),
            ),
            routes: [
              GoRoute(
                path: ':newsId',
                pageBuilder: (context, state) {
                  final eventId = state.pathParameters['id']!;
                  final newsId = state.pathParameters['newsId']!;
                  final newsData = state.extra as Map<String, dynamic>?;
                  return _fadeTransition(
                    NewsDetailPage(
                      eventId: eventId,
                      newsId: newsId,
                      newsData: newsData,
                    ),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/events/:id/hotline',
            pageBuilder: (context, state) =>
                _fadeTransition(const HotlinePage()),
          ),
          GoRoute(
            path: '/events/:id/faq',
            pageBuilder: (context, state) => _fadeTransition(
              FAQPage(eventId: state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: '/events/:id/feedback',
            pageBuilder: (context, state) => _fadeTransition(
              FeedbackPage(eventId: state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: '/events/:id/transfer',
            pageBuilder: (context, state) {
              final idStr = state.pathParameters['id']!;
              return _fadeTransition(
                TransferPage(eventId: int.tryParse(idStr) ?? 0),
              );
            },
          ),
          GoRoute(
            path: '/events/:id/flights',
            pageBuilder: (context, state) {
              final idStr = state.pathParameters['id']!;
              return _fadeTransition(
                FlightsPage(eventId: int.tryParse(idStr)),
              );
            },
          ),
          GoRoute(
            path: '/events/:id/visa/form/:participantId',
            pageBuilder: (context, state) {
              final eventIdStr = state.pathParameters['id']!;
              final participantId =
                  state.pathParameters['participantId']!;
              final visaId = state.uri.queryParameters['visaId'];
              return _fadeTransition(
                VisaApplicationFormPage(
                  eventId: int.tryParse(eventIdStr) ?? 0,
                  participantId: participantId,
                  visaId: visaId,
                ),
              );
            },
          ),
          GoRoute(
            path: '/events/:id/visa/status/:participantId',
            pageBuilder: (context, state) {
              final eventIdStr = state.pathParameters['id']!;
              final participantId =
                  state.pathParameters['participantId']!;
              return _fadeTransition(
                VisaStatusPage(
                  eventId: int.tryParse(eventIdStr) ?? 0,
                  participantId: participantId,
                ),
              );
            },
          ),
          GoRoute(
            path: '/events/:id/visa/details/:participantId',
            pageBuilder: (context, state) {
              final eventIdStr = state.pathParameters['id']!;
              final participantId =
                  state.pathParameters['participantId']!;
              return _fadeTransition(
                VisaDetailsPage(
                  eventId: int.tryParse(eventIdStr) ?? 0,
                  participantId: participantId,
                ),
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
          final returnTo = state.uri.queryParameters['returnTo'];
          return ProfilePage(returnTo: returnTo);
        },
      ),
    ],
  );
});
