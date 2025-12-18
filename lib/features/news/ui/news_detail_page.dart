import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../../core/config/app_config.dart';
import '../../../core/services/event_context_service.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../events/ui/widgets/profile_dropdown.dart';
import '../../notifications/ui/notification_drawer.dart';

/// News Detail Page - displays full news article with gallery
class NewsDetailPage extends ConsumerStatefulWidget {
  final String eventId;
  final String newsId;
  final Map<String, dynamic>? newsData;

  const NewsDetailPage({
    super.key,
    required this.eventId,
    required this.newsId,
    this.newsData,
  });

  @override
  ConsumerState<NewsDetailPage> createState() => _NewsDetailPageState();
}

class _NewsDetailPageState extends ConsumerState<NewsDetailPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isProfileOpen = false;
  bool _isLoading = true;
  Map<String, dynamic>? _news;

  @override
  void initState() {
    super.initState();
    if (widget.newsData != null) {
      _news = widget.newsData;
      _isLoading = false;
    } else {
      _fetchNewsDetail();
    }
  }

  Future<void> _fetchNewsDetail() async {
    try {
      final siteId = eventContextService.siteId;
      final uri = siteId != null
          ? Uri.parse(
              '${AppConfig.tourismApiBaseUrl}/news/${widget.newsId}?site_id=$siteId',
            )
          : Uri.parse('${AppConfig.tourismApiBaseUrl}/news/${widget.newsId}');

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        setState(() {
          _news = jsonDecode(response.body);
          _isLoading = false;
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
      return DateFormat('d MMM yy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;
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
                  const SizedBox(height: 20),

                  // Content Container
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(10),
                        ),
                      ),
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _news == null
                          ? _buildErrorState()
                          : _buildContent(isMobile),
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
          onPressed: () => context.pop(),
        ),
        const SizedBox(width: 8),
        // Title - smaller
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
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Failed to load news',
            style: GoogleFonts.roboto(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchNewsDetail();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 20 : 50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb
          _buildBreadcrumb(),
          const SizedBox(height: 16),
          // Divider
          Container(
            height: 2,
            color: const Color(0xFF20306C).withValues(alpha: 0.8),
          ),
          const SizedBox(height: 30),
          // Main content - two column on desktop
          isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
        ],
      ),
    );
  }

  Widget _buildBreadcrumb() {
    return Row(
      children: [
        Text(
          'News',
          style: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B6B6B),
          ),
        ),
        const SizedBox(width: 8),
        Icon(Icons.chevron_right, size: 20, color: const Color(0xFF6B6B6B)),
        const SizedBox(width: 8),
        Text(
          'Details',
          style: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B6B6B),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    final imageUrl = _buildImageUrl(_news!['photo']);
    final header = (_news!['header'] ?? 'No Title').toString();
    final description = (_news!['description'] ?? '').toString();
    final category = (_news!['category'] ?? 'News').toString();
    final createdAt = _formatDate(_news!['created_at']?.toString());

    // Split description into paragraphs
    final paragraphs = description
        .split('\n')
        .where((p) => p.trim().isNotEmpty)
        .toList();
    final leftParagraphs = paragraphs
        .take((paragraphs.length / 2).ceil())
        .toList();
    final rightParagraphs = paragraphs
        .skip((paragraphs.length / 2).ceil())
        .toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column - image, title, partial description
        Expanded(
          flex: 45,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main image
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildImagePlaceholder(),
                        )
                      : _buildImagePlaceholder(),
                ),
              ),
              const SizedBox(height: 16),
              // Category badge and date row
              Row(
                children: [
                  // Category badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF20306C),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      category,
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFF1F1F6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Date
                  Icon(
                    Icons.access_time,
                    size: 20,
                    color: const Color(0xFF20306C),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    createdAt,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF76777F).withValues(alpha: 0.47),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Title
              Text(
                header,
                style: GoogleFonts.montserrat(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF13152E),
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 20),
              // Left paragraphs
              ...leftParagraphs.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    p,
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: Colors.black.withValues(alpha: 0.7),
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 50),
        // Right column - continuation of article
        Expanded(
          flex: 55,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // If not enough paragraphs, show full description
              if (rightParagraphs.isEmpty)
                Text(
                  description,
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: Colors.black.withValues(alpha: 0.7),
                    height: 1.5,
                  ),
                )
              else
                ...rightParagraphs.map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      p,
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: Colors.black.withValues(alpha: 0.7),
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    final imageUrl = _buildImageUrl(_news!['photo']);
    final header = (_news!['header'] ?? 'No Title').toString();
    final description = (_news!['description'] ?? '').toString();
    final category = (_news!['category'] ?? 'News').toString();
    final createdAt = _formatDate(_news!['created_at']?.toString());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main image
        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildImagePlaceholder(),
                  )
                : _buildImagePlaceholder(),
          ),
        ),
        const SizedBox(height: 16),
        // Category badge and date row
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Category badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF20306C),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                category,
                style: GoogleFonts.roboto(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFF1F1F6),
                ),
              ),
            ),
            // Date
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time,
                  size: 18,
                  color: const Color(0xFF20306C),
                ),
                const SizedBox(width: 4),
                Text(
                  createdAt,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF76777F).withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Title
        Text(
          header,
          style: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF13152E),
            height: 1.25,
          ),
        ),
        const SizedBox(height: 16),
        // Description
        Text(
          description,
          style: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.black.withValues(alpha: 0.7),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: const Color(0xFFF0F2F5),
      child: Center(
        child: Icon(Icons.image_outlined, size: 48, color: Colors.grey[400]),
      ),
    );
  }
}
