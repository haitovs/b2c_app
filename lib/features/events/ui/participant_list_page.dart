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

class ParticipantListPage extends ConsumerStatefulWidget {
  final String eventId;

  const ParticipantListPage({super.key, required this.eventId});

  @override
  ConsumerState<ParticipantListPage> createState() =>
      _ParticipantListPageState();
}

class _ParticipantListPageState extends ConsumerState<ParticipantListPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isProfileOpen = false;

  List<Map<String, dynamic>> _participants = [];
  List<Map<String, dynamic>> _filteredParticipants = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  static const int _pageSize = 20;

  String _searchQuery = '';
  String _selectedFilter = 'all'; // all, expo, forum
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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
    _fetchParticipants();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreParticipants();
    }
  }

  Future<void> _fetchParticipants({bool loadMore = false}) async {
    if (loadMore) {
      if (_isLoadingMore || !_hasMore) return;
      setState(() => _isLoadingMore = true);
    } else {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _hasMore = true;
        _participants = [];
      });
    }

    try {
      // Use EventContextService for site_id
      final siteId = eventContextService.siteId;
      final page = loadMore ? _currentPage + 1 : 1;

      var uriString =
          '${AppConfig.tourismApiBaseUrl}/participants/?page=$page&limit=$_pageSize';
      if (siteId != null) {
        uriString += '&site_id=$siteId';
      }
      final uri = Uri.parse(uriString);

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        final newParticipants = data.cast<Map<String, dynamic>>();

        setState(() {
          if (loadMore) {
            _participants.addAll(newParticipants);
            _currentPage = page;
          } else {
            _participants = newParticipants;
          }

          // Check if there are more to load
          _hasMore = newParticipants.length >= _pageSize;

          _applyFilters();
          _isLoading = false;
          _isLoadingMore = false;
        });
      } else {
        debugPrint('Failed to fetch participants: ${response.statusCode}');
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching participants: $e');
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _loadMoreParticipants() {
    if (!_isLoadingMore && _hasMore && !_isLoading) {
      _fetchParticipants(loadMore: true);
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> result = _participants;

    // Apply role filter
    if (_selectedFilter != 'all') {
      result = result.where((p) {
        final role = p['role']?.toString().toLowerCase() ?? '';
        if (_selectedFilter == 'expo') {
          return role == 'expo' || role == 'both';
        } else if (_selectedFilter == 'forum') {
          return role == 'forum' || role == 'both';
        }
        return true;
      }).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      result = result.where((p) {
        final name = (p['name'] ?? '').toString().toLowerCase();
        return name.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    setState(() {
      _filteredParticipants = result;
    });
  }

  void _onSearchChanged(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _applyFilters();
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigate to add participant page
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Add participant functionality coming soon'),
            ),
          );
        },
        backgroundColor: Colors.white,
        icon: const Icon(Icons.add, color: Colors.black),
        label: Text(
          'Add participant',
          style: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: GestureDetector(
        onTap: _closeProfile,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: horizontalPadding,
                      right: horizontalPadding,
                      top: isMobile ? 12 : 20,
                    ),
                    child: _buildHeader(isMobile),
                  ),
                ),

                // Search Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: isMobile ? 8 : 16,
                    ),
                    child: _buildSearchBar(isMobile),
                  ),
                ),

                // Filter Chips
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: horizontalPadding,
                      right: horizontalPadding,
                      bottom: 16,
                    ),
                    child: _buildFilterChips(isMobile),
                  ),
                ),

                // Content Container with Grid
                SliverToBoxAdapter(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: _isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(60),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF3C4494),
                              ),
                            ),
                          )
                        : _filteredParticipants.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(60),
                            child: Center(
                              child: Text(
                                _searchQuery.isNotEmpty ||
                                        _selectedFilter != 'all'
                                    ? 'No participants found'
                                    : 'No participants available',
                                style: GoogleFonts.roboto(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          )
                        : _buildParticipantsGrid(isMobile),
                  ),
                ),

                // Loading More Indicator
                if (_isLoadingMore)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                  ),

                // Bottom spacing
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
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
    return Row(
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
          'Participants',
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
              onChanged: _onSearchChanged,
              style: GoogleFonts.roboto(
                fontSize: isMobile ? 16 : 20,
                color: const Color(0xFFF1F1F6),
              ),
              decoration: InputDecoration(
                hintText: 'Search by name',
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

  Widget _buildFilterChips(bool isMobile) {
    final filters = [
      {'key': 'all', 'label': 'All'},
      {'key': 'expo', 'label': 'Expo'},
      {'key': 'forum', 'label': 'Forum'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => _onFilterChanged(filter['key']!),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 24,
                  vertical: isMobile ? 8 : 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white
                      : const Color(0xFFF1F1F6).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  filter['label']!,
                  style: GoogleFonts.roboto(
                    fontSize: isMobile ? 14 : 18,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? const Color(0xFF3C4494)
                        : const Color(0xFFF1F1F6),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildParticipantsGrid(bool isMobile) {
    // Calculate columns based on screen width
    int crossAxisCount = isMobile ? 1 : 3;
    if (!isMobile && MediaQuery.of(context).size.width < 1200) {
      crossAxisCount = 2;
    }

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 30),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: isMobile ? 1.1 : 1.12,
          crossAxisSpacing: isMobile ? 16 : 30,
          mainAxisSpacing: isMobile ? 16 : 30,
        ),
        itemCount: _filteredParticipants.length,
        itemBuilder: (context, index) {
          final participant = _filteredParticipants[index];
          return _buildParticipantCard(participant, isMobile);
        },
      ),
    );
  }

  Widget _buildParticipantCard(
    Map<String, dynamic> participant,
    bool isMobile,
  ) {
    final name = participant['name'] ?? '';
    final logoUrl = _buildImageUrl(participant['logo']);

    return GestureDetector(
      onTap: () {
        // Navigate to participant detail
        context.push(
          '/events/${widget.eventId}/participants/${participant['id']}',
          extra: participant,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 8,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Logo/Image - takes ~68% of card
            Expanded(
              flex: 68,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.grey[200]),
                child: logoUrl.isNotEmpty
                    ? Image.network(
                        logoUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => Center(
                          child: Icon(
                            Icons.business,
                            size: isMobile ? 60 : 80,
                            color: Colors.grey[400],
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.business,
                          size: isMobile ? 60 : 80,
                          color: Colors.grey[400],
                        ),
                      ),
              ),
            ),

            // Name section - takes ~32% of card
            Expanded(
              flex: 32,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 24,
                  vertical: isMobile ? 12 : 16,
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name : 'Unknown Participant',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lato(
                      fontSize: isMobile ? 18 : 25,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E1E1E),
                      height: 1.2,
                    ),
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
