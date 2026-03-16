import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../../core/widgets/animated_fade_in.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers/event_context_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../company/providers/company_providers.dart';
import '../../shop/providers/shop_providers.dart';
import '../../team/providers/team_providers.dart';
import '../../visa/providers/visa_providers.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  // Sponsor data
  List<Map<String, dynamic>> _sponsors = [];
  bool _isLoadingSponsors = true;
  late ScrollController _sponsorScrollController;
  Timer? _sponsorScrollTimer;

  // Dashboard data
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _sponsorScrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  Future<void> _loadAll() async {
    final routerState = GoRouterState.of(context);
    final eventIdStr = routerState.pathParameters['id'] ?? '0';
    final eventId = int.tryParse(eventIdStr) ?? 0;
    if (eventId == 0) return;

    await Future.wait([
      _fetchSponsors(),
      _fetchDashboardData(eventId),
    ]);
  }

  Future<void> _fetchSponsors() async {
    try {
      final siteId = ref.read(eventContextProvider).siteId;
      final uri = siteId != null
          ? Uri.parse(
              '${AppConfig.tourismApiBaseUrl}/sponsors/?site_id=$siteId')
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

  Future<void> _fetchDashboardData(int eventId) async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoadingData = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingData = false);
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
    _sponsorScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final routerState = GoRouterState.of(context);
    final eventIdStr = routerState.pathParameters['id'] ?? '0';
    final eventId = int.tryParse(eventIdStr) ?? 0;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return _isLoadingData
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : AnimatedFadeIn(
              child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sponsor strip
                  _SponsorStrip(
                    sponsors: _sponsors,
                    isLoading: _isLoadingSponsors,
                    scrollController: _sponsorScrollController,
                  ),
                  const SizedBox(height: 24),

                  // Progress bar
                  _ParticipationProgress(
                    hasPurchased: ref.watch(hasPurchasedProvider(eventId)),
                    companies: ref.watch(myCompaniesProvider(eventId)),
                    teamMembers: ref.watch(allTeamMembersProvider(eventId)),
                    visas: ref.watch(visaListProvider(eventId)),
                  ),
                  const SizedBox(height: 16),

                  // Status badge: not purchased → pending → approved
                  _StatusBadge(
                    hasPurchased: ref.watch(hasPurchasedProvider(eventId)),
                    orders: ref.watch(ordersProvider(eventId)),
                  ),
                  const SizedBox(height: 24),

                  // Status cards
                  _StatusCards(
                    eventId: eventId,
                    isMobile: isMobile,
                    hasPurchased: ref.watch(hasPurchasedProvider(eventId)),
                    companies: ref.watch(myCompaniesProvider(eventId)),
                    teamMembers: ref.watch(allTeamMembersProvider(eventId)),
                    visas: ref.watch(visaListProvider(eventId)),
                    orders: ref.watch(ordersProvider(eventId)),
                  ),
                ],
              ),
            ),
          );
  }
}

// =============================================================================
// Sponsor Strip — primary-color background, auto-scrolling
// =============================================================================

class _SponsorStrip extends StatelessWidget {
  final List<Map<String, dynamic>> sponsors;
  final bool isLoading;
  final ScrollController scrollController;

