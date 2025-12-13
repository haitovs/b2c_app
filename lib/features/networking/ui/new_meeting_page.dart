import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart' as legacy_provider;

import '../../../core/config/app_config.dart';
import '../../../core/services/event_context_service.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../auth/services/auth_service.dart';
import '../../events/ui/widgets/profile_dropdown.dart';
import '../../notifications/ui/notification_drawer.dart';

/// New Meeting Page - Grid of participants/entities to select for meeting
class NewMeetingPage extends ConsumerStatefulWidget {
  final String eventId;

  const NewMeetingPage({super.key, required this.eventId});

  @override
  ConsumerState<NewMeetingPage> createState() => _NewMeetingPageState();
}

class _NewMeetingPageState extends ConsumerState<NewMeetingPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isProfileOpen = false;

  // Meeting type toggle
  bool _isB2B = true; // true = B2B, false = B2G

  // Filter state (will be used when filter chips are added)
  // ignore: unused_field
  final String _selectedDirectionFilter = 'all'; // all, sent, received
  // ignore: unused_field
  final String _selectedStatusFilter =
      'all'; // all, approved, pending, declined

  // Search
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Data
  List<Map<String, dynamic>> _participants = []; // B2B participants
  List<Map<String, dynamic>> _govEntities = []; // B2G gov entities
  List<Map<String, dynamic>> _filteredItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAndFetch();
  }

  Future<void> _initializeAndFetch() async {
    // Ensure the event context is loaded for this event
    final eventId = int.tryParse(widget.eventId);
    if (eventId != null) {
      await eventContextService.ensureEventContext(eventId);
    }
    _fetchData();
  }

  void _onToggleChanged(bool isB2B) {
    setState(() {
      _isB2B = isB2B;
      _applyFilters();
    });

    // Lazy-load B2G data when switching to B2G tab
    if (!isB2B && _govEntities.isEmpty) {
      _fetchGovEntities();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleProfile() {
    setState(() {
      _isProfileOpen = !_isProfileOpen;
    });
  }

  void _closeProfile() {
    if (_isProfileOpen) {
      setState(() {
        _isProfileOpen = false;
      });
    }
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    try {
      final authService = legacy_provider.Provider.of<AuthService>(
        context,
        listen: false,
      );
      final token = await authService.getToken();

      // Fetch B2C users for B2B meetings
      // These have UUID IDs for meeting requests between app users
      try {
        final usersResponse = await http.get(
          Uri.parse('${AppConfig.b2cApiBaseUrl}/api/v1/users/'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        if (usersResponse.statusCode == 200) {
          final List data = jsonDecode(usersResponse.body);
          _participants = data.cast<Map<String, dynamic>>();
        } else {
          debugPrint('Failed to fetch B2C users: ${usersResponse.statusCode}');
        }
      } catch (usersError) {
        debugPrint('Error fetching B2C users: $usersError');
      }

      // Note: B2G gov entities are now fetched lazily when user switches to B2G tab

      setState(() {
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchGovEntities() async {
    if (_govEntities.isNotEmpty) return; // Already loaded

    try {
      final authService = legacy_provider.Provider.of<AuthService>(
        context,
        listen: false,
      );
      final token = await authService.getToken();

      final govResponse = await http.get(
        Uri.parse('${AppConfig.b2cApiBaseUrl}/api/v1/meetings/gov-entities'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (govResponse.statusCode == 200) {
        final List govData = jsonDecode(govResponse.body);
        setState(() {
          _govEntities = govData.cast<Map<String, dynamic>>();
          _applyFilters();
        });
      }
    } catch (govError) {
      debugPrint('Error fetching gov entities: $govError');
    }
  }

  void _applyFilters() {
    // Select data source based on toggle
    List<Map<String, dynamic>> source = _isB2B ? _participants : _govEntities;
    List<Map<String, dynamic>> result = List.from(source);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      result = result.where((item) {
        if (_isB2B) {
          // Search B2C user fields
          final firstName = (item['first_name'] ?? '').toString().toLowerCase();
          final lastName = (item['last_name'] ?? '').toString().toLowerCase();
          final companyName = (item['company_name'] ?? '')
              .toString()
              .toLowerCase();
          final query = _searchQuery.toLowerCase();
          return firstName.contains(query) ||
              lastName.contains(query) ||
              companyName.contains(query);
        } else {
          // Search gov entity name
          final name = (item['name'] ?? '').toString().toLowerCase();
          return name.contains(_searchQuery.toLowerCase());
        }
      }).toList();
    }

    setState(() {
      _filteredItems = result;
    });
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _applyFilters();
    });
  }

  String _buildImageUrl(String? imagePath, {bool isB2G = false}) {
    if (imagePath == null || imagePath.isEmpty) return '';
    if (imagePath.startsWith('http')) return imagePath;
    // B2C backend for both B2B users and B2G entities
    return '${AppConfig.b2cApiBaseUrl}$imagePath';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF3C4494),
      endDrawer: const NotificationDrawer(),
      body: GestureDetector(
        onTap: _closeProfile,
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  // Custom header
                  _buildHeader(),
                  // B2B/B2G toggle row
                  _buildToggleRow(),
                  const SizedBox(height: 16),
                  // Search bar
                  _buildSearchBar(),
                  const SizedBox(height: 16),
                  // Content area with white rounded container
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _buildItemsGrid(),
                    ),
                  ),
                ],
              ),
            ),
            // Profile dropdown overlay
            if (_isProfileOpen)
              Positioned(
                top: 100,
                right: 20,
                child: ProfileDropdown(onClose: _closeProfile),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 8),
          // Title
          Text(
            'New Meeting',
            style: GoogleFonts.montserrat(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          // Notification & Profile icons
          CustomAppBar(
            onNotificationTap: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
            onProfileTap: _toggleProfile,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Center(child: _buildMeetingTypeToggle()),
    );
  }

  Widget _buildMeetingTypeToggle() {
    // Responsive toggle size
    final isSmall = MediaQuery.of(context).size.width < 600;
    final fontSize = isSmall ? 14.0 : 20.0;
    final horizontalPadding = isSmall ? 16.0 : 40.0;
    final verticalPadding = isSmall ? 8.0 : 12.0;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // B2B button
          GestureDetector(
            onTap: () => _onToggleChanged(true),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              decoration: BoxDecoration(
                color: _isB2B ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'B2B',
                style: GoogleFonts.roboto(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: _isB2B ? Colors.black : Colors.white,
                ),
              ),
            ),
          ),
          // B2G button
          GestureDetector(
            onTap: () => _onToggleChanged(false),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              decoration: BoxDecoration(
                color: !_isB2B ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'B2G',
                style: GoogleFonts.roboto(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: !_isB2B ? Colors.black : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: Colors.white.withOpacity(0.8), size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.roboto(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: _isB2B ? 'Search users...' : 'Search entities...',
                hintStyle: GoogleFonts.roboto(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 16,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsGrid() {
    if (_filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No companies found',
              style: GoogleFonts.roboto(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive grid
        int crossAxisCount;
        double childAspectRatio;
        if (constraints.maxWidth > 1200) {
          crossAxisCount = 4;
          childAspectRatio = 0.95;
        } else if (constraints.maxWidth > 900) {
          crossAxisCount = 3;
          childAspectRatio = 0.9;
        } else if (constraints.maxWidth > 600) {
          crossAxisCount = 2;
          childAspectRatio = 0.95;
        } else {
          crossAxisCount = 2;
          childAspectRatio = 0.85;
        }

        return GridView.builder(
          padding: const EdgeInsets.all(30),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 30,
            mainAxisSpacing: 30,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: _filteredItems.length,
          itemBuilder: (context, index) {
            return _buildItemCard(_filteredItems[index]);
          },
        );
      },
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    // B2B: B2C users have first_name, last_name, company_name, photo_url
    // B2G: Gov entities have name, logo_url
    String name;
    String? imageUrl;
    String? subtitle;

    if (_isB2B) {
      // B2C user fields - combine first_name and last_name
      final firstName = item['first_name'] ?? '';
      final lastName = item['last_name'] ?? '';
      name = '$firstName $lastName'.trim();
      if (name.isEmpty) name = item['email'] ?? 'Unknown User';

      // For B2B users, show company_name or status as subtitle
      subtitle = item['company_name'] ?? item['status'];
      final photoPath = item['photo_url'];
      imageUrl = _buildImageUrl(photoPath, isB2G: false);
    } else {
      // Gov entity fields
      name = item['name'] ?? 'Unknown Entity';
      final logoPath = item['logo_url'];
      imageUrl = _buildImageUrl(logoPath, isB2G: true);
    }

    final itemId = item['id'];

    return GestureDetector(
      onTap: () {
        if (_isB2B) {
          // Navigate to B2B meeting request page
          context.push(
            '/events/${widget.eventId}/meetings/new/$itemId',
            extra: item,
          );
        } else {
          // Navigate to B2G meeting request page
          context.push(
            '/events/${widget.eventId}/meetings/b2g/new/$itemId',
            extra: item,
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Column(
            children: [
              // Photo section - full bleed, no border radius, cover all space
              Expanded(
                flex: 70,
                child: Container(
                  width: double.infinity,
                  color: Colors.grey[200],
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildPhotoPlaceholder(),
                        )
                      : _buildPhotoPlaceholder(),
                ),
              ),
              // Name section (bottom 30%)
              Expanded(
                flex: 30,
                child: Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E1E1E),
                        ),
                      ),
                      if (subtitle != null && subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          _isB2B ? Icons.person : Icons.account_balance,
          size: 64,
          color: Colors.grey[400],
        ),
      ),
    );
  }
}
