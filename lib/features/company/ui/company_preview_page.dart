import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../models/company.dart';
import '../providers/company_providers.dart';

/// Social platform icons — recognizable Material icons for each platform.
final _socialIcons = <String, IconData>{
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

/// Read-only public view of a company profile — matches Figma design.
///
/// Layout:
/// - Company name (left) + brand logo (right)
/// - Divider
/// - About text (first half)
/// - Gallery (1 tall left + 2 small right top + 1 wide right bottom)
/// - About text (second half)
/// - "Participants list from this company" — horizontal card carousel
/// - "Social Media" — icon circles
/// - "Contacts" — phone
/// - "Email" — email
class CompanyPreviewPage extends ConsumerWidget {
  final String companyId;

  const CompanyPreviewPage({super.key, required this.companyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companyAsync = ref.watch(companyDetailProvider(companyId));

    return companyAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('Failed to load company',
                style: GoogleFonts.inter(color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () =>
                  ref.invalidate(companyDetailProvider(companyId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (company) => _PreviewContent(company: company),
    );
  }
}

class _PreviewContent extends StatelessWidget {
  final Company company;
  const _PreviewContent({required this.company});

  @override
  Widget build(BuildContext context) {
    final about = company.about ?? '';
    final gallery = company.galleryUrls ?? [];
    final members = company.teamMembers ?? [];
    final socialLinks = company.socialLinks ?? {};
    final activeSocials = socialLinks.entries
        .where((e) => e.value != null && e.value.toString().isNotEmpty)
        .toList();

    // Split about text into two halves (gallery goes in between)
    final aboutMidpoint = about.length > 200 ? _findSplitPoint(about) : about.length;
    final aboutFirst = about.substring(0, aboutMidpoint).trim();
    final aboutSecond =
        aboutMidpoint < about.length ? about.substring(aboutMidpoint).trim() : '';

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
            // Header: company name + brand logo
            _buildHeader(),
            const SizedBox(height: 16),
            Divider(color: Colors.grey.shade300, height: 1),
            const SizedBox(height: 20),

            // About text — first part
            if (aboutFirst.isNotEmpty) ...[
              Text(
                aboutFirst,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  height: 1.6,
                  color: const Color(0xFF1E1E1E),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Gallery — Figma layout
            if (gallery.isNotEmpty) ...[
              _GalleryLayout(urls: gallery),
              const SizedBox(height: 24),
            ],

            // About text — second part
            if (aboutSecond.isNotEmpty) ...[
              Text(
                aboutSecond,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  height: 1.6,
                  color: const Color(0xFF1E1E1E),
                ),
              ),
              const SizedBox(height: 32),
            ],

            // Participants list
            if (members.isNotEmpty) ...[
              Text(
                'Participants list from this company',
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF151938),
                ),
              ),
              const SizedBox(height: 16),
              _MemberCarousel(members: members),
              const SizedBox(height: 32),
            ],

            // Social Media
            if (activeSocials.isNotEmpty) ...[
              _buildSocialSection(activeSocials),
              const SizedBox(height: 20),
            ],

            // Contacts
            if (company.mobile != null && company.mobile!.isNotEmpty) ...[
              _buildContactRow('Contacts', company.mobile!, 'tel:${company.mobile}'),
              const SizedBox(height: 16),
            ],

            // Email
            if (company.email != null && company.email!.isNotEmpty) ...[
              _buildContactRow('Email', company.email!, 'mailto:${company.email}'),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  /// Find a good split point (end of sentence/paragraph near the middle).
  int _findSplitPoint(String text) {
    final mid = text.length ~/ 2;
    // Look for paragraph break near middle
    final paragraphBreak = text.indexOf('\n', mid);
    if (paragraphBreak != -1 && paragraphBreak < mid + 200) {
      return paragraphBreak;
    }
    // Look for sentence end near middle
    final sentenceEnd = text.indexOf('. ', mid);
    if (sentenceEnd != -1 && sentenceEnd < mid + 200) {
      return sentenceEnd + 2;
    }
    return mid;
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 500;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                company.name,
                style: GoogleFonts.montserrat(
                  fontSize: isMobile ? 20 : 30,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            if (company.fullLogoUrl != null || company.brandIconUrl != null) ...[
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  company.fullLogoUrl ?? company.brandIconUrl!,
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

  Widget _buildSocialSection(List<MapEntry<String, dynamic>> socials) {
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
          final url = entry.value.toString();
          final icon = _socialIcons[key] ?? Icons.link;

          return InkWell(
              onTap: () => _launchUrl(url),
              borderRadius: BorderRadius.circular(17),
              child: Container(
                width: 34,
                height: 34,
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

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// =============================================================================
// Gallery Layout — Figma style
// 1 tall image left, 2 small images top-right, 1 wide image bottom-right
// =============================================================================

class _GalleryLayout extends StatelessWidget {
  final List<String> urls;
  const _GalleryLayout({required this.urls});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        // Left image: ~33%, right side: ~66%
        final leftWidth = (totalWidth * 0.34).roundToDouble();
        final rightWidth = totalWidth - leftWidth - 12; // 12 = gap
        final tallHeight = 571.0 * (totalWidth / 1011).clamp(0.4, 1.0);
        final smallHeight = (tallHeight - 12) * 0.46; // top pair height
        final wideHeight = tallHeight - smallHeight - 12; // bottom wide

        return SizedBox(
          height: tallHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left tall image
              _galleryImage(urls[0], leftWidth, tallHeight),
              const SizedBox(width: 12),
              // Right side
              Expanded(
                child: Column(
                  children: [
                    // Top row: 2 small images
                    Row(
                      children: [
                        if (urls.length > 1)
                          _galleryImage(
                              urls[1],
                              (rightWidth - 12) / 2,
                              smallHeight),
                        if (urls.length > 1) const SizedBox(width: 12),
                        if (urls.length > 2)
                          _galleryImage(
                              urls[2],
                              (rightWidth - 12) / 2,
                              smallHeight),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Bottom wide image
                    if (urls.length > 3)
                      _galleryImage(urls[3], rightWidth, wideHeight),
                  ],
                ),
              ),
            ],
          ),
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

// =============================================================================
// Member Card Carousel — horizontal scrolling
// =============================================================================

class _MemberCarousel extends StatelessWidget {
  final List<Map<String, dynamic>> members;
  const _MemberCarousel({required this.members});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 246,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: members.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) => _buildMemberCard(members[index]),
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    final name =
        '${member['first_name'] ?? ''} ${member['last_name'] ?? ''}'.trim();
    final position = member['position'] as String? ?? '';
    final company = member['company_name'] as String?;
    final photoUrl = member['profile_photo_url'] as String?;
    final country = member['country'] as String?;
    final role = member['role'] as String? ?? '';

    return Container(
      width: 184,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.25),
            blurRadius: 5,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(5)),
            child: SizedBox(
              width: 184,
              height: 122,
              child: photoUrl != null
                  ? Image.network(photoUrl, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _photoPlaceholder(name))
                  : _photoPlaceholder(name),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Text(
                  name,
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Position + Company
                if (position.isNotEmpty || (company != null && company.isNotEmpty))
                  Text(
                    [position, company].where((e) => e != null && e.isNotEmpty).join(', '),
                    style: GoogleFonts.roboto(
                      fontSize: 10,
                      color: Colors.black,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 8),
                // Role + country with flag
                Row(
                  children: [
                    if (country != null && country.isNotEmpty) ...[
                      Icon(Icons.flag_outlined,
                          size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        [role.isNotEmpty ? _roleLabel(role) : null, country]
                            .where((e) => e != null && e.isNotEmpty)
                            .join(', '),
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          // View Profile button
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Container(
              width: double.infinity,
              height: 25,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: AppTheme.primaryColor),
              ),
              child: Center(
                child: Text(
                  'View Profile',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoPlaceholder(String name) {
    return Container(
      color: AppTheme.primaryColor.withValues(alpha: 0.1),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: GoogleFonts.montserrat(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role.toUpperCase()) {
      case 'ADMINISTRATOR':
        return 'Admin';
      case 'SPEAKER':
        return 'Speaker';
      case 'KEYNOTE':
        return 'Keynote';
      default:
        return role;
    }
  }
}
