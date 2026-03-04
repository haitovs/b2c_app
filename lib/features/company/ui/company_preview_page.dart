import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/layouts/event_sidebar_layout.dart';
import '../../../shared/widgets/breadcrumb_nav.dart';
import '../models/company.dart';
import '../providers/company_providers.dart';

/// Read-only public view of a company profile.
class CompanyPreviewPage extends ConsumerWidget {
  final String companyId;

  const CompanyPreviewPage({super.key, required this.companyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventIdStr = GoRouterState.of(context).pathParameters['id'] ?? '';
    final companyAsync = ref.watch(companyDetailProvider(companyId));

    return EventSidebarLayout(
      title: 'Company Preview',
      child: companyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text('Failed to load company', style: GoogleFonts.inter(color: Colors.grey.shade600)),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => ref.invalidate(companyDetailProvider(companyId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (company) => _buildContent(context, company, eventIdStr),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Company company, String eventIdStr) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb
          BreadcrumbNav(items: [
            BreadcrumbItem(label: 'Dashboard', path: '/events/$eventIdStr/menu'),
            BreadcrumbItem(label: 'Participants', path: '/events/$eventIdStr/participants'),
            BreadcrumbItem(label: company.name),
          ]),
          const SizedBox(height: 24),

          // Header card with cover + info
          _HeaderSection(company: company),
          const SizedBox(height: 20),

          // About
          if (company.about != null && company.about!.isNotEmpty)
            _SectionCard(
              title: 'About',
              child: Text(
                company.about!,
                style: GoogleFonts.inter(fontSize: 14, height: 1.6, color: Colors.grey.shade800),
              ),
            ),

          // Gallery
          if (company.galleryUrls != null && company.galleryUrls!.isNotEmpty) ...[
            const SizedBox(height: 20),
            _SectionCard(
              title: 'Gallery',
              child: _GalleryGrid(urls: company.galleryUrls!),
            ),
          ],

          // Team Members
          const SizedBox(height: 20),
          _SectionCard(
            title: 'Team Members',
            child: company.teamMembers != null && company.teamMembers!.isNotEmpty
                ? _TeamList(members: company.teamMembers!)
                : Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text('No team members.', style: GoogleFonts.inter(color: Colors.grey)),
                  ),
          ),

          // Contact & Social
          const SizedBox(height: 20),
          _ContactSection(company: company),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header Section
// ---------------------------------------------------------------------------
class _HeaderSection extends StatelessWidget {
  final Company company;
  const _HeaderSection({required this.company});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image
          SizedBox(
            width: double.infinity,
            height: 200,
            child: company.coverImageUrl != null
                ? Image.network(company.coverImageUrl!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _coverPlaceholder())
                : _coverPlaceholder(),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade100,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8)],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: company.brandIconUrl != null
                      ? Image.network(company.brandIconUrl!, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _iconPlaceholder())
                      : _iconPlaceholder(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(company.name,
                          style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.w700)),
                      if (company.country != null || company.city != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          [company.city, company.country].where((e) => e != null).join(', '),
                          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade600),
                        ),
                      ],
                      if (company.categories != null && company.categories!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: company.categories!.map((c) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(c, style: GoogleFonts.inter(
                              fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.w500)),
                          )).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _coverPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3C4494), Color(0xFF5B6BC0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(child: Icon(Icons.business, size: 48, color: Colors.white54)),
    );
  }

  Widget _iconPlaceholder() {
    return Center(
      child: Text(
        company.name.isNotEmpty ? company.name[0].toUpperCase() : '?',
        style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.primaryColor),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section Card
// ---------------------------------------------------------------------------
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Gallery Grid
// ---------------------------------------------------------------------------
class _GalleryGrid extends StatelessWidget {
  final List<String> urls;
  const _GalleryGrid({required this.urls});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth >= 500 ? 2 : 1;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: urls.take(4).map((url) {
          final w = (constraints.maxWidth - (cols - 1) * 12) / cols;
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: w,
              height: w * 0.65,
              child: Image.network(url, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade100,
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  )),
            ),
          );
        }).toList(),
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Team List
// ---------------------------------------------------------------------------
class _TeamList extends StatelessWidget {
  final List<Map<String, dynamic>> members;
  const _TeamList({required this.members});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: members.map((m) {
        final name = '${m['first_name'] ?? ''} ${m['last_name'] ?? ''}'.trim();
        final position = m['position'] as String? ?? '';
        final role = m['role'] as String? ?? 'USER';
        final photoUrl = m['profile_photo_url'] as String?;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                child: photoUrl == null
                    ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, color: AppTheme.primaryColor))
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                    if (position.isNotEmpty)
                      Text(position, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: role == 'ADMINISTRATOR'
                      ? AppTheme.primaryColor.withValues(alpha: 0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  role == 'ADMINISTRATOR' ? 'Admin' : 'Member',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: role == 'ADMINISTRATOR' ? AppTheme.primaryColor : Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Contact Section
// ---------------------------------------------------------------------------
class _ContactSection extends StatelessWidget {
  final Company company;
  const _ContactSection({required this.company});

  @override
  Widget build(BuildContext context) {
    final socialLinks = company.socialLinks ?? {};
    final hasSocial = socialLinks.values.any((v) => v != null && v.toString().isNotEmpty);
    final hasContact = company.email != null || company.mobile != null || company.website != null;

    if (!hasContact && !hasSocial) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth >= 500) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasContact) Expanded(child: _buildContact()),
              if (hasContact && hasSocial) const SizedBox(width: 24),
              if (hasSocial) Expanded(child: _buildSocial(socialLinks)),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasContact) _buildContact(),
            if (hasContact && hasSocial) const SizedBox(height: 20),
            if (hasSocial) _buildSocial(socialLinks),
          ],
        );
      }),
    );
  }

  Widget _buildContact() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Contact', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        if (company.email != null)
          _contactRow(Icons.email_outlined, company.email!),
        if (company.mobile != null)
          _contactRow(Icons.phone_outlined, company.mobile!),
        if (company.website != null)
          _contactRow(Icons.language, company.website!),
      ],
    );
  }

  Widget _contactRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: GoogleFonts.inter(fontSize: 14, color: AppTheme.primaryColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildSocial(Map<String, dynamic> links) {
    final socialIcons = <String, IconData>{
      'linkedin': Icons.business,
      'instagram': Icons.camera_alt_outlined,
      'twitter': Icons.alternate_email,
      'facebook': Icons.facebook,
      'whatsapp': Icons.chat_outlined,
      'wechat': Icons.message_outlined,
    };

    final activeLinks = links.entries
        .where((e) => e.value != null && e.value.toString().isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Social', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: activeLinks.map((entry) {
            final icon = socialIcons[entry.key.toLowerCase()] ?? Icons.link;
            return Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: AppTheme.primaryColor),
            );
          }).toList(),
        ),
      ],
    );
  }
}
