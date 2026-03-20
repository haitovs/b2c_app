import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../analytics/providers/analytics_providers.dart';
import '../../auth/providers/auth_provider.dart';

/// Social platform icons — consistent with company preview page.
const _socialIcons = <String, IconData>{
  'facebook': Icons.facebook,
  'instagram': Icons.photo_camera,
  'linkedin': Icons.groups,
  'twitter': Icons.tag,
  'twitter / x': Icons.tag,
  'youtube': Icons.smart_display,
  'tiktok': Icons.music_video,
  'telegram': Icons.telegram,
  'whatsapp': Icons.chat_bubble,
  'wechat': Icons.forum,
  'website': Icons.language,
};

/// Company preview page for a participant — matches the CompanyPreviewPage
/// design. Rendered inside EventShellLayout (no Scaffold needed).
///
/// Layout:
/// - Company name + brand logo
/// - Divider
/// - About / bio text (first half)
/// - Gallery
/// - About / bio text (second half)
/// - Social media icons
/// - Contacts (phone)
/// - Email
class ParticipantDetailPage extends ConsumerStatefulWidget {
  final String eventId;
  final String participantId;
  final Map<String, dynamic>? participantData;

  const ParticipantDetailPage({
    super.key,
    required this.eventId,
    required this.participantId,
    this.participantData,
  });

  @override
  ConsumerState<ParticipantDetailPage> createState() =>
      _ParticipantDetailPageState();
}

