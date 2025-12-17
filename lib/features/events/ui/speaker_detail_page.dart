import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/services/event_context_service.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../notifications/ui/notification_drawer.dart';
import 'widgets/profile_dropdown.dart';

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isProfileOpen = false;

  Map<String, dynamic>? _speaker;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.speakerData != null) {
      _speaker = widget.speakerData;
      _isLoading = false;
    } else {
      _fetchSpeaker();
    }
  }

  Future<void> _fetchSpeaker() async {
    try {
      // Use EventContextService for site_id
      final siteId = eventContextService.siteId;
      final uri = siteId != null
          ? Uri.parse(
              '${AppConfig.tourismApiBaseUrl}/speakers/${widget.speakerId}?site_id=$siteId',
            )
          : Uri.parse(
              '${AppConfig.tourismApiBaseUrl}/speakers/${widget.speakerId}',
            );

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        setState(() {
          _speaker = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        debugPrint('Failed to fetch speaker: ${response.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching speaker: $e');
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

  Future<void> _launchUrl(String url) async {
    try {
      String finalUrl = url;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        finalUrl = 'https://$url';
      }
      final uri = Uri.parse(finalUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch $url: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
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

                  // Content Container
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F1F6),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF3C4494),
                              ),
                            )
                          : _speaker == null
                          ? Center(
                              child: Text(
                                'Speaker not found',
                                style: GoogleFonts.roboto(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            )
                          : _buildContent(isMobile),
                    ),
                  ),
                ],
              ),
            ),

            // Profile Dropdown
            if (_isProfileOpen)
              Positioned(
                top: isMobile ? 55 : 70,
                right: horizontalPadding,
                child: ProfileDropdown(
                  onClose: _closeProfile,
                  onLogout: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/');
                    }
                  },
                ),
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
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: isMobile ? 24 : 28,
          ),
          onPressed: () => context.go('/events/${widget.eventId}/speakers'),
        ),
        const SizedBox(width: 8),
        // Title
        Text(
          'Speaker',
          style: GoogleFonts.montserrat(
            fontSize: isMobile ? 24 : 28,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const Spacer(),
        // Custom App Bar with notifications and profile
        CustomAppBar(
          onProfileTap: _toggleProfile,
          onNotificationTap: () {
            _closeProfile();
            _scaffoldKey.currentState?.openEndDrawer();
          },
          isMobile: isMobile,
        ),
      ],
    );
  }

  Widget _buildContent(bool isMobile) {
    final name = _speaker!['name'] ?? '';
    final surname = _speaker!['surname'] ?? '';
    final fullName = '$name $surname'.trim();
    final position = _speaker!['position'] ?? '';
    final company = _speaker!['company'] ?? '';
    final description = _speaker!['description'] ?? '';
    final phone = _speaker!['phone'] ?? '';
    final email = _speaker!['email'] ?? '';
    final photoUrl = _buildImageUrl(_speaker!['photo']);
    final companyPhotoUrl = _buildImageUrl(_speaker!['company_photo']);

    // Parse social links
    List<Map<String, String>> socialLinks = [];
    final socialLinksData = _speaker!['social_links'];
    if (socialLinksData != null) {
      if (socialLinksData is List) {
        for (var link in socialLinksData) {
          if (link is Map) {
            socialLinks.add({
              'platform': link['platform']?.toString() ?? '',
              'url': link['url']?.toString() ?? '',
            });
          }
        }
      }
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb
          Row(
            children: [
              GestureDetector(
                onTap: () => context.go('/events/${widget.eventId}/speakers'),
                child: Text(
                  'Speakers',
                  style: GoogleFonts.roboto(
                    fontSize: isMobile ? 14 : 18,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF616161),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.chevron_right,
                  size: isMobile ? 18 : 20,
                  color: const Color(0xFF616161),
                ),
              ),
              Text(
                'Speaker',
                style: GoogleFonts.roboto(
                  fontSize: isMobile ? 14 : 18,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF616161),
                ),
              ),
            ],
          ),

          SizedBox(height: isMobile ? 16 : 24),

          // Main content - Photo and Info
          isMobile
              ? _buildMobileLayout(
                  fullName,
                  position,
                  company,
                  description,
                  phone,
                  email,
                  photoUrl,
                  companyPhotoUrl,
                  socialLinks,
                )
              : _buildDesktopLayout(
                  fullName,
                  position,
                  company,
                  description,
                  phone,
                  email,
                  photoUrl,
                  companyPhotoUrl,
                  socialLinks,
                ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(
    String fullName,
    String position,
    String company,
    String description,
    String phone,
    String email,
    String photoUrl,
    String companyPhotoUrl,
    List<Map<String, String>> socialLinks,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Photo
        Center(
          child: Container(
            width: 200,
            height: 240,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
            child: photoUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.person, size: 80, color: Colors.grey),
                      ),
                    ),
                  )
                : const Center(
                    child: Icon(Icons.person, size: 80, color: Colors.grey),
                  ),
          ),
        ),

        const SizedBox(height: 24),

        // Info Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Personal Information label
              Text(
                'Personal Information',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF151938).withValues(alpha: 0.85),
                ),
              ),

              const SizedBox(height: 8),

              // Name
              Text(
                fullName.isNotEmpty ? fullName : 'Unknown Speaker',
                style: GoogleFonts.roboto(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF151938),
                ),
              ),

              const SizedBox(height: 16),

              // Company and Position
              _buildCompanyPositionRow(
                company,
                position,
                companyPhotoUrl,
                true,
              ),

              const SizedBox(height: 20),

              // Description
              if (description.isNotEmpty)
                Text(
                  description,
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 1.6,
                    color: Colors.black,
                  ),
                ),

              const SizedBox(height: 24),

              // Social Links
              if (socialLinks.isNotEmpty) _buildSocialLinks(socialLinks, true),

              const SizedBox(height: 16),

              // Contacts
              if (phone.isNotEmpty || email.isNotEmpty)
                _buildContacts(phone, email, true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(
    String fullName,
    String position,
    String company,
    String description,
    String phone,
    String email,
    String photoUrl,
    String companyPhotoUrl,
    List<Map<String, String>> socialLinks,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Photo
        Container(
          width: 300,
          height: 351,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(10),
          ),
          child: photoUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    photoUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.person, size: 100, color: Colors.grey),
                    ),
                  ),
                )
              : const Center(
                  child: Icon(Icons.person, size: 100, color: Colors.grey),
                ),
        ),

        const SizedBox(width: 50),

        // Info Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row with label and meeting request button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Personal Information',
                      style: GoogleFonts.roboto(
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF151938).withValues(alpha: 0.85),
                      ),
                    ),
                    // Meeting request button
                    OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Implement meeting request
                      },
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: const Text('Meeting request'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF151938),
                        side: const BorderSide(color: Color(0xFF383B56)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Name
                Text(
                  fullName.isNotEmpty ? fullName : 'Unknown Speaker',
                  style: GoogleFonts.roboto(
                    fontSize: 65,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF151938),
                  ),
                ),

                const SizedBox(height: 20),

                // Company and Position
                _buildCompanyPositionRow(
                  company,
                  position,
                  companyPhotoUrl,
                  false,
                ),

                const SizedBox(height: 30),

                // Description
                if (description.isNotEmpty)
                  Text(
                    description,
                    style: GoogleFonts.roboto(
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                      height: 1.6,
                      color: Colors.black,
                    ),
                  ),

                const SizedBox(height: 40),

                // Social Links
                if (socialLinks.isNotEmpty)
                  _buildSocialLinks(socialLinks, false),

                const SizedBox(height: 20),

                // Contacts
                if (phone.isNotEmpty || email.isNotEmpty)
                  _buildContacts(phone, email, false),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompanyPositionRow(
    String company,
    String position,
    String companyPhotoUrl,
    bool isMobile,
  ) {
    return Row(
      children: [
        // Company logo if available
        if (companyPhotoUrl.isNotEmpty)
          Container(
            width: isMobile ? 60 : 100,
            height: isMobile ? 40 : 66,
            margin: EdgeInsets.only(right: isMobile ? 12 : 20),
            child: Image.network(
              companyPhotoUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),

        // Divider
        if (companyPhotoUrl.isNotEmpty || company.isNotEmpty)
          Container(
            width: 2,
            height: isMobile ? 40 : 60,
            margin: EdgeInsets.only(right: isMobile ? 12 : 20),
            color: const Color(0xFF20306C),
          ),

        // Position and Company
        Expanded(
          child: Text(
            position.isNotEmpty && company.isNotEmpty
                ? '$position, $company'
                : position.isNotEmpty
                ? position
                : company,
            style: GoogleFonts.roboto(
              fontSize: isMobile ? 16 : 25,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF151938),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialLinks(
    List<Map<String, String>> socialLinks,
    bool isMobile,
  ) {
    return Row(
      children: [
        Text(
          'Follow me:',
          style: GoogleFonts.roboto(
            fontSize: isMobile ? 18 : 25,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        SizedBox(width: isMobile ? 12 : 20),
        ...socialLinks.map((link) {
          IconData icon = Icons.link;
          final platform = link['platform']?.toLowerCase() ?? '';
          if (platform.contains('facebook')) {
            icon = Icons.facebook;
          } else if (platform.contains('instagram')) {
            icon = Icons.camera_alt;
          } else if (platform.contains('linkedin')) {
            icon = Icons.business;
          } else if (platform.contains('twitter') || platform.contains('x')) {
            icon = Icons.alternate_email;
          }

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => _launchUrl(link['url'] ?? ''),
              child: Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: Color(0xFF3C4494),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: const Color(0xFFF1F1F6)),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildContacts(String phone, String email, bool isMobile) {
    return Row(
      children: [
        Text(
          'Contacts:',
          style: GoogleFonts.roboto(
            fontSize: isMobile ? 18 : 25,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        SizedBox(width: isMobile ? 12 : 20),
        if (phone.isNotEmpty)
          GestureDetector(
            onTap: () => _launchUrl('tel:$phone'),
            child: Text(
              phone,
              style: GoogleFonts.roboto(
                fontSize: isMobile ? 16 : 25,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
          ),
        if (phone.isNotEmpty && email.isNotEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16),
            child: Text(
              '|',
              style: GoogleFonts.roboto(
                fontSize: isMobile ? 16 : 25,
                color: Colors.grey,
              ),
            ),
          ),
        if (email.isNotEmpty)
          GestureDetector(
            onTap: () => _launchUrl('mailto:$email'),
            child: Text(
              email,
              style: GoogleFonts.roboto(
                fontSize: isMobile ? 16 : 25,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
          ),
      ],
    );
  }
}
