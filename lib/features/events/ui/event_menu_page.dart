import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers/event_context_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../../shop/providers/shop_providers.dart';

// =============================================================================
// EventMenuPage — the event dashboard
// =============================================================================

class EventMenuPage extends ConsumerStatefulWidget {
  final int eventId;

  const EventMenuPage({super.key, required this.eventId});

  @override
  ConsumerState<EventMenuPage> createState() => _EventMenuPageState();
}

class _EventMenuPageState extends ConsumerState<EventMenuPage> {
  List<Map<String, dynamic>> _sponsors = [];
  bool _isLoadingSponsors = true;
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
    await ref
        .read(eventContextProvider.notifier)
        .ensureEventContext(widget.eventId);
    _fetchSponsors();
    _sponsorRefreshTimer = Timer.periodic(
      const Duration(minutes: 2),
      (_) => _fetchSponsors(),
    );
  }

  Future<void> _fetchSponsors() async {
    try {
      final siteId = ref.read(eventContextProvider).siteId;
      final uri = siteId != null
          ? Uri.parse('${AppConfig.tourismApiBaseUrl}/sponsors/?site_id=$siteId')
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
    } catch (_) {
      if (mounted) setState(() => _isLoadingSponsors = false);
    }
  }

  void _startAutoScroll() {
    if (_sponsors.isEmpty) return;
    _sponsorScrollTimer = Timer.periodic(
      const Duration(milliseconds: 30),
      (_) {
        if (!_sponsorScrollController.hasClients) return;
        final max = _sponsorScrollController.position.maxScrollExtent;
        final current = _sponsorScrollController.offset;
        _sponsorScrollController.jumpTo(current >= max ? 0 : current + 1);
      },
    );
  }

  @override
  void dispose() {
    _sponsorScrollTimer?.cancel();
    _sponsorRefreshTimer?.cancel();
    _sponsorScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final hasPurchased = ref.watch(hasPurchasedProvider(widget.eventId));

    return SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sponsor Carousel
            _SponsorCarousel(
              sponsors: _sponsors,
              isLoading: _isLoadingSponsors,
              scrollController: _sponsorScrollController,
            ),
            const SizedBox(height: 24),

            // Dashboard heading
            Text(
              'Dashboard',
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Quick access to event features',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),

            // Menu Grid
            _DashboardGrid(
              eventId: widget.eventId,
              hasPurchased: hasPurchased,
              isMobile: isMobile,
              l10n: l10n,
              onExitEvent: () {
                ref.read(eventContextProvider.notifier).clearContext();
                context.go('/');
              },
              onAgreementRequired: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Agreement Required'),
                    content: const Text(
                      'Please complete the Participation Agreement Process in your Profile before accessing this feature.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.go(
                            '/profile?tab=0&returnTo=/events/${widget.eventId}/menu',
                          );
                        },
                        child: const Text('Go to Profile'),
                      ),
                    ],
                  ),
                );
              },
              hasAgreedTerms: ref.read(authNotifierProvider).hasAgreedTerms,
            ),
          ],
        ),
      );
  }
}

// =============================================================================
// Sponsor Carousel
// =============================================================================

class _SponsorCarousel extends StatelessWidget {
  final List<Map<String, dynamic>> sponsors;
  final bool isLoading;
  final ScrollController scrollController;

  const _SponsorCarousel({
    required this.sponsors,
    required this.isLoading,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 90,
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

    if (sponsors.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 90,
      child: ListView.builder(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: sponsors.length * 100,
        itemBuilder: (context, index) {
          final s = sponsors[index % sponsors.length];
          return _SponsorCard(sponsor: s);
        },
      ),
    );
  }
}

class _SponsorCard extends StatelessWidget {
  final Map<String, dynamic> sponsor;

  const _SponsorCard({required this.sponsor});