  const _SponsorStrip({
    required this.sponsors,
    required this.isLoading,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (sponsors.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: sponsors.length * 100,
        padding: const EdgeInsets.symmetric(horizontal: 8),
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
      if (rawLogoUrl.startsWith('http')) {
        // Proxy external Tourism API images through B2C backend to avoid CORS
        final tourismBase = AppConfig.tourismApiBaseUrl;
        if (rawLogoUrl.startsWith(tourismBase)) {
          final relativePath = rawLogoUrl.substring(tourismBase.length);
          fullLogoUrl =
              '${AppConfig.b2cApiBaseUrl}/proxy/tourism${relativePath.startsWith('/') ? relativePath : '/$relativePath'}';
        } else {
          fullLogoUrl = rawLogoUrl;
        }
      } else {
        // Relative path — proxy through B2C backend
        fullLogoUrl =
            '${AppConfig.b2cApiBaseUrl}/proxy/tourism${rawLogoUrl.startsWith('/') ? rawLogoUrl : '/$rawLogoUrl'}';
      }
    }

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () async {
            if (website == null || website.isEmpty) return;
            var url = website;
            if (!url.startsWith('http://') && !url.startsWith('https://')) {
              url = 'https://$url';
            }
            try {
              await launchUrl(
                Uri.parse(url),
                mode: LaunchMode.externalApplication,
              );
            } catch (_) {}
          },
          child: Container(
            width: 130,
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: fullLogoUrl != null
                      ? Image.network(
                          fullLogoUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.business,
                            color: AppTheme.primaryColor,
                            size: 28,
                          ),
                        )
                      : const Icon(
                          Icons.business,
                          color: AppTheme.primaryColor,
                          size: 28,
                        ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
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
                      fontSize: 9,
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
}

// =============================================================================
// Status Badge
// =============================================================================

class _StatusBadge extends StatelessWidget {
  final bool hasPurchased;
  final AsyncValue<List<dynamic>> orders;

  const _StatusBadge({
    required this.hasPurchased,
    required this.orders,
  });

  @override
  Widget build(BuildContext context) {
    // Not purchased → Not Registered
    // Purchased + any order approved → Confirmed
    // Purchased + no approved orders → Pending
    final String label;
    final Color color;
    final IconData icon;

    if (!hasPurchased) {
      label = 'Not Registered';
      color = Colors.grey;
      icon = Icons.info_outline;
    } else {
      final hasApproved = orders.whenOrNull(
        data: (list) => list.any((o) => o.status.toUpperCase() == 'APPROVED'),
      ) ?? false;

      if (hasApproved) {
        label = 'Confirmed';
        color = AppTheme.successColor;
        icon = Icons.check_circle;
      } else {
        label = 'Pending';
        color = const Color(0xFFFF9800);
        icon = Icons.schedule;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            'Status: $label',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Participation Progress
// =============================================================================

class _ParticipationProgress extends StatelessWidget {
  final bool hasPurchased;
  final AsyncValue<List<dynamic>> companies;
  final AsyncValue<List<dynamic>> teamMembers;
  final AsyncValue<List<Map<String, dynamic>>> visas;

  const _ParticipationProgress({
    required this.hasPurchased,
    required this.companies,
    required this.teamMembers,
    required this.visas,
  });

  @override
  Widget build(BuildContext context) {
    final segments = _computeSegments();
    final totalPercent =
        segments.fold<int>(0, (sum, s) => sum + s.percent) ~/ segments.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Participation Progress',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$totalPercent%',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Segmented bar
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 12,
            child: Row(
              children: segments.map((s) {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 2),
                    color: s.percent == 100
                        ? AppTheme.successColor
                        : s.percent > 0
                            ? const Color(0xFFFF9800)
                            : Colors.grey.shade300,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Labels
        Wrap(
          spacing: 16,
          runSpacing: 4,
          children: segments.map((s) {
            final isDone = s.percent == 100;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 14,
                  color: isDone ? AppTheme.successColor : Colors.grey.shade400,
                ),
                const SizedBox(width: 4),
                Text(
                  '${s.label} ${s.percent}%',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDone ? AppTheme.successColor : Colors.grey.shade600,
                    fontWeight: isDone ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  List<_Segment> _computeSegments() {
    // Payment (purchasing a service = registration)
    final payPercent = hasPurchased ? 100 : 0;

    // Company info: 100% if company with name exists
    final compPercent = companies.whenOrNull(
          data: (list) => list.isNotEmpty ? 100 : 0,
        ) ??
        0;

    // Team members: 100% if any members exist
    final teamPercent = teamMembers.whenOrNull(
          data: (list) => list.isNotEmpty ? 100 : 0,
        ) ??
        0;

    // Visa: 100% if any visa confirmed/approved
    final visaPercent = visas.whenOrNull(
          data: (list) => list.any((v) {
            final s = (v['status'] ?? '').toString().toUpperCase();
            return s == 'CONFIRMED' || s == 'APPROVED';
          })
              ? 100
              : 0,
        ) ??
        0;

    return [
      _Segment('Order', payPercent),
      _Segment('Company', compPercent),
      _Segment('Team', teamPercent),
      _Segment('Visa', visaPercent),
    ];
  }
}

class _Segment {
  final String label;
  final int percent;

  const _Segment(this.label, this.percent);
}

// =============================================================================
// Status Cards
// =============================================================================

class _StatusCards extends StatelessWidget {
  final int eventId;
  final bool isMobile;
  final bool hasPurchased;
  final AsyncValue<List<dynamic>> companies;
  final AsyncValue<List<dynamic>> teamMembers;
  final AsyncValue<List<Map<String, dynamic>>> visas;
  final AsyncValue<List<dynamic>> orders;

  const _StatusCards({
    required this.eventId,
    required this.isMobile,
    required this.hasPurchased,
    required this.companies,
    required this.teamMembers,
    required this.visas,
    required this.orders,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _CompanyCard(eventId: eventId, isMobile: isMobile, hasPurchased: hasPurchased, companies: companies)),
            const SizedBox(width: 16),
            Expanded(child: _TeamCard(eventId: eventId, isMobile: isMobile, hasPurchased: hasPurchased, teamMembers: teamMembers)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _VisaCard(eventId: eventId, isMobile: isMobile, hasPurchased: hasPurchased, visas: visas)),
            const SizedBox(width: 16),
            Expanded(child: _OrdersCard(eventId: eventId, isMobile: isMobile, orders: orders)),
          ],
        ),
      ],
    );
  }
}

// --- My Company Card ---

class _CompanyCard extends StatelessWidget {
  final int eventId;
  final bool isMobile;
  final bool hasPurchased;
  final AsyncValue<List<dynamic>> companies;

  const _CompanyCard({
    required this.eventId,
    required this.isMobile,
    required this.hasPurchased,
    required this.companies,
  });

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: companies.when(
        loading: () => const _CardLoading(),
        error: (_, __) => const _CardError(message: 'Failed to load'),
        data: (list) {
          final company = list.isNotEmpty ? list.first : null;
          final logoUrl = company?.brandIconUrl;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: logoUrl != null
                        ? Image.network(
                            logoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.business_outlined,
                              color: Colors.grey.shade400,
                              size: 20,
                            ),
                          )
                        : Icon(
                            Icons.business_outlined,
                            color: Colors.grey.shade400,
                            size: 20,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'My Company',
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                company?.name ?? 'Not set up yet',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (!hasPurchased) {
                      AppSnackBar.showInfo(context, 'Purchase a service package to unlock this feature');
                      return;
                    }
                    context.go('/events/$eventId/company-profile');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasPurchased ? AppTheme.successColor : Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Edit',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// --- Team Members Card ---

class _TeamCard extends StatelessWidget {
  final int eventId;
  final bool isMobile;
  final bool hasPurchased;
  final AsyncValue<List<dynamic>> teamMembers;

  const _TeamCard({
    required this.eventId,
    required this.isMobile,
    required this.hasPurchased,
    required this.teamMembers,
  });

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: teamMembers.when(
        loading: () => const _CardLoading(),
        error: (_, __) => const _CardError(message: 'Failed to load'),
        data: (members) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF42A5F5).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.groups_outlined,
                      color: Color(0xFF42A5F5), size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  'Team Members',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${members.length} Member${members.length == 1 ? '' : 's'}',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (!hasPurchased) {
                    AppSnackBar.showInfo(context, 'Purchase a service package to unlock this feature');
                    return;
                  }
                  context.go('/events/$eventId/team');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasPurchased ? AppTheme.successColor : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Manage',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Visa Status Card ---

class _VisaCard extends StatelessWidget {
  final int eventId;
  final bool isMobile;
  final bool hasPurchased;
  final AsyncValue<List<Map<String, dynamic>>> visas;

  const _VisaCard({
    required this.eventId,
    required this.isMobile,
    required this.hasPurchased,
    required this.visas,
  });

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: visas.when(
        loading: () => const _CardLoading(),
        error: (_, __) => const _CardError(message: 'Failed to load'),
        data: (list) {
          final counts = _countStatuses(list);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5C6BC0).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.description_outlined,
                        color: Color(0xFF5C6BC0), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Visa Status',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 2x2 status grid
              Row(
                children: [
                  _VisaStatusChip(
                      label: 'Pending', count: counts['pending']!),
                  const SizedBox(width: 12),
                  _VisaStatusChip(
                      label: 'Fill out', count: counts['fill_out']!),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _VisaStatusChip(
                      label: 'Confirmed', count: counts['confirmed']!),
                  const SizedBox(width: 12),
                  _VisaStatusChip(
                      label: 'Declined', count: counts['declined']!),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    if (!hasPurchased) {
                      AppSnackBar.showInfo(context, 'Purchase a service package to unlock this feature');
                      return;
                    }
                    context.go('/events/$eventId/visa-travel');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: hasPurchased ? AppTheme.primaryColor : Colors.grey,
                    side: BorderSide(color: hasPurchased ? AppTheme.primaryColor : Colors.grey),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'View',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Map<String, int> _countStatuses(List<Map<String, dynamic>> list) {
    int pending = 0, fillOut = 0, confirmed = 0, declined = 0;
    for (final v in list) {
      final s = (v['status'] ?? '').toString().toUpperCase();
      switch (s) {
        case 'PENDING':
        case 'SUBMITTED':
          pending++;
          break;
        case 'FILL_OUT':
        case 'DRAFT':
        case '':
          fillOut++;
          break;
        case 'CONFIRMED':
        case 'APPROVED':
          confirmed++;
          break;
        case 'DECLINED':
        case 'REJECTED':
          declined++;
          break;
      }
    }
    return {
      'pending': pending,
      'fill_out': fillOut,
      'confirmed': confirmed,
      'declined': declined,
    };
  }
}

class _VisaStatusChip extends StatelessWidget {
  final String label;
  final int count;

  const _VisaStatusChip({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Text(
              '$count',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Services & Orders Card ---

class _OrdersCard extends StatelessWidget {
  final int eventId;
  final bool isMobile;
  final AsyncValue<List<dynamic>> orders;

  const _OrdersCard({
    required this.eventId,
    required this.isMobile,
    required this.orders,
  });

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: orders.when(
        loading: () => const _CardLoading(),
        error: (_, __) => const _CardError(message: 'Failed to load'),
        data: (list) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF66BB6A).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.shopping_bag_outlined,
                        color: Color(0xFF66BB6A), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Services & Orders',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${list.length} Service${list.length == 1 ? '' : 's'} Purchased',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.go('/events/$eventId/services'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: const BorderSide(color: AppTheme.primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'View',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// =============================================================================
// Shared card helpers
// =============================================================================

class _CardShell extends StatelessWidget {
  final Widget child;

  const _CardShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Container(
      height: isMobile ? 180 : 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CardLoading extends StatelessWidget {
  const _CardLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }
}

class _CardError extends StatelessWidget {
  final String message;

  const _CardError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500),
      ),
    );
  }
}
