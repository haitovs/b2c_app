import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../core/widgets/animated_fade_in.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../company/providers/company_providers.dart';
import '../../shop/providers/shop_providers.dart';
import '../../team/providers/team_providers.dart';
import '../../visa/providers/visa_providers.dart';
import 'widgets/participation_progress.dart';
import 'widgets/sponsor_strip.dart';
import 'widgets/status_badge.dart';
import 'widgets/status_cards.dart';

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
      final routerState = GoRouterState.of(context);
      final eventIdStr = routerState.pathParameters['id'] ?? '0';
      final uri = Uri.parse(
          '${AppConfig.b2cApiBaseUrl}/api/v1/sponsors/?event_id=$eventIdStr');
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
                  SponsorStrip(
                    sponsors: _sponsors,
                    isLoading: _isLoadingSponsors,
                    scrollController: _sponsorScrollController,
                  ),
                  const SizedBox(height: 24),

                  // Progress bar
                  ParticipationProgress(
                    hasPurchased: ref.watch(hasPurchasedProvider(eventId)),
                    companies: ref.watch(myCompaniesProvider(eventId)),
                    teamMembers: ref.watch(allTeamMembersProvider(eventId)),
                    visas: ref.watch(visaListProvider(eventId)),
                  ),
                  const SizedBox(height: 16),

                  // Status badge: not purchased -> pending -> approved
                  DashboardStatusBadge(
                    hasPurchased: ref.watch(hasPurchasedProvider(eventId)),
                    orders: ref.watch(ordersProvider(eventId)),
                  ),
                  const SizedBox(height: 24),

                  // Status cards
                  DashboardStatusCards(
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
