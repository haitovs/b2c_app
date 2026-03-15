import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';

/// News Detail Page — displays a full news article inside the EventShellLayout.
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
      final uri = Uri.parse(
        '${AppConfig.b2cApiBaseUrl}/api/v1/content/news/${widget.newsId}',
      );

      final response = await http.get(uri);
      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() {
          _news = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  String _buildImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '${AppConfig.b2cApiBaseUrl}$path';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('d MMM yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    if (_news == null) {
      return _buildErrorState();
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back + Title row
          Row(
            children: [
              InkWell(
                onTap: () => context.pop(),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_back,
                    size: 20,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'News',
                  style: GoogleFonts.montserrat(
                    fontSize: isMobile ? 18 : 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Article content
          isMobile
              ? _buildMobileLayout()
              : _buildDesktopLayout(),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Failed to load news',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchNewsDetail();
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
            style: AppTheme.primaryButtonStyle,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Desktop layout — image left + excerpt right, then full description below
  // ---------------------------------------------------------------------------

  Widget _buildDesktopLayout() {
    final imageUrl = _buildImageUrl(_news!['photo']);
    final header = (_news!['header'] ?? 'No Title').toString();
    final description = (_news!['description'] ?? '').toString();
    final content = (_news!['content'] ?? '').toString();
    final category = (_news!['category'] ?? 'News').toString();
    final createdAt = _formatDate(_news!['created_at']?.toString());
    final bodyText = content.isNotEmpty ? content : description;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            header,
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryColor,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Divider(color: Colors.grey.shade200),
          const SizedBox(height: 16),

          // Row: image left + excerpt right
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 400,
                  height: 250,
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildImagePlaceholder(),
                        )
                      : _buildImagePlaceholder(),
                ),
              ),
              const SizedBox(width: 24),

              // Description excerpt on right side of image
              Expanded(
                child: Text(
                  description,
                  maxLines: 8,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey.shade700,
                    height: 1.7,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Category + date row
          _buildMeta(category, createdAt),
          const SizedBox(height: 20),

          // Full article content below — full width
          Text(
            bodyText,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Colors.grey.shade700,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Mobile layout — stacked
  // ---------------------------------------------------------------------------

  Widget _buildMobileLayout() {
    final imageUrl = _buildImageUrl(_news!['photo']);
    final header = (_news!['header'] ?? 'No Title').toString();
    final description = (_news!['description'] ?? '').toString();
    final content = (_news!['content'] ?? '').toString();
    final category = (_news!['category'] ?? 'News').toString();
    final createdAt = _formatDate(_news!['created_at']?.toString());
    final bodyText = content.isNotEmpty ? content : description;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                    )
                  : _buildImagePlaceholder(),
            ),
          ),

          // Content below image
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category + date
                _buildMeta(category, createdAt),
                const SizedBox(height: 12),

                // Title
                Text(
                  header,
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),

                // Body — show full content, fall back to description
                Text(
                  bodyText,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey.shade700,
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Shared widgets
  // ---------------------------------------------------------------------------

  Widget _buildMeta(String category, String date) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            category,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        if (date.isNotEmpty)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(
                date,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Icon(Icons.image_outlined, size: 48, color: Colors.grey.shade300),
      ),
    );
  }
}
