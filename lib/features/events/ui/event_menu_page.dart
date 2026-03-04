import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_config.dart';
import '../../../../shared/layouts/event_sidebar_layout.dart';
import '../../../../core/providers/event_context_provider.dart';
import '../../../../core/widgets/attention_seeker.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';

class EventMenuPage extends ConsumerStatefulWidget {
  final int eventId;

  const EventMenuPage({super.key, required this.eventId});

  @override
  ConsumerState<EventMenuPage> createState() => _EventMenuPageState();
}

class _EventMenuPageState extends ConsumerState<EventMenuPage> {
  List<Map<String, dynamic>> _sponsors = [];
  bool _isLoadingSponsors = true;

  // Event data for dynamic title
  Map<String, dynamic>? _eventData;

  // Registration status
  bool _isRegistered = false;
  bool _isCheckingRegistration = true;

  // Registration button highlight
  bool _showRegistrationHighlight = false;

  // For endless scrolling carousel
  late ScrollController _sponsorScrollController;
  Timer? _sponsorScrollTimer;
  Timer? _sponsorRefreshTimer;

  @override
  void initState() {
    super.initState();
    _sponsorScrollController = ScrollController();
    _initializeAndFetch();
  }

  Future<void> _initializeAndFetch() async {
    await ref.read(eventContextProvider.notifier).ensureEventContext(widget.eventId);
    _fetchEvent();
    _fetchSponsors();
    _startPeriodicSponsorRefresh();
    _checkRegistrationStatus();
    _checkParticipantAutoRegistration();
  }