  @override
  Widget build(BuildContext context) {
    final tier = sponsor['tier'] as String? ?? 'general';
    final rawLogoUrl = sponsor['logo'] as String?;
    final website = sponsor['website'] as String?;

    String? fullLogoUrl;
    if (rawLogoUrl != null && rawLogoUrl.isNotEmpty) {
      fullLogoUrl = rawLogoUrl.startsWith('http')
          ? rawLogoUrl
          : '${AppConfig.tourismApiBaseUrl}$rawLogoUrl';
    }

    final tierColor = _getTierColor(tier);

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        elevation: 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () async {
            if (website == null || website.isEmpty) return;
            var url = website;
            if (!url.startsWith('http://') && !url.startsWith('https://')) {
              url = 'https://$url';
            }
            try {
              await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            } catch (_) {}
          },
          child: Container(
            width: 150,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: fullLogoUrl != null
                      ? Image.network(
                          fullLogoUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.business,
                            color: tierColor,
                            size: 32,
                          ),
                        )
                      : Icon(Icons.business, color: tierColor, size: 32),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tier.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Color _getTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'premier':
      case 'diamond':
        return const Color(0xFF64B5F6);
      case 'platinum':
        return const Color(0xFFB0BEC5);
      case 'gold':
        return const Color(0xFFFFD54F);
      case 'silver':
        return const Color(0xFF90A4AE);
      case 'bronze':
        return const Color(0xFFBCAAA4);
      default:
        return AppTheme.primaryColor;
    }
  }
}

// =============================================================================
// Dashboard Grid
// =============================================================================

class _DashboardGrid extends StatelessWidget {
  final int eventId;
  final bool hasPurchased;
  final bool isMobile;
  final AppLocalizations l10n;
  final VoidCallback onExitEvent;
  final VoidCallback onAgreementRequired;
  final bool hasAgreedTerms;

  const _DashboardGrid({
    required this.eventId,
    required this.hasPurchased,
    required this.isMobile,
    required this.l10n,
    required this.onExitEvent,
    required this.onAgreementRequired,
    required this.hasAgreedTerms,
  });

