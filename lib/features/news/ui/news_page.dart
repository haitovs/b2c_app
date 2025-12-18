import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart' as legacy_provider;

import '../../../core/config/app_config.dart';
import '../../../core/services/event_context_service.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../auth/services/auth_service.dart';
import '../../events/ui/widgets/profile_dropdown.dart';
import '../../notifications/services/notification_service.dart';
import '../../notifications/ui/notification_drawer.dart';

/// News Page - displays news from Tourism backend with search and infinite scroll
class NewsPage extends ConsumerStatefulWidget {
  final String eventId;

  const NewsPage({super.key, required this.eventId});

  @override
  ConsumerState<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends ConsumerState<NewsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  bool _isProfileOpen = false;

  List<Map<String, dynamic>> _news = [];
  List<Map<String, dynamic>> _filteredNews = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  final TextEditingController _searchController = TextEditingController();

  // Pagination
  int _skip = 0;
  final int _limit = 12;

  @override
  void initState() {
    super.initState();
    _fetchNews();
    _scrollController.addListener(_onScroll);
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

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore &&
        _searchController.text.isEmpty) {
      _loadMore();
    }
  }

  Future<void> _fetchNews() async {
    try {
      final siteId = eventContextService.siteId;
      final uri = siteId != null
          ? Uri.parse(
              '${AppConfig.tourismApiBaseUrl}/news/?site_id=$siteId&skip=$_skip&limit=$_limit',
            )
          : Uri.parse(
              '${AppConfig.tourismApiBaseUrl}/news/?skip=$_skip&limit=$_limit',
            );

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _news = data.cast<Map<String, dynamic>>();
          _filteredNews = _news;
          _isLoading = false;
          _hasMore = data.length >= _limit;
          _skip = _news.length;
        });
      } else {
        debugPrint('Failed to fetch news: ${response.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching news: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final siteId = eventContextService.siteId;
      final uri = siteId != null
          ? Uri.parse(
              '${AppConfig.tourismApiBaseUrl}/news/?site_id=$siteId&skip=$_skip&limit=$_limit',
            )
          : Uri.parse(
              '${AppConfig.tourismApiBaseUrl}/news/?skip=$_skip&limit=$_limit',
            );

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _news.addAll(data.cast<Map<String, dynamic>>());
          _filteredNews = _news;
          _hasMore = data.length >= _limit;
          _skip = _news.length;
          _isLoadingMore = false;
        });
      } else {
        setState(() => _isLoadingMore = false);
      }
    } catch (e) {
      debugPrint('Error loading more news: $e');
      setState(() => _isLoadingMore = false);
    }
  }

  void _filterNews(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredNews = _news;
      } else {
        _filteredNews = _news.where((news) {
          final header = (news['header'] ?? '').toString().toLowerCase();
          final description = (news['description'] ?? '')
              .toString()
              .toLowerCase();
          final category = (news['category'] ?? '').toString().toLowerCase();
          return header.contains(query.toLowerCase()) ||
              description.contains(query.toLowerCase()) ||
              category.contains(query.toLowerCase());
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

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
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
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _buildNewsGrid(isMobile, screenWidth),
                    ),
                  ),
                ],
              ),
            ),
            // Profile dropdown overlay
            if (_isProfileOpen)
              Positioned(
                top: isMobile ? 60 : 80,
                right: horizontalPadding,
                child: ProfileDropdown(onClose: _closeProfile),
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
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          onPressed: () => context.go('/events/${widget.eventId}/menu'),
        ),
        const SizedBox(width: 8),
        // Title
        Text(
          'News',
          style: GoogleFonts.montserrat(
            fontSize: isMobile ? 24 : 32,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFF1F1F6),
          ),
        ),
        const Spacer(),
        // Notification & Profile icons
        CustomAppBar(
          onNotificationTap: () {
            _scaffoldKey.currentState?.openEndDrawer();
          },
          onProfileTap: _toggleProfile,
          unreadNotificationCount: _unreadNotificationCount,
        ),
      ],
    );
  }

  Widget _buildSearchBar(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: isMobile ? 10 : 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: Colors.white.withValues(alpha: 0.8),
            size: isMobile ? 24 : 36,
          ),
          SizedBox(width: isMobile ? 12 : 20),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.roboto(
                color: Colors.white,
                fontSize: isMobile ? 14 : 16,
              ),
              decoration: InputDecoration(
                hintText: 'Search news...',
                hintStyle: GoogleFonts.roboto(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: isMobile ? 14 : 16,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: _filterNews,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsGrid(bool isMobile, double screenWidth) {
    if (_filteredNews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No news found',
              style: GoogleFonts.roboto(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // Responsive columns: 4 on large desktop, 3 on medium, 2 on tablet, 1 on mobile
    int crossAxisCount;
    double childAspectRatio;

    if (screenWidth > 1400) {
      crossAxisCount = 4;
      childAspectRatio = 0.85; // Compact cards for large screens
    } else if (screenWidth > 1000) {
      crossAxisCount = 3;
      childAspectRatio = 0.85;
    } else if (screenWidth > 600) {
      crossAxisCount = 2;
      childAspectRatio = 0.85;
    } else {
      crossAxisCount = 1;
      childAspectRatio = 1.0; // Wider cards on mobile
    }

    return Padding(
      padding: EdgeInsets.all(isMobile ? 12 : 24),
      child: GridView.builder(
        controller: _scrollController,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: isMobile ? 12 : 24,
          mainAxisSpacing: isMobile ? 12 : 24,
          childAspectRatio: childAspectRatio,
        ),
        itemCount: _filteredNews.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _filteredNews.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }
          return _NewsCard(
            eventId: widget.eventId,
            news: _filteredNews[index],
            imageUrl: _buildImageUrl(_filteredNews[index]['photo']),
            formattedDate: _formatDate(_filteredNews[index]['created_at']),
          );
        },
      ),
    );
  }
}