  void _startPeriodicSponsorRefresh() {
    _sponsorRefreshTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      _fetchSponsors();
    });
  }

  Future<void> _checkRegistrationStatus() async {
    try {
      final token = await ref.read(authNotifierProvider.notifier).getToken();

      final response = await http.get(
        Uri.parse(
          '${AppConfig.b2cApiBaseUrl}/api/v1/registrations/my-status?event_id=${widget.eventId}',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['status'];

        setState(() {
          _isRegistered =
              status == 'ACCEPTED' ||
              status == 'APPROVED' ||
              status == 'SUBMITTED';
          _isCheckingRegistration = false;
        });
      } else {
        setState(() {
          _isRegistered = false;
          _isCheckingRegistration = false;
        });
      }
    } catch (e) {
      debugPrint('[EventMenu] Error checking registration: $e');
      if (mounted) {
        setState(() {
          _isRegistered = false;
          _isCheckingRegistration = false;
        });
      }
    }
  }

  Future<void> _checkParticipantAutoRegistration() async {
    try {
      final token = await ref.read(authNotifierProvider.notifier).getToken();

      final response = await http.get(
        Uri.parse(
          '${AppConfig.b2cApiBaseUrl}/api/v1/participant-auth/my-profile',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _isRegistered = true;
        });
      }
    } catch (e) {
      debugPrint('[EventMenu] Error checking participant status: $e');
    }
  }

  Future<void> _fetchEvent() async {
    try {
      final uri = Uri.parse(
        '${AppConfig.b2cApiBaseUrl}/api/v1/events/${widget.eventId}',
      );
      final response = await http.get(uri);
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _eventData = data;
        });
      }
    } catch (e) {
      // Silently fail - event header will show defaults
    }
  }

  @override
  void dispose() {
    _sponsorScrollTimer?.cancel();
    _sponsorRefreshTimer?.cancel();
    _sponsorScrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchSponsors() async {
    try {
      final siteId = ref.read(eventContextProvider).siteId;
      final uri = siteId != null
          ? Uri.parse(
              '${AppConfig.tourismApiBaseUrl}/sponsors/?site_id=$siteId',
            )
          : Uri.parse('${AppConfig.tourismApiBaseUrl}/sponsors/');
      final response = await http.get(uri);
      if (!mounted) return;

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _sponsors = data.cast<Map<String, dynamic>>();
          _isLoadingSponsors = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _startAutoScroll();
        });
      } else {
        setState(() => _isLoadingSponsors = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingSponsors = false);
    }
  }

  void _startAutoScroll() {
    if (_sponsors.isEmpty) return;

    _sponsorScrollTimer = Timer.periodic(const Duration(milliseconds: 30), (
      timer,
    ) {
      if (_sponsorScrollController.hasClients) {
        final maxScroll = _sponsorScrollController.position.maxScrollExtent;
        final currentScroll = _sponsorScrollController.offset;

        if (currentScroll >= maxScroll) {
          _sponsorScrollController.jumpTo(0);
        } else {
          _sponsorScrollController.jumpTo(currentScroll + 1);
        }
      }
    });
  }

  void _onExitEvent() {
    ref.read(eventContextProvider.notifier).clearContext();
    context.go('/');
  }

  Color _getTierColor(String? tier) {
    switch (tier?.toLowerCase()) {
      case 'premier':
      case 'diamond':
        return const Color(0xFFB9F2FF);
      case 'platinum':
        return const Color(0xFFE5E4E2);
      case 'gold':
        return const Color(0xFFFFD700);
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'bronze':
        return const Color(0xFFCD7F32);
      case 'general':
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final eventTitle = _eventData?['title'] ?? 'Dashboard';

    final menuItems = <Map<String, dynamic>>[
      // Visa Application — first position, always accessible
      {
        'icon': 'registration.png',
        'label': 'Visa Application',
        'route': '/events/${widget.eventId}/visa-travel',
        'isRegistrationButton': true,
      },
      // Items requiring registration
      {
        'icon': 'agenda.png',
        'label': l10n.agenda,
        'route': '/events/${widget.eventId}/agenda',
        'requiresRegistration': true,
      },
      {
        'icon': 'speakers.png',
        'label': l10n.speakers,
        'route': '/events/${widget.eventId}/speakers',
        'requiresRegistration': true,
        'requiresAgreement': true,
      },
      {
        'icon': 'participants.png',
        'label': l10n.participants,
        'route': '/events/${widget.eventId}/participants',
        'requiresRegistration': true,
        'requiresAgreement': true,
      },
      {
        'icon': 'meetings.png',
        'label': l10n.meetings,
        'route': '/events/${widget.eventId}/meetings',
        'requiresRegistration': true,
        'requiresAgreement': true,
      },
      {
        'icon': 'flights.png',
        'label': l10n.flights,
        'route': '/events/${widget.eventId}/flights',
        'requiresRegistration': true,
        'requiresAgreement': true,
      },
      {
        'icon': 'transfer.png',
        'label': l10n.transfer,
        'route': '/events/${widget.eventId}/transfer',
        'requiresRegistration': true,
        'requiresAgreement': true,
      },
      // Always available items
      {
        'icon': 'news.png',
        'label': l10n.news,
        'route': '/events/${widget.eventId}/news',
      },
      {
        'icon': 'hotline.png',
        'label': l10n.hotline,
        'route': '/events/${widget.eventId}/hotline',
      },
      {
        'icon': 'feedback.png',
        'label': l10n.feedback,
        'route': '/events/${widget.eventId}/feedback',
      },
      {
        'icon': 'faq.png',
        'label': l10n.faq,
        'route': '/events/${widget.eventId}/faq',
      },
      {'icon': 'exit', 'label': l10n.exitEvent, 'route': null, 'isExit': true},
    ];

    return EventSidebarLayout(
      title: eventTitle,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 0 : 40,
          vertical: 20,
        ),
        child: Column(
          children: [
            // Sponsors Carousel (endless scrolling)
            if (_isLoadingSponsors)
              const SizedBox(
                height: 100,
                child: Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ),
              )
            else if (_sponsors.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  controller: _sponsorScrollController,
                  scrollDirection: Axis.horizontal,
                  itemCount: _sponsors.length * 100,
                  itemBuilder: (context, index) {
                    final s = _sponsors[index % _sponsors.length];
                    final tier = s['tier'] as String? ?? 'general';
                    final tierColor = _getTierColor(tier);
                    final rawLogoUrl = s['logo'] as String?;
                    final website = s['website'] as String?;

                    String? fullLogoUrl;
                    if (rawLogoUrl != null && rawLogoUrl.isNotEmpty) {
                      if (rawLogoUrl.startsWith('http')) {
                        fullLogoUrl = rawLogoUrl;
                      } else {
                        fullLogoUrl =
                            '${AppConfig.tourismApiBaseUrl}$rawLogoUrl';
                      }
                    }

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () async {
                          if (website != null && website.isNotEmpty) {
                            String url = website;
                            if (!url.startsWith('http://') &&
                                !url.startsWith('https://')) {
                              url = 'https://$url';
                            }
                            try {
                              final uri = Uri.parse(url);
                              await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                            } catch (e) {
                              debugPrint('Could not launch $url: $e');
                            }
                          }
                        },
                        child: Container(
                          width: 160,
                          margin: const EdgeInsets.only(right: 15),
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: tierColor.withValues(alpha: 0.5),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: (fullLogoUrl != null)
                                    ? Image.network(
                                        fullLogoUrl,
                                        fit: BoxFit.contain,
                                        errorBuilder: (c, e, s) => Icon(
                                          Icons.business,
                                          color: tierColor,
                                          size: 40,
                                        ),
                                      )
                                    : Icon(
                                        Icons.business,
                                        color: tierColor,
                                        size: 40,
                                      ),
                              ),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                  horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF262B60)
                                      .withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  tier.toUpperCase(),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.roboto(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              const SizedBox(height: 100),

            const SizedBox(height: 25),

            // Menu Grid (responsive: 3 columns mobile, 5 columns desktop)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isMobile ? double.infinity : 900,
                  ),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isMobile ? 3 : 5,
                          mainAxisSpacing: isMobile ? 10 : 20,
                          crossAxisSpacing: isMobile ? 10 : 20,
                          childAspectRatio: isMobile ? 0.9 : 1.0,
                        ),
                    itemCount: menuItems.length,
                    itemBuilder: (context, index) {
                      final item = menuItems[index];
                      final isExit = item['isExit'] == true;
                      final iconName = item['icon'] as String;
                      final isRegistrationButton =
                          item['isRegistrationButton'] == true;
                      final requiresRegistration =
                          item['requiresRegistration'] == true;

                      final isDisabled =
                          requiresRegistration &&
                          !_isRegistered &&
                          !_isCheckingRegistration;

                      Widget cardContent = Container(
                        decoration: BoxDecoration(
                          color: isExit
                              ? Colors.orange.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isExit
                                ? Colors.orange.withValues(alpha: 0.3)
                                : Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Opacity(
                                opacity: isDisabled ? 0.4 : 1.0,
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isExit)
                                      Icon(
                                        Icons.exit_to_app,
                                        color: Colors.orange,
                                        size: isMobile ? 48 : 52,
                                      )
                                    else
                                      Image.asset(
                                        'assets/event_menu/$iconName',
                                        width: isMobile ? 64 : 58,
                                        height: isMobile ? 64 : 58,
                                        errorBuilder: (c, e, s) =>
                                            const Icon(
                                              Icons.image,
                                              color: Colors.white54,
                                              size: 24,
                                            ),
                                      ),
                                    SizedBox(
                                      height: isMobile ? 4 : 8,
                                    ),
                                    Padding(
                                      padding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 4.0,
                                          ),
                                      child: Text(
                                        item['label'] as String,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.roboto(
                                          fontSize: isMobile ? 14 : 18,
                                          fontWeight: FontWeight.w500,
                                          color: isExit
                                              ? Colors.orange
                                              : const Color(0xFFF1F1F6),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (isDisabled)
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.lock_outline,
                                    color: Colors.white70,
                                    size: 14,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );

                      if (isRegistrationButton) {
                        cardContent = AttentionSeeker(
                          animate: _showRegistrationHighlight,
                          glowColor: Colors.greenAccent,
                          repeatCount: 3,
                          onAnimationComplete: () {
                            if (mounted) {
                              setState(
                                () => _showRegistrationHighlight = false,
                              );
                            }
                          },
                          child: cardContent,
                        );
                      }

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            if (isDisabled) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please register for this event first',
                                  ),
                                  backgroundColor: Color(0xFF3C4494),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              setState(
                                () => _showRegistrationHighlight = true,
                              );
                              return;
                            }

                            if (isExit) {
                              _onExitEvent();
                            } else if (item['route'] != null) {
                              final requiresAgreement =
                                  item['requiresAgreement'] == true;
                              final hasAgreed = ref
                                  .read(authNotifierProvider)
                                  .hasAgreedTerms;

                              if (requiresAgreement && !hasAgreed) {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text(
                                      'Agreement Required',
                                    ),
                                    content: const Text(
                                      'Please complete the Participation Agreement Process in your Profile before accessing this feature.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                          context.go(
                                            '/profile?tab=0&returnTo=/events/${widget.eventId}/menu',
                                          );
                                        },
                                        child: const Text(
                                          'Go to Profile',
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                                return;
                              }
                              context.go(item['route'] as String);
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          splashColor: isDisabled
                              ? Colors.transparent
                              : Colors.white24,
                          highlightColor: isDisabled
                              ? Colors.transparent
                              : Colors.white10,
                          child: cardContent,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
