import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';

/// Participant list — grid of company cards. Tapping a card opens the
/// company preview / participant detail page.
class ParticipantListPage extends ConsumerStatefulWidget {
  final String eventId;
  const ParticipantListPage({super.key, required this.eventId});

  @override
  ConsumerState<ParticipantListPage> createState() =>
      _ParticipantListPageState();
}

class _ParticipantListPageState extends ConsumerState<ParticipantListPage> {
  List<Map<String, dynamic>> _participants = [];
  List<Map<String, dynamic>> _filteredParticipants = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  static const int _pageSize = 20;

  String _searchQuery = '';
  String _selectedFilter = 'all';
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  static const _filters = [
    {'key': 'all', 'label': 'All'},
    {'key': 'partners', 'label': 'Partners'},
    {'key': 'companies', 'label': 'Companies'},
    {'key': 'speakers', 'label': 'Speakers'},
    {'key': 'delegates', 'label': 'Delegates'},
    {'key': 'exhibitors', 'label': 'Exhibitors'},
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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
      _loadMore();
    }
  }

  // ---------------------------------------------------------------------------
  // Data
  // ---------------------------------------------------------------------------

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
      final page = loadMore ? _currentPage + 1 : 1;

      final uri =
          '${AppConfig.b2cApiBaseUrl}/api/v1/companies/public?event_id=${widget.eventId}&page=$page&limit=$_pageSize';

      final response = await http.get(Uri.parse(uri));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        final items = data.cast<Map<String, dynamic>>();
        setState(() {
          if (loadMore) {
            _participants.addAll(items);
            _currentPage = page;
          } else {
            _participants = items;
          }
          _hasMore = items.length >= _pageSize;
          _applyFilters();
          _isLoading = false;
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching participants: $e');
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _loadMore() {
    if (!_isLoadingMore && _hasMore && !_isLoading) {
      _fetchParticipants(loadMore: true);
    }
  }

  void _applyFilters() {
    var result = _participants;

    if (_selectedFilter != 'all') {
      result = result.where((p) {
        final role = (p['role'] ?? '').toString().toLowerCase();
        final type = (p['type'] ?? '').toString().toLowerCase();
        switch (_selectedFilter) {
          case 'partners':
            return role == 'partner' || type == 'partner';
          case 'companies':
            return role == 'company' || type == 'company';
          case 'speakers':
            return role == 'speaker' || type == 'speaker';
          case 'delegates':
            return role == 'delegate' || type == 'delegate';
          case 'exhibitors':
            return role == 'exhibitor' || type == 'exhibitor' ||
                role == 'expo' || role == 'both';
          default:
            return true;
        }
      }).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where((p) => (p['name'] ?? '').toString().toLowerCase().contains(q))
          .toList();
    }

    setState(() => _filteredParticipants = result);
  }

  String _imageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '${AppConfig.b2cApiBaseUrl}$path';
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Search + Filter row
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 16 : 20,
              12,
              isMobile ? 16 : 20,
              16,
            ),
            child: Column(
              children: [
                _buildSearchBar(isMobile),
                const SizedBox(height: 12),
                _buildFilterRow(isMobile),
              ],
            ),
          ),
        ),

        // Grid
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            isMobile ? 16 : 20, 4, isMobile ? 16 : 20, 24,
          ),
          sliver: _isLoading
              ? const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(60),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                )
              : _filteredParticipants.isEmpty
                  ? SliverToBoxAdapter(child: _buildEmpty())
                  : _buildGrid(isMobile, screenWidth),
        ),

        // Load more indicator
        if (_isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Search Bar
  // ---------------------------------------------------------------------------

  Widget _buildSearchBar(bool isMobile) {
    return TextField(
      controller: _searchController,
      onChanged: (q) {
        _searchQuery = q;
        _applyFilters();
      },
      style: GoogleFonts.inter(fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Search companies...',
        hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
        prefixIcon: const Icon(Icons.search, size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Filter Row — horizontal scrolling pills
  // ---------------------------------------------------------------------------

  Widget _buildFilterRow(bool isMobile) {
    return SizedBox(
      height: isMobile ? 36 : 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isActive = _selectedFilter == filter['key'];
          return GestureDetector(
            onTap: () {
              setState(() => _selectedFilter = filter['key']!);
              _applyFilters();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
              ),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.primaryColor
                    : AppTheme.primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                filter['label']!,
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 13 : 14,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : AppTheme.primaryColor,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Empty State
  // ---------------------------------------------------------------------------

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.business_outlined, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _selectedFilter != 'all'
                  ? 'No companies found'
                  : 'No companies available',
              style: GoogleFonts.inter(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Grid — company cards
  // ---------------------------------------------------------------------------

  SliverGrid _buildGrid(bool isMobile, double screenWidth) {
    int cols;
    if (isMobile) {
      cols = 2;
    } else if (screenWidth < 900) {
      cols = 3;
    } else if (screenWidth < 1200) {
      cols = 4;
    } else {
      cols = 5;
    }

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        childAspectRatio: 0.75,
        crossAxisSpacing: isMobile ? 12 : 16,
        mainAxisSpacing: isMobile ? 12 : 16,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => _CompanyCard(
          participant: _filteredParticipants[index],
          eventId: widget.eventId,
          imageUrl: _imageUrl,
        ),
        childCount: _filteredParticipants.length,
      ),
    );
  }
}

// =============================================================================
// Company Card — logo/image top, name + role badge bottom
// =============================================================================

class _CompanyCard extends StatelessWidget {
  final Map<String, dynamic> participant;
  final String eventId;
  final String Function(String?) imageUrl;

  const _CompanyCard({
    required this.participant,
    required this.eventId,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final name = (participant['name'] ?? '').toString();
    final logo = imageUrl(participant['logo']);
    final role = (participant['role'] ?? '').toString();

    return GestureDetector(
      onTap: () => context.push(
        '/events/$eventId/participants/${participant['id']}',
        extra: participant,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image — 65%
            Expanded(
              flex: 65,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  logo.isNotEmpty
                      ? Image.network(
                          logo,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(name),
                        )
                      : _placeholder(name),
                  // Role badge
                  if (role.isNotEmpty)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _roleLabel(role),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Info — 35%
            Expanded(
              flex: 35,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name.isNotEmpty ? name : 'Unknown',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF151938),
                        height: 1.3,
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

  Widget _placeholder(String name) {
    return Container(
      color: const Color(0xFFE8ECF5),
      child: Center(
        child: name.isNotEmpty
            ? Text(
                name[0].toUpperCase(),
                style: GoogleFonts.montserrat(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              )
            : Icon(Icons.business, size: 40, color: Colors.grey.shade400),
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role.toLowerCase()) {
      case 'expo':
        return 'Expo';
      case 'forum':
        return 'Forum';
      case 'both':
        return 'Expo & Forum';
      case 'partner':
        return 'Partner';
      case 'speaker':
        return 'Speaker';
      case 'delegate':
        return 'Delegate';
      case 'exhibitor':
        return 'Exhibitor';
      default:
        return role;
    }
  }
}
