import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart' as legacy_provider;

import '../../../core/config/app_config.dart';
import '../../../core/services/event_context_service.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../auth/services/auth_service.dart';
import '../../notifications/services/notification_service.dart';
import '../../notifications/ui/notification_drawer.dart';
import 'widgets/profile_dropdown.dart';

class SpeakerListPage extends ConsumerStatefulWidget {
  final String eventId;

  const SpeakerListPage({super.key, required this.eventId});

  @override
  ConsumerState<SpeakerListPage> createState() => _SpeakerListPageState();
}

class _SpeakerListPageState extends ConsumerState<SpeakerListPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isProfileOpen = false;

  List<Map<String, dynamic>> _speakers = [];
  List<Map<String, dynamic>> _filteredSpeakers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeAndFetch();
    _loadNotificationCount();
  }

  int _unreadNotificationCount = 0;

  Future<void> _loadNotificationCount() async {
    try {
      final authService = legacy_provider.Provider.of<AuthService>(
        context,
        listen: false,
      );
      final notificationService = NotificationService(authService);
      final notifications = await notificationService.getNotifications();
      if (mounted) {
        setState(() {
          _unreadNotificationCount = notifications
              .where((n) => !n.isRead)
              .length;
        });
      }
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> _initializeAndFetch() async {
    // Ensure the event context is loaded for this event
    final eventId = int.tryParse(widget.eventId);
    if (eventId != null) {
      await eventContextService.ensureEventContext(eventId);
    }
    _fetchSpeakers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchSpeakers() async {
    try {
      // Use EventContextService for site_id
      final siteId = eventContextService.siteId;
      final uri = siteId != null
          ? Uri.parse(
              '${AppConfig.tourismApiBaseUrl}/speakers/?site_id=$siteId',
            )
          : Uri.parse('${AppConfig.tourismApiBaseUrl}/speakers/');

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _speakers = data.cast<Map<String, dynamic>>();
          _filteredSpeakers = _speakers;
          _isLoading = false;
        });
      } else {
        debugPrint('Failed to fetch speakers: ${response.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching speakers: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterSpeakers(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredSpeakers = _speakers;
      } else {
        _filteredSpeakers = _speakers.where((speaker) {
          final name = '${speaker['name'] ?? ''} ${speaker['surname'] ?? ''}'
              .toLowerCase();
          final position = (speaker['position'] ?? '').toString().toLowerCase();
          final company = (speaker['company'] ?? '').toString().toLowerCase();
          return name.contains(query.toLowerCase()) ||
              position.contains(query.toLowerCase()) ||
              company.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _toggleProfile() {
    setState(() => _isProfileOpen = !_isProfileOpen);
  }

  void _closeProfile() {
    if (_isProfileOpen) setState(() => _isProfileOpen = false);
  }

  String _buildImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '${AppConfig.tourismApiBaseUrl}$path';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final horizontalPadding = isMobile ? 16.0 : 50.0;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF3C4494),
      endDrawer: const NotificationDrawer(),
      body: GestureDetector(
        onTap: _closeProfile,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: EdgeInsets.only(
                      left: horizontalPadding,
                      right: horizontalPadding,
                      top: isMobile ? 12 : 20,
                    ),
                    child: _buildHeader(isMobile),
                  ),

                  // Search Bar
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: isMobile ? 12 : 20,
                    ),
                    child: _buildSearchBar(isMobile),
                  ),

                  // Content Container
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F1F6),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF3C4494),
                              ),
                            )
                          : _filteredSpeakers.isEmpty
                          ? Center(
                              child: Text(
                                _searchQuery.isNotEmpty
                                    ? 'No speakers found for "$_searchQuery"'
                                    : 'No speakers available',
                                style: GoogleFonts.roboto(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            )
                          : _buildSpeakersGrid(isMobile),
                    ),
                  ),
                ],
              ),
            ),

            // Profile Dropdown
            if (_isProfileOpen)
              Positioned(
                top: isMobile ? 55 : 70,
                right: horizontalPadding,
                child: ProfileDropdown(
                  onClose: _closeProfile,
                  onLogout: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/');
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: isMobile ? 24 : 28,
            ),
            onPressed: () => context.go('/events/${widget.eventId}/menu'),
          ),
          const SizedBox(width: 8),
          // Title
          Text(
            'Speakers',
            style: GoogleFonts.montserrat(
              fontSize: isMobile ? 24 : 28,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          // Custom App Bar with notifications and profile
          CustomAppBar(
            onProfileTap: _toggleProfile,
            onNotificationTap: () {
              _closeProfile();
              _scaffoldKey.currentState?.openEndDrawer();
            },
            isMobile: isMobile,
            unreadNotificationCount: _unreadNotificationCount,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isMobile) {
    return Container(
      height: isMobile ? 50 : 64,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F6).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          SizedBox(width: isMobile ? 16 : 24),
          Icon(
            Icons.search,
            color: const Color(0xFFF1F1F6),
            size: isMobile ? 28 : 36,
          ),
          SizedBox(width: isMobile ? 12 : 20),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _filterSpeakers,
              style: GoogleFonts.roboto(
                fontSize: isMobile ? 16 : 20,
                color: const Color(0xFFF1F1F6),
              ),
              decoration: InputDecoration(
                hintText: 'Search speakers',
                hintStyle: GoogleFonts.roboto(
                  fontSize: isMobile ? 16 : 20,
                  color: const Color(0xFFF1F1F6),
                ),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeakersGrid(bool isMobile) {
    // Calculate columns based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 2; // Default mobile
    if (screenWidth >= 1200) {
      crossAxisCount = 5;
    } else if (screenWidth >= 900) {
      crossAxisCount = 4;
    } else if (screenWidth >= 600) {
      crossAxisCount = 3;
    }

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 30),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 0.72,
          crossAxisSpacing: isMobile ? 12 : 20,
          mainAxisSpacing: isMobile ? 12 : 20,
        ),
        itemCount: _filteredSpeakers.length,
        itemBuilder: (context, index) {
          final speaker = _filteredSpeakers[index];
          return _buildSpeakerCard(speaker, isMobile);
        },
      ),
    );
  }

  Widget _buildSpeakerCard(Map<String, dynamic> speaker, bool isMobile) {
    final name = '${speaker['name'] ?? ''} ${speaker['surname'] ?? ''}'.trim();
    final position = speaker['position'] ?? '';
    final photoUrl = _buildImageUrl(speaker['photo']);

    return GestureDetector(
      onTap: () {
        // Navigate to speaker detail
        context.push(
          '/events/${widget.eventId}/speakers/${speaker['id']}',
          extra: speaker,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Photo - takes ~75% of card
            Expanded(
              flex: 75,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                ),
                child: photoUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                        child: Image.network(
                          photoUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.person, size: 50, color: Colors.grey),
                      ),
              ),
            ),

            // Info section - takes ~25% of card
            Expanded(
              flex: 25,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 6 : 10,
                  vertical: isMobile ? 4 : 8,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        name.isNotEmpty ? name : 'Unknown Speaker',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.roboto(
                          fontSize: isMobile ? 14 : 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF151938),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Flexible(
                      child: Text(
                        position,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.roboto(
                          fontSize: isMobile ? 10 : 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