/// Modern compact news card with hover effects
class _NewsCard extends StatefulWidget {
  final String eventId;
  final Map<String, dynamic> news;
  final String imageUrl;
  final String formattedDate;

  const _NewsCard({
    required this.eventId,
    required this.news,
    required this.imageUrl,
    required this.formattedDate,
  });

  @override
  State<_NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends State<_NewsCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final header = widget.news['header'] ?? 'No Title';
    final description = widget.news['description'] ?? '';
    final category = widget.news['category'] ?? 'News';
    final newsId = widget.news['id']?.toString() ?? '';

    return GestureDetector(
      onTap: () {
        // Navigate to news detail page
        context.push(
          '/events/${widget.eventId}/news/$newsId',
          extra: widget.news,
        );
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          transform: Matrix4.identity()
            ..translate(0.0, _isHovered ? -4.0 : 0.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isHovered ? 0.15 : 0.08),
                blurRadius: _isHovered ? 20 : 12,
                offset: Offset(0, _isHovered ? 8 : 4),
              ),
            ],
          ),
          height: 1.4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image section - takes remaining space
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Image with zoom on hover
                      AnimatedScale(
                        scale: _isHovered ? 1.05 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: widget.imageUrl.isNotEmpty
                            ? Image.network(
                                widget.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildPlaceholder(),
                              )
                            : _buildPlaceholder(),
                      ),
                      // Gradient overlay
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 60,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.3),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Category badge
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF20306C),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            category,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Content section - takes only needed space
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Date
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.formattedDate,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Title
                      Text(
                        header,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1a1a2e),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Description - 3 lines max with ellipsis
                      Text(
                        description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFFF0F2F5),
      child: Center(
        child: Icon(Icons.article_outlined, size: 40, color: Colors.grey[400]),
      ),
    );
  }
}
