import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../auth/services/auth_service.dart';

/// My Participants - Responsive design with Figma specifications
class MyParticipantsPage extends StatefulWidget {
  final int eventId;

  const MyParticipantsPage({super.key, required this.eventId});

  @override
  State<MyParticipantsPage> createState() => _MyParticipantsPageState();
}

class _MyParticipantsPageState extends State<MyParticipantsPage> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _participants = [];
  int _totalSlots = 10;
  int _usedSlots = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isAdministrator = true; // Default to true for safety;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _loadParticipants();
  }

  void _checkUserRole() {
    final authService = context.read<AuthService>();
    final user = authService.currentUser;
    if (user != null) {
      final roles = List<String>.from(user['roles'] ?? []);
      // Administrator if doesn't have PARTICIPANT role, or has USER/ADMIN role
      _isAdministrator =
          !roles.contains('PARTICIPANT') ||
          roles.contains('USER') ||
          roles.contains('ADMIN');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadParticipants() async {
    try {
      final authService = context.read<AuthService>();
      final token = await authService.getToken();

      final response = await http.get(
        Uri.parse(
          '${AppConfig.b2cApiBaseUrl}/api/v1/participants/my-participants?event_id=${widget.eventId}',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> participantsList =
            responseData['participants'] ?? [];
        final Map<String, dynamic> slotsData = responseData['slots'] ?? {};

        setState(() {
          _participants = participantsList.cast<Map<String, dynamic>>();
          _totalSlots = slotsData['total'] ?? 0;
          _usedSlots = slotsData['used'] ?? _participants.length;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load participants';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredParticipants {
    if (_searchQuery.isEmpty) return _participants;

    return _participants.where((p) {
      final name = '${p['first_name']} ${p['last_name']}'.toLowerCase();
      final email = (p['email'] as String? ?? '').toLowerCase();
      final company = (p['company_name'] as String? ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();

      return name.contains(query) ||
          email.contains(query) ||
          company.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3C4494),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 1200;
            final isTablet =
                constraints.maxWidth >= 768 && constraints.maxWidth < 1200;
            final isMobile = constraints.maxWidth < 768;

            return Column(
              children: [
                _buildHeader(
                  constraints.maxWidth,
                  isDesktop,
                  isTablet,
                  isMobile,
                ),
                SizedBox(height: isDesktop ? 40 : 20),
                _buildSearchBar(
                  constraints.maxWidth,
                  isDesktop,
                  isTablet,
                  isMobile,
                ),
                SizedBox(height: isDesktop ? 40 : 20),
                Expanded(
                  child: _buildContent(
                    constraints.maxWidth,
                    isDesktop,
                    isTablet,
                    isMobile,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(
    double width,
    bool isDesktop,
    bool isTablet,
    bool isMobile,
  ) {
    final horizontalPadding = isDesktop ? 50.0 : (isTablet ? 30.0 : 20.0);
    final titleSize = isDesktop ? 40.0 : (isTablet ? 32.0 : 24.0);
    final buttonHeight = isDesktop ? 67.0 : (isTablet ? 56.0 : 48.0);
    final buttonFontSize = isDesktop ? 26.0 : (isTablet ? 22.0 : 18.0);
    final buttonPaddingH = isDesktop ? 53.0 : (isTablet ? 40.0 : 30.0);
    final buttonPaddingV = isDesktop ? 17.0 : (isTablet ? 14.0 : 12.0);

    if (isMobile) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          20,
          horizontalPadding,
          0,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.menu, color: Color(0xFFF1F1F6)),
                  iconSize: 28,
                  onPressed: () => context.go('/events/${widget.eventId}/menu'),
                ),
                Text(
                  'My participants',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w600,
                    fontSize: titleSize,
                    color: const Color(0xFFF1F1F6),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: buttonHeight,
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: buttonPaddingV,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '$_usedSlots/$_totalSlots',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w700,
                          fontSize: buttonFontSize,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Only show Add button for administrators
                if (_isAdministrator)
                  Expanded(
                    child: SizedBox(
                      height: buttonHeight,
                      child: ElevatedButton(
                        onPressed: _navigateToAddParticipant,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: buttonPaddingH * 0.7,
                            vertical: buttonPaddingV,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Add new',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w600,
                            fontSize: buttonFontSize,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 50, horizontalPadding, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(color: Colors.transparent),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.menu, color: Color(0xFFF1F1F6), size: 32),
              onPressed: () => context.go('/events/${widget.eventId}/menu'),
            ),
          ),
          Text(
            'My participants',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w600,
              fontSize: titleSize,
              color: const Color(0xFFF1F1F6),
            ),
          ),
          Container(
            height: buttonHeight,
            padding: EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: buttonPaddingV,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$_usedSlots/$_totalSlots',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w700,
                  fontSize: buttonFontSize,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          // Only show Add button for administrators
          if (_isAdministrator)
            SizedBox(
              height: buttonHeight,
              child: ElevatedButton(
                onPressed: _navigateToAddParticipant,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: buttonPaddingH,
                    vertical: buttonPaddingV,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Add new',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w600,
                    fontSize: buttonFontSize,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(
    double width,
    bool isDesktop,
    bool isTablet,
    bool isMobile,
  ) {
    final horizontalPadding = isDesktop ? 50.0 : (isTablet ? 30.0 : 20.0);
    final height = isDesktop ? 64.0 : (isTablet ? 56.0 : 48.0);
    final iconSize = isDesktop ? 36.0 : (isTablet ? 32.0 : 28.0);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Container(
        height: height,
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 24 : 16,
          vertical: isDesktop ? 14 : 10,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F1F6).withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: const Color(0xFFF1F1F6), size: iconSize),
            const SizedBox(width: 20),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                style: const TextStyle(color: Color(0xFFF1F1F6), fontSize: 16),
                decoration: const InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(color: Color(0xFFF1F1F6)),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    double width,
    bool isDesktop,
    bool isTablet,
    bool isMobile,
  ) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.white70),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadParticipants,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_participants.isEmpty) {
      return _buildEmptyState();
    }

    final filtered = _filteredParticipants;

    if (filtered.isEmpty) {
      return const Center(
        child: Text(
          'No participants found',
          style: TextStyle(color: Colors.white70, fontSize: 18),
        ),
      );
    }

    final horizontalPadding = isDesktop ? 50.0 : (isTablet ? 30.0 : 20.0);

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      itemCount: filtered.length,
      itemBuilder: (context, index) => _buildParticipantCard(
        filtered[index],
        index + 1,
        width,
        isDesktop,
        isTablet,
        isMobile,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.person_add_outlined,
            size: 80,
            color: Colors.white54,
          ),
          const SizedBox(height: 24),
          const Text(
            'No participants added yet',
            style: TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'You have $_totalSlots available slots',
            style: const TextStyle(fontSize: 18, color: Colors.white70),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _navigateToAddParticipant,
            icon: const Icon(Icons.add),
            label: const Text('Add your first participant'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantCard(
    Map<String, dynamic> participant,
    int index,
    double width,
    bool isDesktop,
    bool isTablet,
    bool isMobile,
  ) {
    final visaStatus = participant['visa_status'] as String? ?? 'FILL_OUT';
    final visaColor = participant['visa_button_color'] as String? ?? '#E8E84F';
    final visaLabel = participant['visa_button_label'] as String? ?? 'Fill out';
    final role = participant['role'] as String? ?? 'Administrator';

    if (isMobile) {
      return _buildMobileCard(
        participant,
        index,
        visaStatus,
        visaColor,
        visaLabel,
        role,
      );
    }

    // Desktop/Tablet card with headers at top
    final cardHeight = isDesktop ? 305.0 : 280.0;
    final photoWidth = isDesktop ? 150.0 : 130.0;
    final photoHeight = isDesktop ? 260.0 : 230.0; // Bigger photo
    final photoLeft = isDesktop ? 65.0 : 50.0;
    final photoTop = isDesktop ? 25.0 : 30.0; // Less top padding

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      height: cardHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Number badge
          Positioned(
            left: 15,
            top: 15,
            child: Container(
              width: 39,
              height: 39,
              decoration: const BoxDecoration(
                color: Color(0xFF3C4494),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '$index',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // Photo (bigger with less top padding)
          Positioned(
            left: photoLeft,
            top: photoTop,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: photoWidth,
                height: photoHeight,
                decoration: const BoxDecoration(color: Color(0xFF9CA4CC)),
                child: participant['profile_photo_url'] != null
                    ? Image.network(
                        participant['profile_photo_url'],
                        width: photoWidth,
                        height: photoHeight,
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.person, size: 80, color: Colors.white),
              ),
            ),
          ),
          // Participant info
          Positioned(
            left: isDesktop ? 266 : 220,
            top: isDesktop ? 58 : 50,
            right: isDesktop ? 600 : 450,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Role:', role),
                const SizedBox(height: 8),
                _buildInfoRow('Name:', participant['first_name'] ?? ''),
                const SizedBox(height: 8),
                _buildInfoRow('Surname:', participant['last_name'] ?? ''),
                const SizedBox(height: 8),
                _buildInfoRow('Company:', participant['company_name'] ?? ''),
                const SizedBox(height: 8),
                _buildInfoRow('Phone:', participant['mobile'] ?? ''),
              ],
            ),
          ),
          // Visa Section (Divider + Header + Button)
          Positioned(
            left: isDesktop ? 756 : 650,
            width: isDesktop ? 273 : 200,
            top: 0,
            bottom: 0,
            child: Row(
              children: [
                // Divider
                Container(
                  width: 2,
                  margin: const EdgeInsets.symmetric(vertical: 68),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.1),
                        Colors.black.withValues(alpha: 0.5),
                        Colors.black.withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                ),
                // Content
                Expanded(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Header
                      const Text(
                        'Visa',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: 25,
                          color: Colors.black,
                        ),
                      ),
                      // Button (Centered)
                      Expanded(
                        child: Center(
                          child: GestureDetector(
                            onTap: () =>
                                _handleVisaAction(visaStatus, participant),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 33,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: _parseColor(visaColor),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                visaLabel,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 20,
                                  color: visaStatus == 'FILL_OUT'
                                      ? Colors.black
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Role Section (Divider + Header + Value)
          Positioned(
            left: isDesktop ? 1029 : 850,
            right: 0,
            top: 0,
            bottom: 0,
            child: Row(
              children: [
                // Divider
                Container(
                  width: 2,
                  margin: const EdgeInsets.symmetric(vertical: 68),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.1),
                        Colors.black.withValues(alpha: 0.5),
                        Colors.black.withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                ),
                // Content
                Expanded(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Header
                      const Text(
                        'Role',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: 25,
                          color: Colors.black,
                        ),
                      ),
                      // Value (Centered)
                      Expanded(
                        child: Center(
                          child: Text(
                            role,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              fontSize: 20,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // More menu - only for administrators
          if (_isAdministrator)
            Positioned(
              right: 15,
              top: 15,
              child: Container(
                width: 39,
                height: 39,
                decoration: const BoxDecoration(
                  color: Color(0xFF3C4494),
                  shape: BoxShape.circle,
                ),
                child: PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: Colors.white,
                    size: 24,
                  ),
                  onSelected: (value) => _handleMenuAction(value, participant),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 8,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20, color: Color(0xFF3C4494)),
                          SizedBox(width: 12),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMobileCard(
    Map<String, dynamic> participant,
    int index,
    String visaStatus,
    String visaColor,
    String visaLabel,
    String role,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Number badge
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFF3C4494),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$index',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              // More menu - only for administrators
              if (_isAdministrator)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 24),
                  onSelected: (value) => _handleMenuAction(value, participant),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20, color: Color(0xFF3C4494)),
                          SizedBox(width: 12),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 100,
                  height: 133,
                  color: const Color(0xFF9CA4CC),
                  child: participant['profile_photo_url'] != null
                      ? Image.network(
                          participant['profile_photo_url'],
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.person, size: 50, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMobileInfoRow('Role:', role),
                    const SizedBox(height: 4),
                    _buildMobileInfoRow(
                      'Name:',
                      participant['first_name'] ?? '',
                    ),
                    const SizedBox(height: 4),
                    _buildMobileInfoRow(
                      'Surname:',
                      participant['last_name'] ?? '',
                    ),
                    const SizedBox(height: 4),
                    _buildMobileInfoRow(
                      'Company:',
                      participant['company_name'] ?? '',
                    ),
                    const SizedBox(height: 4),
                    _buildMobileInfoRow('Phone:', participant['mobile'] ?? ''),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      'Visa',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _handleVisaAction(visaStatus, participant),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _parseColor(visaColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          visaLabel,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: visaStatus == 'FILL_OUT'
                                ? Colors.black
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 50, color: Colors.grey[300]),
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      'Role',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      role,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              fontSize: 20,
              color: Colors.black,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFFE8E84F);
    }
  }

  void _handleVisaAction(String status, Map<String, dynamic> participant) {
    final participantId = participant['id'];
    String route;

    switch (status) {
      case 'FILL_OUT':
      case 'NOT_STARTED':
        route = '/events/${widget.eventId}/visa/form/$participantId';
        break;
      case 'PENDING':
        route = '/events/${widget.eventId}/visa/status/$participantId';
        break;
      case 'APPROVED':
      case 'DECLINED':
        route = '/events/${widget.eventId}/visa/details/$participantId';
        break;
      default:
        route = '/events/${widget.eventId}/visa/form/$participantId';
    }

    context.push(route).then((result) {
      _loadParticipants();
    });
  }

  void _handleMenuAction(
    String action,
    Map<String, dynamic> participant,
  ) async {
    switch (action) {
      case 'edit':
        _editParticipant(participant);
        break;
      case 'delete':
        await _deleteParticipant(participant);
        break;
    }
  }

  void _editParticipant(Map<String, dynamic> participant) {
    context.push(
      '/events/${widget.eventId}/participants/edit/${participant['id']}',
    ).then((result) {
      if (result == true || result == null) {
        _loadParticipants();
      }
    });
  }

  Future<void> _deleteParticipant(Map<String, dynamic> participant) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Participant'),
        content: Text(
          'Are you sure you want to delete ${participant['first_name']} ${participant['last_name']}?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      if (!mounted) return;
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = await authService.getToken();

      final response = await http.delete(
        Uri.parse(
          '${AppConfig.b2cApiBaseUrl}/api/v1/participants/${participant['id']}',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 204 && mounted) {
        setState(() {
          _participants.removeWhere((p) => p['id'] == participant['id']);
          _usedSlots = _participants.length;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Participant deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        throw Exception('Failed to delete participant');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToAddParticipant() {
    if (_usedSlots >= _totalSlots) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Slot Limit Reached'),
          content: Text(
            'You have used all $_totalSlots available participant slots.\n\nPlease purchase additional packages to add more participants.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    context.push('/participants/add?event_id=${widget.eventId}').then((result) {
      if (result == true || result == null) {
        _loadParticipants();
      }
    });
  }
}
