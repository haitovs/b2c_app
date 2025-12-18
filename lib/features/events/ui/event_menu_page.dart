import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/services/event_context_service.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../auth/services/auth_service.dart';
import '../../notifications/ui/notification_drawer.dart';
import 'widgets/profile_dropdown.dart';

class EventMenuPage extends ConsumerStatefulWidget {
  final int eventId;

  const EventMenuPage({super.key, required this.eventId});

  @override
  ConsumerState<EventMenuPage> createState() => _EventMenuPageState();
}

class _EventMenuPageState extends ConsumerState<EventMenuPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isProfileOpen = false;

  List<Map<String, dynamic>> _sponsors = [];
  bool _isLoadingSponsors = true;

  // For endless scrolling carousel
  late ScrollController _sponsorScrollController;
  Timer? _sponsorScrollTimer;

  @override
  void initState() {
    super.initState();
    _sponsorScrollController = ScrollController();
    _initializeAndFetch();
  }

  Future<void> _initializeAndFetch() async {
    // Ensure the event context is loaded for this event
    // This handles direct navigation and page refreshes
    await eventContextService.ensureEventContext(widget.eventId);
    _fetchSponsors();
  }

  @override
  void dispose() {
    _sponsorScrollTimer?.cancel();
    _sponsorScrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchSponsors() async {
    try {
      // Use EventContextService for site_id
      final siteId = eventContextService.siteId;
      // Use query param for site_id instead of header for better compatibility
      final uri = siteId != null
          ? Uri.parse(
              '${AppConfig.tourismApiBaseUrl}/sponsors/?site_id=$siteId',
            )
          : Uri.parse('${AppConfig.tourismApiBaseUrl}/sponsors/');
      final response = await http.get(uri);
      if (!mounted) return; // Check if widget is still mounted

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _sponsors = data.cast<Map<String, dynamic>>();
          _isLoadingSponsors = false;
        });
        // Start auto-scroll after data loads
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

  void _toggleProfile() {
    setState(() {
      _isProfileOpen = !_isProfileOpen;
    });
  }

  void _closeProfile() {
    if (_isProfileOpen) {
      setState(() {
        _isProfileOpen = false;
      });
    }
  }

  void _onExitEvent() {
    eventContextService.clearContext();
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

    // Menu Items (including exit event as last item)
    final menuItems = [
      {
        'icon': 'agenda.png',
        'label': l10n.agenda,
        'route': '/events/${widget.eventId}/agenda',
      },
      {
        'icon': 'speakers.png',
        'label': l10n.speakers,
        'route': '/events/${widget.eventId}/speakers',
        'requiresAgreement': true,
      },
      {
        'icon': 'participants.png',
        'label': l10n.participants,
        'route': '/events/${widget.eventId}/participants',
        'requiresAgreement': true,
      },
      {
        'icon': 'meetings.png',
        'label': l10n.meetings,
        'route': '/events/${widget.eventId}/meetings',
        'requiresAgreement': true,
      },
      {
        'icon': 'news.png',
        'label': l10n.news,
        'route': '/events/${widget.eventId}/news',
      },
      {
        'icon': 'registration.png',
        'label': l10n.registration,
        'route': '/events/${widget.eventId}/registration',
        'requiresAgreement': true,
      },
      {
        'icon': 'my_participants.png',
        'label': l10n.myParticipants,
        'route': '/events/${widget.eventId}/my-participants',
        'requiresAgreement': true,
      },
      {
        'icon': 'flights.png',
        'label': l10n.flights,
        'route': '/events/${widget.eventId}/flights',
        'requiresAgreement': true,
      },
      {
        'icon': 'accommodation.png',
        'label': l10n.accommodation,
        'route': '/events/${widget.eventId}/accommodation',
        'requiresAgreement': true,
      },
      {
        'icon': 'transfer.png',
        'label': l10n.transfer,
        'route': '/events/${widget.eventId}/transfer',
        'requiresAgreement': true,
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
      {
        'icon': 'contact_us.png',
        'label': l10n.contactUs,
        'route': '/events/${widget.eventId}/contact',
      },
      {'icon': 'exit', 'label': l10n.exitEvent, 'route': null, 'isExit': true},
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF3C4494),
      endDrawer: const NotificationDrawer(),
      body: GestureDetector(
        onTap: _closeProfile,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            Column(
              children: [
                // 1. Header with Logo + Title + AppBar Icons
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 20 : 40,
                    vertical: 20,
                  ),
                  child: Row(
                    children: [
                      // Logo
                      Container(
                        width: isMobile ? 60 : 80,
                        height: isMobile ? 60 : 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/event_menu/logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => const Icon(
                              Icons.event,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      // Title in 2 lines
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.eventMenuLine1,
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w600,
                                fontSize: isMobile ? 20 : 28,
                                color: const Color(0xFFF1F1F6),
                              ),
                            ),
                            Text(
                              l10n.eventMenuLine2,
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w600,
                                fontSize: isMobile ? 20 : 28,
                                color: const Color(0xFFF1F1F6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // AppBar Icons (Notifications, Profile)
                      Row(
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(50),
                              onTap: () {
                                _closeProfile();
                                _scaffoldKey.currentState?.openEndDrawer();
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SvgPicture.asset(
                                  'assets/event_calendar/bell.svg',
                                  width: 28,
                                  height: 28,
                                  colorFilter: const ColorFilter.mode(
                                    Colors.white,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(50),
                              onTap: _toggleProfile,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SvgPicture.asset(
                                  'assets/event_calendar/user.svg',
                                  width: 28,
                                  height: 28,
                                  colorFilter: const ColorFilter.mode(
                                    Colors.white,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 2. Main Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 0 : 40,
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
                              // Duplicate list for endless effect
                              itemCount: _sponsors.length * 100,
                              itemBuilder: (context, index) {
                                final s = _sponsors[index % _sponsors.length];
                                final tier = s['tier'] as String? ?? 'general';
                                final tierColor = _getTierColor(tier);
                                final rawLogoUrl = s['logo'] as String?;
                                final website = s['website'] as String?;

                                // Build full logo URL
                                String? fullLogoUrl;
                                if (rawLogoUrl != null &&
                                    rawLogoUrl.isNotEmpty) {
                                  if (rawLogoUrl.startsWith('http')) {
                                    fullLogoUrl = rawLogoUrl;
                                  } else {
                                    fullLogoUrl =
                                        '${AppConfig.tourismApiBaseUrl}$rawLogoUrl';
                                  }
                                }

                                return GestureDetector(
                                  onTap: () async {
                                    if (website != null && website.isNotEmpty) {
                                      // Add http:// if missing
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
                                      color: const Color(0xFF262B60),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: tierColor.withValues(alpha: 0.5),
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        // Logo - takes most of the space
                                        Expanded(
                                          child: (fullLogoUrl != null)
                                              ? Image.network(
                                                  fullLogoUrl,
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (c, e, s) =>
                                                      Icon(
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
                                        const SizedBox(height: 4),
                                        // Tier label only
                                        Text(
                                          tier.toUpperCase(),
                                          style: GoogleFonts.roboto(
                                            color: tierColor,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                        else
                          const SizedBox(height: 100),

                        const SizedBox(height: 25),

                        // Grid (responsive: 2 columns mobile, 5 columns desktop)
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

                                  return Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        if (isExit) {
                                          _onExitEvent();
                                        } else if (item['route'] != null) {
                                          // Check if menu item requires agreement
                                          final requiresAgreement =
                                              item['requiresAgreement'] == true;
                                          final hasAgreed = context
                                              .read<AuthService>()
                                              .hasAgreedTerms;

                                          if (requiresAgreement && !hasAgreed) {
                                            // Show dialog to guide user to agreement
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
                                                      context.go('/profile');
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
                                          // Use go() instead of push() for proper URL update on web
                                          context.go(item['route'] as String);
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      splashColor: Colors.white24,
                                      highlightColor: Colors.white10,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: isExit
                                              ? Colors.orange.withValues(
                                                  alpha: 0.15,
                                                )
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: isExit
                                                ? Colors.orange.withValues(
                                                    alpha: 0.3,
                                                  )
                                                : Colors.white.withValues(
                                                    alpha: 0.1,
                                                  ),
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
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
                                            SizedBox(height: isMobile ? 4 : 8),
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
                ),
              ],
            ),

            // Profile Dropdown Overlay
            if (_isProfileOpen)
              Positioned(
                top: 100,
                right: isMobile ? 20 : 65,
                child: ProfileDropdown(onLogout: _onExitEvent),
              ),
          ],
        ),
      ),
    );
  }
}
