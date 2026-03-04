import 'package:flutter/material.dart';


/// Horizontal auto-scrolling sponsor logo carousel.
///
/// Displays a list of sponsor logos that scroll continuously from right to left.
/// Each logo is presented inside a white card with padding. The carousel loops
/// infinitely by duplicating the logo list internally.
///
/// ```dart
/// SponsorCarousel(
///   logoUrls: [
///     'https://example.com/logo1.png',
///     'https://example.com/logo2.png',
///   ],
///   height: 80,
/// )
/// ```
class SponsorCarousel extends StatefulWidget {
  /// Image URLs for sponsor logos.
  final List<String> logoUrls;

  /// Height of the carousel. Defaults to 80.
  final double height;

  const SponsorCarousel({
    super.key,
    required this.logoUrls,
    this.height = 80,
  });

  @override
  State<SponsorCarousel> createState() => _SponsorCarouselState();
}

class _SponsorCarouselState extends State<SponsorCarousel>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final AnimationController _animationController;

  /// Pixels scrolled per second.
  static const double _scrollSpeed = 40.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(
      vsync: this,
      // Duration is set once the layout is known; start with a placeholder.
      duration: const Duration(seconds: 1),
    );

    // Wait for the first frame so the scroll extent is available.
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoScroll());
  }

  void _startAutoScroll() {
    if (!mounted || widget.logoUrls.isEmpty) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) return;

    // Calculate duration based on remaining distance.
    final remainingDistance = maxScroll - _scrollController.offset;
    final durationSeconds = remainingDistance / _scrollSpeed;

    _animationController.duration =
        Duration(milliseconds: (durationSeconds * 1000).round());

    _animationController.addListener(_onTick);
    _animationController.addStatusListener(_onStatus);
    _animationController.forward();
  }

  void _onTick() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final offset = _animationController.value * maxScroll;
    _scrollController.jumpTo(offset);
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      // Jump back to the start and restart the animation for infinite looping.
      _scrollController.jumpTo(0);
      _animationController.reset();
      _startAutoScroll();
    }
  }

  @override
  void dispose() {
    _animationController.removeListener(_onTick);
    _animationController.removeStatusListener(_onStatus);
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.logoUrls.isEmpty) {
      return SizedBox(height: widget.height);
    }

    // Duplicate the list so the user sees a continuous stream of logos.
    final logos = [...widget.logoUrls, ...widget.logoUrls];

    return SizedBox(
      height: widget.height,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: logos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          return _LogoCard(
            imageUrl: logos[index],
            height: widget.height,
          );
        },
      ),
    );
  }
}

class _LogoCard extends StatelessWidget {
  final String imageUrl;
  final double height;

  const _LogoCard({required this.imageUrl, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Image.network(
        imageUrl,
        height: height - 24, // account for padding
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(
          Icons.image_not_supported_outlined,
          size: height * 0.4,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }
}