  @override
  Widget build(BuildContext context) {
    final items = <_MenuItem>[
      _MenuItem(
        asset: 'registration.png',
        fallbackIcon: Icons.description_outlined,
        label: 'Visa Application',
        route: '/events/$eventId/visa-travel',
        color: const Color(0xFF5C6BC0),
      ),
      _MenuItem(
        asset: 'agenda.png',
        fallbackIcon: Icons.event_note_outlined,
        label: l10n.agenda,
        route: '/events/$eventId/agenda',
        color: const Color(0xFF42A5F5),
      ),
      _MenuItem(
        asset: 'speakers.png',
        fallbackIcon: Icons.record_voice_over_outlined,
        label: l10n.speakers,
        route: '/events/$eventId/speakers',
        color: const Color(0xFFAB47BC),
        requiresAgreement: true,
      ),
      _MenuItem(
        asset: 'participants.png',
        fallbackIcon: Icons.groups_outlined,
        label: l10n.participants,
        route: '/events/$eventId/participants',
        color: const Color(0xFF26A69A),
        requiresAgreement: true,
      ),
      _MenuItem(
        asset: 'meetings.png',
        fallbackIcon: Icons.handshake_outlined,
        label: l10n.meetings,
        route: '/events/$eventId/meetings',
        color: const Color(0xFFEF5350),
        requiresPurchase: true,
        requiresAgreement: true,
      ),
      _MenuItem(
        asset: 'flights.png',
        fallbackIcon: Icons.flight_outlined,
        label: l10n.flights,
        route: '/events/$eventId/flights',
        color: const Color(0xFF29B6F6),
        requiresPurchase: true,
        requiresAgreement: true,
      ),
      _MenuItem(
        asset: 'transfer.png',
        fallbackIcon: Icons.directions_car_outlined,
        label: l10n.transfer,
        route: '/events/$eventId/transfer',
        color: const Color(0xFF66BB6A),
        requiresPurchase: true,
        requiresAgreement: true,
      ),
      _MenuItem(
        asset: 'news.png',
        fallbackIcon: Icons.article_outlined,
        label: l10n.news,
        route: '/events/$eventId/news',
        color: const Color(0xFFFF7043),
      ),
      _MenuItem(
        asset: 'hotline.png',
        fallbackIcon: Icons.support_agent_outlined,
        label: l10n.hotline,
        route: '/events/$eventId/hotline',
        color: const Color(0xFF78909C),
      ),
      _MenuItem(
        asset: 'feedback.png',
        fallbackIcon: Icons.chat_bubble_outline,
        label: l10n.feedback,
        route: '/events/$eventId/feedback',
        color: const Color(0xFF7E57C2),
      ),
      _MenuItem(
        asset: 'faq.png',
        fallbackIcon: Icons.help_outline,
        label: l10n.faq,
        route: '/events/$eventId/faq',
        color: const Color(0xFF8D6E63),
      ),
      _MenuItem(
        fallbackIcon: Icons.exit_to_app,
        label: l10n.exitEvent,
        route: null,
        color: Colors.orange,
        isExit: true,
      ),
    ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isMobile ? 3 : 4,
            mainAxisSpacing: isMobile ? 12 : 16,
            crossAxisSpacing: isMobile ? 12 : 16,
            childAspectRatio: isMobile ? 0.95 : 1.05,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final isDisabled = item.requiresPurchase && !hasPurchased;

            return _DashboardCard(
              item: item,
              isDisabled: isDisabled,
              isMobile: isMobile,
              onTap: () => _handleTap(context, item, isDisabled),
            );
          },
        ),
      ),
    );
  }

  void _handleTap(BuildContext context, _MenuItem item, bool isDisabled) {
    if (isDisabled) {
      AppSnackBar.showInfo(context, 'Purchase a service package to unlock this feature');
      return;
    }

    if (item.isExit) {
      onExitEvent();
      return;
    }

    if (item.route == null) return;

    if (item.requiresAgreement && !hasAgreedTerms) {
      onAgreementRequired();
      return;
    }

    context.go(item.route!);
  }
}

// =============================================================================
// Dashboard Card — white card with icon, label, optional lock
// =============================================================================

class _DashboardCard extends StatelessWidget {
  final _MenuItem item;
  final bool isDisabled;
  final bool isMobile;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.item,
    required this.isDisabled,
    required this.isMobile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isExit = item.isExit;

    return Material(
      color: isExit ? Colors.orange.withValues(alpha: 0.08) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: isExit ? 0 : 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isExit
                  ? Colors.orange.withValues(alpha: 0.3)
                  : Colors.grey.shade200,
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Opacity(
                  opacity: isDisabled ? 0.4 : 1.0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: isMobile ? 48 : 56,
                          height: isMobile ? 48 : 56,
                          child: item.asset != null
                              ? Image.asset(
                                  'assets/event_menu/${item.asset}',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Container(
                                    decoration: BoxDecoration(
                                      color: item.color.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      item.fallbackIcon,
                                      size: isMobile ? 24 : 26,
                                      color: item.color,
                                    ),
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    color: item.color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    item.fallbackIcon,
                                    size: isMobile ? 24 : 26,
                                    color: item.color,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          item.label,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: isMobile ? 12 : 13,
                            fontWeight: FontWeight.w500,
                            color: isExit ? Colors.orange : Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (isDisabled)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.lock_outline,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// MenuItem data class
// =============================================================================

class _MenuItem {
  final String? asset;
  final IconData fallbackIcon;
  final String label;
  final String? route;
  final Color color;
  final bool requiresPurchase;
  final bool requiresAgreement;
  final bool isExit;

  const _MenuItem({
    this.asset,
    required this.fallbackIcon,
    required this.label,
    required this.route,
    required this.color,
    this.requiresPurchase = false,
    this.requiresAgreement = false,
    this.isExit = false,
  });
}
