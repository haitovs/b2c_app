import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../analytics/providers/analytics_providers.dart';

/// Speaker detail / profile page — rendered inside EventShellLayout.
/// Matches Figma: breadcrumb top, photo left + info card right (desktop),
/// stacked on mobile. Single white container, no double background.
class SpeakerDetailPage extends ConsumerStatefulWidget {
  final String eventId;
  final String speakerId;
  final Map<String, dynamic>? speakerData;

  const SpeakerDetailPage({
    super.key,
    required this.eventId,
    required this.speakerId,
    this.speakerData,
  });

  @override
  ConsumerState<SpeakerDetailPage> createState() => _SpeakerDetailPageState();
}

class _SpeakerDetailPageState extends ConsumerState<SpeakerDetailPage> {
  Map<String, dynamic>? _speaker;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _trackView();
    if (widget.speakerData != null) {
      _speaker = widget.speakerData;
      _isLoading = false;
    } else {
      _fetchSpeaker();
    }
  }

  void _trackView() {
    final eventId = int.tryParse(widget.eventId) ?? 0;
    if (eventId > 0) {
      ref.read(analyticsServiceProvider).recordView(
            targetType: 'USER',
            targetId: widget.speakerId,
            eventId: eventId,
          );
    }
  }

  Future<void> _fetchSpeaker() async {
    try {
      final uri = Uri.parse(
        '${AppConfig.b2cApiBaseUrl}/api/v1/speakers/${widget.speakerId}',
      );
      final response = await http.get(uri);
      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() {
          _speaker = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching speaker: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  String _imageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '${AppConfig.b2cApiBaseUrl}$path';
  }

  Future<void> _launchUrl(String url) async {
    try {
      String finalUrl = url;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        finalUrl = 'https://$url';
      }
      final uri = Uri.parse(finalUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (kDebugMode) debugPrint('Could not launch $url: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    if (_speaker == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Speaker not found',
              style: GoogleFonts.inter(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return _buildPage();
  }

  Widget _buildPage() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final name = _speaker!['name'] ?? '';
    final surname = _speaker!['surname'] ?? '';
    final fullName = '$name $surname'.trim();
    final position = _speaker!['position'] ?? '';
    final company = _speaker!['company'] ?? '';
    final description = _speaker!['description'] ?? '';
    final phone = _speaker!['phone'] ?? '';
    final email = _speaker!['email'] ?? '';
    final photoUrl = _imageUrl(_speaker!['photo']);
    final companyPhotoUrl = _imageUrl(_speaker!['company_photo']);

    // Parse social links (supports both Map and List formats)
    final List<Map<String, String>> socialLinks = [];
    final socialLinksData = _speaker!['social_links'];
    if (socialLinksData is Map) {
      // New format: {"linkedin": "url", "twitter": "url"}
      for (final entry in socialLinksData.entries) {
        final url = entry.value?.toString() ?? '';
        if (url.isNotEmpty) {
          socialLinks.add({'platform': entry.key.toString(), 'url': url});
        }
      }
    } else if (socialLinksData is List) {
      // Legacy format: [{platform, url}, ...]
      for (var link in socialLinksData) {
        if (link is Map) {
          socialLinks.add({
            'platform': link['platform']?.toString() ?? '',
            'url': link['url']?.toString() ?? '',
          });
        }
      }
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb + Meeting request button
          _buildBreadcrumb(fullName, isMobile),

          SizedBox(height: isMobile ? 16 : 24),

          // Main content — white card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isMobile ? 16 : 30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: isMobile
                ? _buildMobileContent(
                    fullName, position, company, description,
                    phone, email, photoUrl, companyPhotoUrl, socialLinks,
                  )
                : _buildDesktopContent(
                    fullName, position, company, description,
                    phone, email, photoUrl, companyPhotoUrl, socialLinks,
                  ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Breadcrumb
  // ---------------------------------------------------------------------------

  Widget _buildBreadcrumb(String fullName, bool isMobile) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.go('/events/${widget.eventId}/speakers'),
          child: Text(
            'Speakers',
            style: GoogleFonts.montserrat(
              fontSize: isMobile ? 20 : 30,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(
            Icons.chevron_right,
            size: isMobile ? 20 : 24,
            color: const Color(0xFF616161),
          ),
        ),
        Expanded(
          child: Text(
            fullName.isNotEmpty ? fullName : 'Speaker',
            style: GoogleFonts.montserrat(
              fontSize: isMobile ? 10 : 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (!isMobile) ...[
          const SizedBox(width: 12),
          _buildMeetingButton(isMobile: false),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Desktop: photo left, info card right
  // ---------------------------------------------------------------------------

  Widget _buildDesktopContent(
    String fullName, String position, String company,
    String description, String phone, String email,
    String photoUrl, String companyPhotoUrl,
    List<Map<String, String>> socialLinks,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Photo
        _buildPhoto(photoUrl, width: 300, height: 351),
        const SizedBox(width: 40),
        // Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Personal Information',
                style: GoogleFonts.roboto(
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF151938).withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 16),

              // Name
              Text(
                fullName.isNotEmpty ? fullName : 'Unknown Speaker',
                style: GoogleFonts.roboto(
                  fontSize: 48,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF151938),
                ),
              ),
              const SizedBox(height: 20),

              // Company logo + position
              _buildCompanyRow(company, position, companyPhotoUrl),
              const SizedBox(height: 24),

              // Description
              if (description.isNotEmpty)
                Text(
                  description,
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    height: 1.6,
                    color: Colors.black,
                  ),
                ),

              if (description.isNotEmpty) const SizedBox(height: 32),

              // Social links
              if (socialLinks.isNotEmpty)
                _buildSocialLinks(socialLinks),

              if (socialLinks.isNotEmpty) const SizedBox(height: 16),

              // Contacts
              if (phone.isNotEmpty || email.isNotEmpty)
                _buildContacts(phone, email),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Mobile: stacked layout
  // ---------------------------------------------------------------------------

  Widget _buildMobileContent(
    String fullName, String position, String company,
    String description, String phone, String email,
    String photoUrl, String companyPhotoUrl,
    List<Map<String, String>> socialLinks,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Meeting button on mobile
        _buildMeetingButton(isMobile: true),
        const SizedBox(height: 16),

        // Photo + Name side by side
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPhoto(photoUrl, width: 120, height: 160),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName.isNotEmpty ? fullName : 'Unknown Speaker',
                    style: GoogleFonts.roboto(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF151938),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (companyPhotoUrl.isNotEmpty)
                    Image.network(
                      companyPhotoUrl,
                      height: 36,
                      fit: BoxFit.contain,
                      alignment: Alignment.centerLeft,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  const SizedBox(height: 8),
                  if (position.isNotEmpty || company.isNotEmpty)
                    Text(
                      [position, company]
                          .where((s) => s.isNotEmpty)
                          .join(', '),
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF151938),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Description
        if (description.isNotEmpty)
          Text(
            description,
            style: GoogleFonts.roboto(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.6,
              color: Colors.black,
            ),
          ),

        if (description.isNotEmpty) const SizedBox(height: 24),

        // Social links
        if (socialLinks.isNotEmpty) _buildSocialLinks(socialLinks),

        if (socialLinks.isNotEmpty) const SizedBox(height: 16),

        // Contacts
        if (phone.isNotEmpty || email.isNotEmpty)
          _buildContacts(phone, email),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Shared widgets
  // ---------------------------------------------------------------------------

  Widget _buildPhoto(String photoUrl, {required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: photoUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                photoUrl,
                fit: BoxFit.cover,
                width: width,
                height: height,
                errorBuilder: (_, __, ___) => Center(
                  child: Icon(Icons.person, size: width * 0.3, color: Colors.grey.shade400),
                ),
              ),
            )
          : Center(
              child: Icon(Icons.person, size: width * 0.3, color: Colors.grey.shade400),
            ),
    );
  }

  Widget _buildCompanyRow(String company, String position, String companyPhotoUrl) {
    final hasLogo = companyPhotoUrl.isNotEmpty;
    final hasText = position.isNotEmpty || company.isNotEmpty;
    if (!hasLogo && !hasText) return const SizedBox.shrink();

    return Row(
      children: [
        if (hasLogo) ...[
          SizedBox(
            width: 100,
            height: 66,
            child: Image.network(
              companyPhotoUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(width: 20),
        ],
        if (hasLogo || hasText)
          Container(
            width: 2,
            height: 60,
            margin: const EdgeInsets.only(right: 20),
            color: const Color(0xFF20306C),
          ),
        Expanded(
          child: Text(
            [position, company].where((s) => s.isNotEmpty).join(', '),
            style: GoogleFonts.roboto(
              fontSize: 20,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF151938),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMeetingButton({required bool isMobile}) {
    return SizedBox(
      width: isMobile ? double.infinity : null,
      child: ElevatedButton.icon(
        onPressed: () => context.push(
          '/events/${widget.eventId}/meetings/speaker/${widget.speakerId}',
          extra: _speaker,
        ),
        icon: const Icon(Icons.calendar_today, size: 16),
        label: const Text('Meeting request'),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: AppTheme.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 16,
            vertical: isMobile ? 12 : 12,
          ),
        ),
      ),
    );
  }

  Widget _buildSocialLinks(List<Map<String, String>> socialLinks) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        Text(
          'Follow me:',
          style: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        ...socialLinks.map((link) {
          final platform = link['platform']?.toLowerCase() ?? '';
          IconData icon;
          if (platform.contains('facebook')) {
            icon = Icons.facebook;
          } else if (platform.contains('instagram')) {
            icon = Icons.photo_camera;
          } else if (platform.contains('linkedin')) {
            icon = Icons.groups;
          } else if (platform.contains('twitter') || platform.contains('x')) {
            icon = Icons.tag;
          } else if (platform.contains('telegram')) {
            icon = Icons.telegram;
          } else if (platform.contains('youtube')) {
            icon = Icons.smart_display;
          } else {
            icon = Icons.link;
          }

          return InkWell(
            onTap: () => _launchUrl(link['url'] ?? ''),
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

  Widget _buildContacts(String phone, String email) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Contacts:',
          style: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        if (phone.isNotEmpty)
          InkWell(
            onTap: () => _launchUrl('tel:$phone'),
            child: Text(
              phone,
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
          ),
        if (phone.isNotEmpty && email.isNotEmpty)
          Text('|', style: GoogleFonts.roboto(fontSize: 16, color: Colors.grey)),
        if (email.isNotEmpty)
          InkWell(
            onTap: () => _launchUrl('mailto:$email'),
            child: Text(
              email,
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
}
