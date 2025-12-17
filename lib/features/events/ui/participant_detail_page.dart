import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/services/event_context_service.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../notifications/ui/notification_drawer.dart';
import 'widgets/profile_dropdown.dart';

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

class _ParticipantDetailPageState extends ConsumerState<ParticipantDetailPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isProfileOpen = false;

  Map<String, dynamic>? _participant;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.participantData != null) {
      _participant = widget.participantData;
      _isLoading = false;
    } else {
      _fetchParticipant();
    }
  }

  Future<void> _fetchParticipant() async {
    try {
      final siteId = eventContextService.siteId;
      final uri = siteId != null
          ? Uri.parse(
              '${AppConfig.tourismApiBaseUrl}/participants/${widget.participantId}?site_id=$siteId',
            )
          : Uri.parse(
              '${AppConfig.tourismApiBaseUrl}/participants/${widget.participantId}',
            );

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        setState(() {
          _participant = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        debugPrint('Failed to fetch participant: ${response.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching participant: $e');
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
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(10),
                        ),
                      ),
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF3C4494),
                              ),
                            )
                          : _participant == null
                          ? Center(
                              child: Text(
                                'Participant not found',
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
          onPressed: () => context.go('/events/${widget.eventId}/participants'),
        ),
        const SizedBox(width: 8),
        // Title
        Text(
          'Participant',
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
    final name = _participant!['name'] ?? '';
    final bio = _participant!['bio'] ?? '';
    final logoUrl = _buildImageUrl(_participant!['logo']);

    // Get images list
    List<Map<String, dynamic>> images = [];
    final imagesData = _participant!['images'];
    if (imagesData != null && imagesData is List) {
      for (var img in imagesData) {
        if (img is Map) {
          images.add({'id': img['id'], 'path': _buildImageUrl(img['path'])});
        }
      }
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb
          Row(
            children: [
              GestureDetector(
                onTap: () =>
                    context.go('/events/${widget.eventId}/participants'),
                child: Text(
                  'Participants',
                  style: GoogleFonts.roboto(
                    fontSize: isMobile ? 18 : 24,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6B6B6B),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.chevron_right,
                  size: isMobile ? 18 : 20,
                  color: const Color(0xFF6B6B6B),
                ),
              ),
              Text(
                'Details',
                style: GoogleFonts.roboto(
                  fontSize: isMobile ? 18 : 24,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B6B6B),
                ),
              ),
            ],
          ),

          SizedBox(height: isMobile ? 16 : 24),

          // Name and Logo row
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name - wraps to multiple lines
                    Text(
                      name.isNotEmpty ? name : 'Unknown Participant',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF1E1E1E),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Logo with shadow
                    if (logoUrl.isNotEmpty)
                      Container(
                        height: 100,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              spreadRadius: 1,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Image.network(
                          logoUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name - takes up to half the screen, wraps
                    Expanded(
                      flex: 1,
                      child: Text(
                        name.isNotEmpty ? name : 'Unknown Participant',
                        style: GoogleFonts.poppins(
                          fontSize: 30,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF1E1E1E),
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                    // Logo with shadow - bigger size
                    if (logoUrl.isNotEmpty)
                      Container(
                        width: 320,
                        height: 140,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 12,
                              spreadRadius: 2,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Image.network(
                          logoUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                  ],
                ),

          SizedBox(height: isMobile ? 16 : 24),

          // Divider
          Container(height: 2, color: const Color(0xFFB59C83)),

          SizedBox(height: isMobile ? 16 : 24),

          // Bio (first part)
          if (bio.isNotEmpty)
            Text(
              bio,
              style: GoogleFonts.lato(
                fontSize: isMobile ? 16 : 25,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1E1E1E),
                height: 1.6,
              ),
            ),

          SizedBox(height: isMobile ? 24 : 40),

          // Gallery
          if (images.isNotEmpty) ...[
            _buildGallery(images, isMobile),
            SizedBox(height: isMobile ? 24 : 40),
          ],

          // Social Links and Contacts placeholders
          _buildSocialAndContacts(isMobile),
        ],
      ),
    );
  }

  Widget _buildGallery(List<Map<String, dynamic>> images, bool isMobile) {
    if (images.isEmpty) return const SizedBox.shrink();

    final imageCount = images.length;

    // For mobile, show images in a responsive grid
    if (isMobile) {
      return _buildDynamicMobileGallery(images);
    }

    // For desktop, create dynamic layouts based on image count
    return SizedBox(
      height: 450,
      child: _buildDynamicDesktopGallery(images, imageCount),
    );
  }

  Widget _buildDynamicMobileGallery(List<Map<String, dynamic>> images) {
    // Show all images in a 2-column grid on mobile
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            images[index]['path'] ?? '',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey[300],
              child: const Center(
                child: Icon(Icons.image, size: 40, color: Colors.grey),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDynamicDesktopGallery(
    List<Map<String, dynamic>> images,
    int count,
  ) {
    // Dynamic layout based on number of images
    if (count == 1) {
      // Single image - full width
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          images[0]['path'] ?? '',
          fit: BoxFit.cover,
          width: double.infinity,
          height: 450,
          errorBuilder: (_, __, ___) => _buildImagePlaceholder(450),
        ),
      );
    } else if (count == 2) {
      // Two images side by side
      return Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                images[0]['path'] ?? '',
                fit: BoxFit.cover,
                height: 450,
                errorBuilder: (_, __, ___) => _buildImagePlaceholder(450),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                images[1]['path'] ?? '',
                fit: BoxFit.cover,
                height: 450,
                errorBuilder: (_, __, ___) => _buildImagePlaceholder(450),
              ),
            ),
          ),
        ],
      );
    } else if (count == 3) {
      // One large left, two stacked right
      return Row(
        children: [
          Expanded(
            flex: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                images[0]['path'] ?? '',
                fit: BoxFit.cover,
                height: 450,
                errorBuilder: (_, __, ___) => _buildImagePlaceholder(450),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      images[1]['path'] ?? '',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) =>
                          _buildImagePlaceholder(null),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      images[2]['path'] ?? '',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) =>
                          _buildImagePlaceholder(null),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      // 4+ images: large left, 2 top-right, 1 bottom-right (or grid for more)
      return Row(
        children: [
          Expanded(
            flex: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                images[0]['path'] ?? '',
                fit: BoxFit.cover,
                height: 450,
                errorBuilder: (_, __, ___) => _buildImagePlaceholder(450),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                // Top row - 2 images
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            images[1]['path'] ?? '',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildImagePlaceholder(null),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            images[2]['path'] ?? '',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildImagePlaceholder(null),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Bottom row - remaining images or single large
                Expanded(
                  child: count == 4
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            images[3]['path'] ?? '',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) =>
                                _buildImagePlaceholder(null),
                          ),
                        )
                      : Row(
                          children: images.skip(3).take(3).map((img) {
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    img['path'] ?? '',
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _buildImagePlaceholder(null),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }

  Widget _buildImagePlaceholder(double? height) {
    return Container(
      height: height,
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.image, size: 60, color: Colors.grey),
      ),
    );
  }

  Widget _buildSocialAndContacts(bool isMobile) {
    // Placeholder for social links and contacts
    // These would typically come from the API if available
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Social links
        Row(
          children: [
            Text(
              'Follow me:',
              style: GoogleFonts.roboto(
                fontSize: isMobile ? 18 : 25,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 16),
            _buildSocialIcon(Icons.facebook, () {}),
            const SizedBox(width: 12),
            _buildSocialIcon(Icons.camera_alt, () {}),
            const SizedBox(width: 12),
            _buildSocialIcon(Icons.business, () {}),
          ],
        ),

        SizedBox(height: isMobile ? 16 : 24),

        // Contacts placeholder
        Row(
          children: [
            Text(
              'Contacts:',
              style: GoogleFonts.roboto(
                fontSize: isMobile ? 18 : 25,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              '+993-xx-xx-xx-xx',
              style: GoogleFonts.roboto(
                fontSize: isMobile ? 16 : 25,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
          ],
        ),

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSocialIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: const BoxDecoration(
          color: Color(0xFF3C4494),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: const Color(0xFFF1F1F6)),
      ),
    );
  }
}
