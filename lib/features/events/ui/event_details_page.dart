import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/providers/event_context_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../providers/event_providers.dart';

// ── Design tokens from Figma ──
const _kBlue = Color(0xFF3C4494);
const _kLightBg = Color(0xFFF1F1F6);
const _kButtonColor = Color(0xFF9CA4CC);
const _kTextDark = Color(0xFF231C1C);
const _kTextBody = Color(0xD9474551); // rgba(71,69,81,0.85)

class EventDetailsPage extends ConsumerStatefulWidget {
  final String id;
  const EventDetailsPage({super.key, required this.id});

  @override
  ConsumerState<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends ConsumerState<EventDetailsPage> {
  Map<String, dynamic>? _event;
  bool _isLoading = true;
  final _descScrollCtrl = ScrollController();
  final _galleryScrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadEvent());
  }

  @override
  void dispose() {
    _descScrollCtrl.dispose();
    _galleryScrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadEvent() async {
    try {
      final eventId = int.tryParse(widget.id);
      if (eventId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final svc = ref.read(eventServiceProvider);
      final data = await svc.fetchEvent(eventId);
      if (!mounted) return;

      if (data != null) {
        // Store last-viewed event so post-login redirect can find it
        ref.read(eventContextProvider.notifier).setEventContext(
          eventId: eventId,
          tourismSiteId: data['tourism_site_id'] as int?,
        );

        setState(() {
          _event = {
            'id': data['id'],
            'name': data['title'] ?? 'Untitled Event',
            'description': data['description'] ?? '',
            'start_date': data['date_str'] ?? '',
            'location': data['location'] ?? '',
            'tourism_site_id': data['tourism_site_id'],
            'image_url': data['image_url'],
            'logo_url': data['logo_url'],
            'gallery_images':
                (data['gallery_images'] as List?)?.cast<String>() ?? <String>[],
          };
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading event: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onOpenTap() {
    final eventId = int.tryParse(widget.id);
    if (eventId != null && _event != null) {
      ref.read(eventContextProvider.notifier).setEventContext(
            eventId: eventId,
            tourismSiteId: _event!['tourism_site_id'] as int?,
          );
    }
    context.go('/events/${widget.id}/menu');
  }

  // ═══════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _kBlue,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_event == null) {
      return Scaffold(
        backgroundColor: _kLightBg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.event_busy, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.eventNotFound,
                style:
                    GoogleFonts.montserrat(fontSize: 20, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Events'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _kLightBg,
      body: LayoutBuilder(
        builder: (context, box) {
          final isDesktop = box.maxWidth >= 1100;
          final isMobile = box.maxWidth < 700;
          if (isMobile) return _mobileLayout(box);
          return _desktopLayout(box, isDesktop);
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // DESKTOP / TABLET  —  no page scroll, viewport-fixed layout
  // ═══════════════════════════════════════════════════════════════════

  Widget _desktopLayout(BoxConstraints box, bool isDesktop) {
    final hPad = isDesktop ? 50.0 : 30.0;
    final imageW = isDesktop ? 381.0 : 300.0;
    final blueH = box.maxHeight * 0.45;
    final imageUrl = _event!['image_url'] as String?;

    return Stack(
      children: [
        // Blue background — top portion
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: blueH,
          child: Container(color: _kBlue),
        ),
        // Content column
        Column(
          children: [
            SafeArea(bottom: false, child: _navBar(isDesktop)),
            SizedBox(height: isDesktop ? 20 : 10),
            _heroHeader(isDesktop, false),
            SizedBox(height: isDesktop ? 40 : 20),
            // Content fills remaining viewport
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 40),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // LEFT — description card (fills height, scrolls internally)
                    Expanded(child: _descriptionCard(isDesktop: true)),
                    SizedBox(width: isDesktop ? 30 : 20),
                    // RIGHT — image + open button (same total height)
                    SizedBox(
                      width: imageW,
                      child: Column(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: _coverImage(imageUrl),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _OpenButton(
                            width: imageW,
                            height: isDesktop ? 121 : 80,
                            fontSize: isDesktop ? 45 : 30,
                            onTap: _onOpenTap,
                            label: AppLocalizations.of(context)!.openButton,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // MOBILE  —  stacked layout, card scrolls internally
  // ═══════════════════════════════════════════════════════════════════

  Widget _mobileLayout(BoxConstraints box) {
    final imageUrl = _event!['image_url'] as String?;
    final blueH = box.maxHeight * 0.30;

    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: blueH,
          child: Container(color: _kBlue),
        ),
        Column(
          children: [
            SafeArea(bottom: false, child: _navBar(false)),
            const SizedBox(height: 10),
            _heroHeader(false, true),
            const SizedBox(height: 16),
            // Image (fixed height)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 200,
                  child: _coverImage(imageUrl),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Description card fills remaining space
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _descriptionCard(isDesktop: false),
              ),
            ),
            const SizedBox(height: 12),
            // Open button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: _OpenButton(
                width: double.infinity,
                height: 56,
                fontSize: 22,
                onTap: _onOpenTap,
                label: AppLocalizations.of(context)!.openButton,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Nav bar ──────────────────────────────────────────────────────

  Widget _navBar(bool isDesktop) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 40 : 20,
        vertical: isDesktop ? 10 : 6,
      ),
      child: SizedBox(
        height: isDesktop ? 80 : 56,
        child: Row(
          children: [
            Image.asset(
              'assets/logo.png',
              height: isDesktop ? 60 : 40,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Text(
                'B2C',
                style: GoogleFonts.montserrat(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () {},
              icon: Icon(Icons.notifications_outlined,
                  color: Colors.white, size: isDesktop ? 28 : 24),
            ),
            SizedBox(width: isDesktop ? 8 : 2),
            IconButton(
              onPressed: () => context.go('/profile'),
              icon: Icon(Icons.account_circle_outlined,
                  color: Colors.white, size: isDesktop ? 28 : 24),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Hero header (← back  [logo]  Event Name) ────────────────────

  Widget _heroHeader(bool isDesktop, bool isMobile) {
    final logoSize = isDesktop ? 80.0 : (isMobile ? 40.0 : 60.0);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 50 : 20),
      child: Row(
        children: [
          // Back arrow — plain icon, no border
          IconButton(
            onPressed: () => context.go('/'),
            icon: Icon(
              Icons.arrow_back,
              color: _kLightBg,
              size: isDesktop ? 36 : 24,
            ),
            tooltip: 'Back',
          ),
          SizedBox(width: isDesktop ? 20 : 10),
          _EventLogo(
            logoUrl: _event!['logo_url'] as String?,
            size: logoSize,
          ),
          SizedBox(width: isDesktop ? 30 : 15),
          Expanded(
            child: Text(
              _event!['name'] as String,
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w500,
                fontSize: isDesktop ? 36 : (isMobile ? 18 : 26),
                height: 1.3,
                color: _kLightBg,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Description card (white, internal scroll, gallery at end) ───

  Widget _descriptionCard({required bool isDesktop}) {
    final desc = _event!['description'] as String;
    final gallery = (_event!['gallery_images'] as List<String>?) ?? [];
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black.withValues(alpha: 0.12)),
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: ScrollbarTheme(
        data: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.all(_kButtonColor),
          trackColor: WidgetStateProperty.all(const Color(0xFFE8E8E8)),
          radius: const Radius.circular(100),
          thickness: WidgetStateProperty.all(isDesktop ? 11.0 : 6.0),
          trackBorderColor: WidgetStateProperty.all(Colors.transparent),
          trackVisibility: WidgetStateProperty.all(true),
          thumbVisibility: WidgetStateProperty.all(true),
        ),
        child: Scrollbar(
          controller: _descScrollCtrl,
          child: SingleChildScrollView(
            controller: _descScrollCtrl,
            padding: EdgeInsets.all(isDesktop ? 30 : 20)
                .copyWith(right: isDesktop ? 44 : 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Markdown or fallback content
                if (desc.trim().isNotEmpty)
                  MarkdownBody(
                    data: desc,
                    shrinkWrap: true,
                    softLineBreak: true,
                    styleSheet: _mdStyle(isDesktop),
                  )
                else
                  _fallbackDescription(isDesktop, l10n),
                // Gallery carousel — only if images exist
                if (gallery.isNotEmpty) ...[
                  SizedBox(height: isDesktop ? 30 : 20),
                  _galleryInCard(gallery, isDesktop),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fallbackDescription(bool isDesktop, AppLocalizations l10n) {
    final headingStyle = GoogleFonts.montserrat(
      fontSize: isDesktop ? 24 : 18,
      fontWeight: FontWeight.w600,
      color: _kTextDark,
    );
    final bodyStyle = GoogleFonts.roboto(
      fontSize: isDesktop ? 16 : 14,
      height: 1.6,
      color: _kTextBody,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.keyThemesTurkmenistanChina, style: headingStyle),
        SizedBox(height: isDesktop ? 16 : 12),
        Text(l10n.dearParticipants, style: bodyStyle),
        SizedBox(height: isDesktop ? 12 : 8),
        Text(l10n.participantInstructions, style: bodyStyle),
      ],
    );
  }

  MarkdownStyleSheet _mdStyle(bool isDesktop) {
    return MarkdownStyleSheet(
      h1: GoogleFonts.montserrat(
        fontSize: isDesktop ? 28 : 20,
        fontWeight: FontWeight.w600,
        color: _kTextDark,
      ),
      h2: GoogleFonts.montserrat(
        fontSize: isDesktop ? 24 : 18,
        fontWeight: FontWeight.w500,
        color: _kTextDark,
      ),
      h3: GoogleFonts.montserrat(
        fontSize: isDesktop ? 20 : 16,
        fontWeight: FontWeight.w500,
        color: _kTextDark,
      ),
      p: GoogleFonts.roboto(
        fontSize: isDesktop ? 16 : 14,
        height: 1.6,
        color: _kTextBody,
      ),
      listBullet: GoogleFonts.roboto(
        fontSize: isDesktop ? 16 : 14,
        color: _kTextBody,
      ),
      strong: GoogleFonts.roboto(
        fontSize: isDesktop ? 16 : 14,
        fontWeight: FontWeight.w600,
        color: _kTextDark,
      ),
      blockquoteDecoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: _kBlue.withValues(alpha: 0.5), width: 3),
        ),
      ),
      blockquotePadding: const EdgeInsets.only(left: 12),
    );
  }

  // ─── Gallery (inside the card) ────────────────────────────────────

  bool _showGalleryArrows = false;

  void _checkGalleryOverflow() {
    if (!_galleryScrollCtrl.hasClients) return;
    final needsScroll = _galleryScrollCtrl.position.maxScrollExtent > 0;
    if (needsScroll != _showGalleryArrows) {
      setState(() => _showGalleryArrows = needsScroll);
    }
  }

  Widget _galleryInCard(List<String> images, bool isDesktop) {
    final imgSize = isDesktop ? 160.0 : 110.0;
    final gap = isDesktop ? 16.0 : 10.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gallery',
          style: GoogleFonts.montserrat(
            fontSize: isDesktop ? 20 : 16,
            fontWeight: FontWeight.w600,
            color: _kTextDark,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (_showGalleryArrows) ...[
              _GalleryArrow(
                icon: Icons.chevron_left,
                size: isDesktop ? 32 : 24,
                onTap: () => _scrollGallery(-imgSize - gap),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: SizedBox(
                height: imgSize,
                child: NotificationListener<ScrollMetricsNotification>(
                  onNotification: (_) {
                    WidgetsBinding.instance
                        .addPostFrameCallback((_) => _checkGalleryOverflow());
                    return false;
                  },
                  child: ListView.separated(
                    controller: _galleryScrollCtrl,
                    scrollDirection: Axis.horizontal,
                    itemCount: images.length,
                    separatorBuilder: (_, __) => SizedBox(width: gap),
                    itemBuilder: (_, i) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          images[i],
                          width: imgSize,
                          height: imgSize,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: imgSize,
                            height: imgSize,
                            color: const Color(0xFFE0E0E0),
                            child: const Icon(Icons.broken_image,
                                color: Colors.grey),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            if (_showGalleryArrows) ...[
              const SizedBox(width: 8),
              _GalleryArrow(
                icon: Icons.chevron_right,
                size: isDesktop ? 32 : 24,
                onTap: () => _scrollGallery(imgSize + gap),
              ),
            ],
          ],
        ),
      ],
    );
  }

  void _scrollGallery(double delta) {
    if (!_galleryScrollCtrl.hasClients) return;
    final target = (_galleryScrollCtrl.offset + delta).clamp(
      0.0,
      _galleryScrollCtrl.position.maxScrollExtent,
    );
    _galleryScrollCtrl.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // ─── Cover image (fills available space) ──────────────────────────

  Widget _coverImage(String? imageUrl) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return SizedBox.expand(
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackCover(),
        ),
      );
    }
    return SizedBox.expand(child: _fallbackCover());
  }

  Widget _fallbackCover() {
    return Container(
      color: const Color(0xFF5A6199),
      child: const Icon(Icons.image, size: 80, color: Colors.white54),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// EXTRACTED WIDGETS
// ═════════════════════════════════════════════════════════════════════════

class _EventLogo extends StatelessWidget {
  final String? logoUrl;
  final double size;
  const _EventLogo({required this.logoUrl, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: logoUrl != null && logoUrl!.isNotEmpty
            ? Image.network(
                logoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.white,
      child: Icon(Icons.event, size: size * 0.4, color: _kBlue),
    );
  }
}

class _OpenButton extends StatelessWidget {
  final double width;
  final double height;
  final double fontSize;
  final VoidCallback onTap;
  final String label;

  const _OpenButton({
    required this.width,
    required this.height,
    required this.fontSize,
    required this.onTap,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: width == double.infinity ? null : width,
          height: height,
          decoration: BoxDecoration(
            color: _kButtonColor,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _GalleryArrow extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;

  const _GalleryArrow({
    required this.icon,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            border: Border.all(color: _kBlue, width: 2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: _kBlue, size: size * 0.6),
        ),
      ),
    );
  }
}