class _ParticipantDetailPageState
    extends ConsumerState<ParticipantDetailPage> {
  Map<String, dynamic>? _participant;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _trackView();
    if (widget.participantData != null) {
      _participant = widget.participantData;
      _isLoading = false;
    } else {
      _fetchParticipant();
    }
  }

  void _trackView() {
    final eventId = int.tryParse(widget.eventId) ?? 0;
    if (eventId > 0) {
      ref.read(analyticsServiceProvider).recordView(
            targetType: 'COMPANY',
            targetId: widget.participantId,
            eventId: eventId,
          );
    }
  }

  Future<void> _fetchParticipant() async {
    try {
      final apiClient = ref.read(authApiClientProvider);
      final result = await apiClient.get<Map<String, dynamic>>(
        '/api/v1/companies/public/${widget.participantId}',
        auth: false,
      );
      if (!mounted) return;
      if (result.isSuccess && result.data != null) {
        setState(() {
          _participant = result.data;
          _isLoading = false;
        });
      } else {
        if (kDebugMode) debugPrint('Failed to fetch participant: ${result.error?.message}');
        setState(() => _isLoading = false);
        AppSnackBar.showError(context, 'Failed to load participant details');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching participant: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppSnackBar.showError(context, 'Failed to load participant details');
    }
  }

  String _imageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '${AppConfig.b2cApiBaseUrl}$path';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    if (_participant == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Participant not found',
              style: GoogleFonts.inter(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return _ParticipantPreview(
      participant: _participant!,
      imageUrl: _imageUrl,
    );
  }
}

// =============================================================================
// Preview Content — matches CompanyPreviewPage layout
// =============================================================================

class _ParticipantPreview extends StatelessWidget {
  final Map<String, dynamic> participant;
  final String Function(String?) imageUrl;

  const _ParticipantPreview({
    required this.participant,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final name = (participant['name'] ?? '').toString();
    final bio = (participant['bio'] ?? '').toString();
    final logoUrl = imageUrl(participant['logo']);

    // Gather gallery images
    final List<String> gallery = [];
    final imagesData = participant['images'];
    if (imagesData is List) {
      for (var img in imagesData) {
        if (img is Map) {
          final path = imageUrl(img['path']?.toString());
          if (path.isNotEmpty) gallery.add(path);
        }
      }
    }

    // Gather social links
    final socialLinks = participant['social_links'];
    final List<MapEntry<String, String>> activeSocials = [];
    if (socialLinks is Map) {
      for (final entry in socialLinks.entries) {
        final value = entry.value?.toString() ?? '';
        if (value.isNotEmpty) {
          activeSocials.add(MapEntry(entry.key.toString(), value));
        }
      }
    } else if (socialLinks is List) {
      for (var link in socialLinks) {
        if (link is Map) {
          final key = link['platform']?.toString() ?? '';
          final val = link['url']?.toString() ?? '';
          if (key.isNotEmpty && val.isNotEmpty) {
            activeSocials.add(MapEntry(key, val));
          }
        }
      }
    }

    final phone = (participant['phone'] ?? participant['mobile'] ?? '').toString();
    final email = (participant['email'] ?? '').toString();

    // Split bio around gallery
    final bioMidpoint =
        bio.length > 200 ? _findSplitPoint(bio) : bio.length;
    final bioFirst = bio.substring(0, bioMidpoint).trim();
    final bioSecond =
        bioMidpoint < bio.length ? bio.substring(bioMidpoint).trim() : '';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: name + logo
            _buildHeader(name, logoUrl),
            const SizedBox(height: 16),
            Divider(color: Colors.grey.shade300, height: 1),
            const SizedBox(height: 20),

            // About text — first part
            if (bioFirst.isNotEmpty) ...[
              Text(
                bioFirst,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  height: 1.6,
                  color: const Color(0xFF1E1E1E),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Gallery
            if (gallery.isNotEmpty) ...[
              _GalleryLayout(urls: gallery),
              const SizedBox(height: 24),
            ],

            // About text — second part
            if (bioSecond.isNotEmpty) ...[
              Text(
                bioSecond,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  height: 1.6,
                  color: const Color(0xFF1E1E1E),
                ),
              ),
              const SizedBox(height: 32),
            ],

            // Social Media
            if (activeSocials.isNotEmpty) ...[
              _buildSocialSection(activeSocials),
              const SizedBox(height: 20),
            ],

            // Contacts (phone)
            if (phone.isNotEmpty) ...[
              _buildContactRow('Contacts', phone, 'tel:$phone'),
              const SizedBox(height: 16),
            ],

            // Email
            if (email.isNotEmpty) ...[
              _buildContactRow('Email', email, 'mailto:$email'),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header — name left, logo right
  // ---------------------------------------------------------------------------

  Widget _buildHeader(String name, String logoUrl) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 500;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                name.isNotEmpty ? name : 'Unknown Company',
                style: GoogleFonts.montserrat(
                  fontSize: isMobile ? 20 : 30,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            if (logoUrl.isNotEmpty) ...[
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  logoUrl,
                  width: isMobile ? 100 : 190,
                  height: isMobile ? 44 : 80,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Social Media
  // ---------------------------------------------------------------------------

  Widget _buildSocialSection(List<MapEntry<String, String>> socials) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        Text(
          'Social Media',
          style: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        ...socials.map((entry) {
          final key = entry.key.toLowerCase();
          final url = entry.value;
          final icon = _socialIcons[key] ?? Icons.link;

          return InkWell(
            onTap: () => _launchUrl(url),
            borderRadius: BorderRadius.circular(22),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: Colors.white),
            ),
          );
        }),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Contacts / Email
  // ---------------------------------------------------------------------------

  Widget _buildContactRow(String label, String value, String uri) {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        InkWell(
          onTap: () => _launchUrl(uri),
          child: Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  int _findSplitPoint(String text) {
    final mid = text.length ~/ 2;
    final paragraphBreak = text.indexOf('\n', mid);
    if (paragraphBreak != -1 && paragraphBreak < mid + 200) {
      return paragraphBreak;
    }
    final sentenceEnd = text.indexOf('. ', mid);
    if (sentenceEnd != -1 && sentenceEnd < mid + 200) {
      return sentenceEnd + 2;
    }
    return mid;
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// =============================================================================
// Gallery Layout — 2x2 grid (matches company preview page)
// =============================================================================

class _GalleryLayout extends StatelessWidget {
  final List<String> urls;
  const _GalleryLayout({required this.urls});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final gap = 12.0;
        final cellWidth = (totalWidth - gap) / 2;
        final cellHeight = cellWidth * 0.6;

        return Column(
          children: [
            // Top row
            Row(
              children: [
                _galleryImage(urls[0], cellWidth, cellHeight),
                SizedBox(width: gap),
                if (urls.length > 1)
                  _galleryImage(urls[1], cellWidth, cellHeight),
              ],
            ),
            if (urls.length > 2) ...[
              SizedBox(height: gap),
              // Bottom row
              Row(
                children: [
                  _galleryImage(urls[2], cellWidth, cellHeight),
                  SizedBox(width: gap),
                  if (urls.length > 3)
                    _galleryImage(urls[3], cellWidth, cellHeight),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _galleryImage(String url, double width, double height) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: width,
        height: height,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.grey.shade200,
            child: const Icon(Icons.broken_image, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}
