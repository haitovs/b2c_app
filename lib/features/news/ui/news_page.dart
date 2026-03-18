import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/animated_fade_in.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/staggered_fade_in.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/news_providers.dart';
import '../services/news_service.dart';

/// News Page - displays news from B2C backend with search and infinite scroll
class NewsPage extends ConsumerStatefulWidget {
  final String eventId;

  const NewsPage({super.key, required this.eventId});

  @override
  ConsumerState<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends ConsumerState<NewsPage> {
  final ScrollController _scrollController = ScrollController();

  List<NewsItem> _news = [];
  List<NewsItem> _filteredNews = [];
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
      final newsService = ref.read(newsServiceProvider);
      final items = await newsService.fetchNews(skip: _skip, limit: _limit);
      if (!mounted) return;
      setState(() {
        _news = items;
        _filteredNews = _news;
        _isLoading = false;
        _hasMore = items.length >= _limit;
        _skip = _news.length;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching news: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppSnackBar.showError(context, 'Failed to load news');
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final newsService = ref.read(newsServiceProvider);
      final items = await newsService.fetchNews(skip: _skip, limit: _limit);
      if (!mounted) return;
      setState(() {
        _news.addAll(items);
        _filteredNews = _news;
        _hasMore = items.length >= _limit;
        _skip = _news.length;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading more news: $e');
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  void _filterNews(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredNews = _news;
      } else {
        _filteredNews = _news.where((news) {
          final header = news.header.toLowerCase();
          final description = news.description.toLowerCase();
          final category = (news.category ?? '').toLowerCase();
          return header.contains(query.toLowerCase()) ||
              description.contains(query.toLowerCase()) ||
              category.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'News',
            style: GoogleFonts.montserrat(
              fontSize: isMobile ? 18 : 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),

          // Search bar
          TextField(
            controller: _searchController,
            onChanged: _filterNews,
            style: GoogleFonts.inter(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search news...',
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
                borderSide:
                    const BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.primaryColor),
                  )
                : AnimatedFadeIn(child: _buildNewsGrid(isMobile, screenWidth)),
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
              style: GoogleFonts.inter(fontSize: 16, color: Colors.grey.shade500),
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

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
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
          return StaggeredFadeIn(
            index: index,
            child: _NewsCard(
              eventId: widget.eventId,
              news: _filteredNews[index],
              imageUrl: _filteredNews[index].imageUrl,
              formattedDate: _formatDate(_filteredNews[index].createdAt),
            ),
          );
        },
    );
  }
}

/// Modern compact news card with hover effects
class _NewsCard extends StatefulWidget {
  final String eventId;
  final NewsItem news;
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
    final header = widget.news.header.isNotEmpty ? widget.news.header : 'No Title';
    final description = widget.news.description;
    final category = widget.news.category ?? 'News';
    final newsId = widget.news.id.toString();

    return GestureDetector(
      onTap: () {
        // Navigate to news detail page
        context.push(
          '/events/${widget.eventId}/news/$newsId',
          extra: <String, dynamic>{
            'id': widget.news.id,
            'header': widget.news.header,
            'description': widget.news.description,
            'category': widget.news.category,
            'photo': widget.news.photo,
            'content': widget.news.content,
            'created_at': widget.news.createdAt.toIso8601String(),
          },
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
            ..setTranslationRaw(0.0, _isHovered ? -4.0 : 0.0, 0.0),
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
