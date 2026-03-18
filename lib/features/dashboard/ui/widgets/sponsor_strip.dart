import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_theme.dart';

/// Auto-scrolling sponsor logo strip with primary-color background.
class SponsorStrip extends StatelessWidget {
  final List<Map<String, dynamic>> sponsors;
  final bool isLoading;
  final ScrollController scrollController;

  const SponsorStrip({
    super.key,
    required this.sponsors,
    required this.isLoading,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (sponsors.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: sponsors.length * 100,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemBuilder: (context, index) {
          final s = sponsors[index % sponsors.length];
          return _SponsorCard(sponsor: s);
        },
      ),
    );
  }
}

class _SponsorCard extends StatelessWidget {
  final Map<String, dynamic> sponsor;

  const _SponsorCard({required this.sponsor});

  @override
  Widget build(BuildContext context) {
    final tier = sponsor['tier'] as String? ?? 'general';
    final rawLogoUrl = sponsor['logo'] as String?;
    final website = sponsor['website'] as String?;

    String? fullLogoUrl;
    if (rawLogoUrl != null && rawLogoUrl.isNotEmpty) {
      if (rawLogoUrl.startsWith('http')) {
        fullLogoUrl = rawLogoUrl;
      } else {
        // Relative path — proxy through B2C backend
        fullLogoUrl =
            '${AppConfig.b2cApiBaseUrl}/proxy/tourism${rawLogoUrl.startsWith('/') ? rawLogoUrl : '/$rawLogoUrl'}';
      }
    }

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () async {
            if (website == null || website.isEmpty) return;
            var url = website;
            if (!url.startsWith('http://') && !url.startsWith('https://')) {
              url = 'https://$url';
            }
            try {
              await launchUrl(
                Uri.parse(url),
                mode: LaunchMode.externalApplication,
              );
            } catch (_) {}
          },
          child: Container(
            width: 130,
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: fullLogoUrl != null
                      ? Image.network(
                          fullLogoUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.business,
                            color: AppTheme.primaryColor,
                            size: 28,
                          ),
                        )
                      : const Icon(
                          Icons.business,
                          color: AppTheme.primaryColor,
                          size: 28,
                        ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tier.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
