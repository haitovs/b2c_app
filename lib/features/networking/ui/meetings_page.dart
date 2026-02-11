import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart' as legacy_provider;

import '../../../core/config/app_config.dart';
import '../../../core/models/api_exception.dart';
import '../../../core/services/event_context_service.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../auth/services/auth_service.dart';
import '../../events/ui/widgets/profile_dropdown.dart';
import '../../notifications/services/notification_service.dart';
import '../../notifications/ui/notification_drawer.dart';
import 'widgets/delete_confirmation_dialog.dart';

/// Main Meeting Page - Shows list of user's scheduled meetings
class MeetingsPage extends ConsumerStatefulWidget {
  final String eventId;

  const MeetingsPage({super.key, required this.eventId});

  @override
  ConsumerState<MeetingsPage> createState() => _MeetingsPageState();
}

class _MeetingsPageState extends ConsumerState<MeetingsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isProfileOpen = false;

  // B2B/B2G toggle
  bool _isB2B = true;

  // Filter chips
  String _selectedFilter =
      'all'; // all, sent, incoming, approved, pending, declined

  // Search
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Day tabs
  List<Map<String, dynamic>> _agendaDays = [];
  int _selectedDayIndex = 0;

  // Meetings data
  List<Map<String, dynamic>> _meetings = [];
  List<Map<String, dynamic>> _filteredMeetings = [];
  bool _isLoading = true;

  // Notification count
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeAndFetch();
    _loadNotificationCount();
  }

  Future<void> _loadNotificationCount() async {
    try {
      final authService = legacy_provider.Provider.of<AuthService>(
        context,
        listen: false,
      );
      final notificationService = NotificationService(authService);
      final notifications = await notificationService.getNotifications();
      if (mounted) {
        setState(() {
          _unreadNotificationCount = notifications
              .where((n) => !n.isRead)
              .length;
        });
      }
    } catch (e) {
      // Silently fail - notification count is not critical
    }
  }

  Future<void> _initializeAndFetch() async {
    // Ensure the event context is loaded for this event
    final eventId = int.tryParse(widget.eventId);
    if (eventId != null) {
      await eventContextService.ensureEventContext(eventId);
    }
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleProfile() {
    setState(() => _isProfileOpen = !_isProfileOpen);
  }

  void _closeProfile() {
    if (_isProfileOpen) {
      setState(() => _isProfileOpen = false);
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

      // Fetch meetings from B2C backend - filtered by event_id
      final eventId = widget.eventId;
      debugPrint('Fetching meetings for event_id=$eventId');
      final meetingsResponse = await http.get(
        Uri.parse(
          '${AppConfig.b2cApiBaseUrl}/api/v1/meetings?event_id=$eventId',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('Meetings response status: ${meetingsResponse.statusCode}');
      debugPrint('Meetings response body: ${meetingsResponse.body}');

      if (meetingsResponse.statusCode == 200) {
        final List data = jsonDecode(meetingsResponse.body);
        debugPrint('Parsed ${data.length} meetings from response');
        _meetings = data.cast<Map<String, dynamic>>();
      } else {
        debugPrint('Failed to fetch meetings: ${meetingsResponse.statusCode}');
      }

      // Use EventContextService for site_id (already initialized at app startup)
      final tourismSiteId = eventContextService.siteId;

      if (tourismSiteId != null) {
        try {
          final daysResponse = await http.get(
            Uri.parse(
              '${AppConfig.tourismApiBaseUrl}/agenda/days?site_id=$tourismSiteId',
            ),
          );
          if (daysResponse.statusCode == 200) {
            final List daysData = jsonDecode(daysResponse.body);
            _agendaDays = daysData.cast<Map<String, dynamic>>();
          } else {
            debugPrint(
              'Failed to fetch agenda days: ${daysResponse.statusCode}',
            );
          }
        } catch (e) {
          debugPrint('Error fetching agenda days: $e');
        }
      } else {
        debugPrint('Warning: No Tourism site_id available, using mock days');
      }

      if (_agendaDays.isEmpty) {
        _agendaDays = _getMockDays();
      }

      if (_agendaDays.isEmpty) {
        _agendaDays = _getMockDays();
      }

      setState(() {
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching meetings: $e');
      // Use mock data for testing
      _meetings = _getMockMeetings();
      _agendaDays = _getMockDays();
      setState(() {
        _applyFilters();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getMockDays() {
    return [
      {'id': 1, 'date': '2025-05-21', 'day_number': 21, 'day_name': 'Monday'},
      {'id': 2, 'date': '2025-05-22', 'day_number': 22, 'day_name': 'Tuesday'},
      {
        'id': 3,
        'date': '2025-05-23',
        'day_number': 23,
        'day_name': 'Wednesday',
      },
    ];
  }

  List<Map<String, dynamic>> _getMockMeetings() {
    return [
      {
        'id': '1',
        'type': 'B2B',
        'status': 'CONFIRMED',
        'subject': 'Marketing Campaign Brainstorm',
        'company_name': 'SilverPeak Innovations',
        'position': 'Marketing Data Analyst',
        'start_time': '2025-05-21T13:30:00',
        'location': 'Ashgabat, TKM',
        'image_url': null,
      },
      {
        'id': '2',
        'type': 'B2B',
        'status': 'CONFIRMED',
        'subject': 'Product Demo Discussion',
        'company_name': 'TechVentures Inc',
        'position': 'Product Manager',
        'start_time': '2025-05-21T15:00:00',
        'location': 'Ashgabat, TKM',
        'image_url': null,
      },
      {
        'id': '3',
        'type': 'B2B',
        'status': 'PENDING',
        'subject': 'Partnership Proposal',
        'company_name': 'Global Trade Co',
        'position': 'Business Developer',
        'start_time': '2025-05-22T10:00:00',
        'location': 'Ashgabat, TKM',
        'image_url': null,
      },
    ];
  }

  void _applyFilters() {
    List<Map<String, dynamic>> result = List.from(_meetings);

    // Filter by B2B/B2G type
    final typeFilter = _isB2B ? 'B2B' : 'B2G';
    result = result.where((m) => m['type'] == typeFilter).toList();

    // Filter by direction (sent/incoming)
    if (_selectedFilter == 'sent') {
      result = result.where((m) => m['is_sender'] == true).toList();
    } else if (_selectedFilter == 'incoming') {
      result = result.where((m) => m['is_sender'] == false).toList();
    } else if (_selectedFilter != 'all') {
      // Filter by status
      final statusMap = {
        'approved': 'CONFIRMED',
        'pending': 'PENDING',
        'declined': 'DECLINED',
      };
      result = result
          .where((m) => m['status'] == statusMap[_selectedFilter])
          .toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      result = result.where((m) {
        final company = (m['company_name'] ?? '').toString().toLowerCase();
        final subject = (m['subject'] ?? '').toString().toLowerCase();
        return company.contains(_searchQuery.toLowerCase()) ||
            subject.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Filter by selected day from agenda
    if (_agendaDays.isNotEmpty && _selectedDayIndex < _agendaDays.length) {
      final selectedDay = _agendaDays[_selectedDayIndex];
      final dayDate = selectedDay['date'] as String?;
      if (dayDate != null) {
        result = result.where((m) {
          final startTime = m['start_time'] as String?;
          if (startTime == null) return false;
          return startTime.startsWith(dayDate);
        }).toList();
      }
    }

    setState(() {
      _filteredMeetings = result;
    });
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _applyFilters();
    });
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
      _applyFilters();
    });
  }

  void _onTypeToggleChanged(bool isB2B) {
    setState(() {
      _isB2B = isB2B;
      _applyFilters();
    });
  }

  void _onDaySelected(int index) {
    setState(() {
      _selectedDayIndex = index;
      _applyFilters();
    });
  }

  Future<void> _deleteMeeting(String meetingId) async {
    // Capture context-dependent values before async gap
    final authService = legacy_provider.Provider.of<AuthService>(
      context,
      listen: false,
    );

    final confirmed = await showDeleteConfirmationDialog(context);
    if (!confirmed) return;

    try {
      final token = await authService.getToken();

      // Call API to update status to CANCELLED
      final response = await http.patch(
        Uri.parse(
          '${AppConfig.b2cApiBaseUrl}/api/v1/meetings/$meetingId/status?status_in=CANCELLED',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Refresh the meeting list to get updated data
        await _fetchData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Meeting cancelled successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        debugPrint('Failed to cancel meeting: ${response.statusCode}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ApiException.extractErrorMessage(response.statusCode, response.body)),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error cancelling meeting: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error cancelling meeting'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editMeeting(Map<String, dynamic> meeting) {
    // Navigate to edit page
    context.push(
      '/events/${widget.eventId}/meetings/${meeting['id']}/edit',
      extra: meeting,
    ).then((result) {
      if (result == true) {
        _fetchData();
      }
    });
  }

  Future<void> _respondToMeeting(String meetingId, String action) async {
    try {
      final authService = legacy_provider.Provider.of<AuthService>(
        context,
        listen: false,
      );
      final token = await authService.getToken();

      final response = await http.post(
        Uri.parse(
          '${AppConfig.b2cApiBaseUrl}/api/v1/meetings/$meetingId/respond',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'action': action}),
      );

      if (response.statusCode == 200) {
        final actionLabel = action == 'accept' ? 'accepted' : 'declined';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Meeting $actionLabel successfully'),
              backgroundColor: action == 'accept'
                  ? Colors.green
                  : Colors.orange,
            ),
          );
          // Refresh the meeting list
          _fetchData();
        }
      } else {
        throw Exception(ApiException.extractErrorMessage(response.statusCode, response.body));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF3C4494),
      endDrawer: const NotificationDrawer(),
      floatingActionButton: _buildNewMeetingFAB(),
      body: GestureDetector(
        onTap: _closeProfile,
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 12),
                  _buildTypeToggleRow(),
                  const SizedBox(height: 12),
                  _buildSearchBar(),
                  const SizedBox(height: 12),
                  _buildFiltersRow(),
                  const SizedBox(height: 12),
                  _buildDayTabs(),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                        : _buildMeetingsList(),
                  ),
                ],
              ),
            ),
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
          // Menu/Back button
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
            onPressed: () => context.go('/events/${widget.eventId}/menu'),
          ),
          const SizedBox(width: 8),
          // Title
          Text(
            'Meetings',
            style: GoogleFonts.montserrat(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          // Icons
          CustomAppBar(
            onNotificationTap: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
            onProfileTap: _toggleProfile,
            unreadNotificationCount: _unreadNotificationCount,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeToggleRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Center(child: _buildTypeToggle()),
    );
  }

  Widget _buildTypeToggle() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive sizing
        final isSmall = MediaQuery.of(context).size.width < 600;
        final fontSize = isSmall ? 16.0 : 20.0;
        final horizontalPadding = isSmall ? 20.0 : 40.0;
        final verticalPadding = isSmall ? 8.0 : 12.0;

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => _onTypeToggleChanged(true),
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
              GestureDetector(
                onTap: () => _onTypeToggleChanged(false),
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
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: Colors.white.withValues(alpha: 0.8),
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.roboto(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Search by event name',
                hintStyle: GoogleFonts.roboto(
                  color: Colors.white.withValues(alpha: 0.6),
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

  Widget _buildFiltersRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All', 'all'),
            const SizedBox(width: 8),
            _buildFilterChip('Sent', 'sent'),
            const SizedBox(width: 8),
            _buildFilterChip('Incoming', 'incoming'),
            const SizedBox(width: 8),
            _buildFilterChip('Approved', 'approved'),
            const SizedBox(width: 8),
            _buildFilterChip('Pending', 'pending'),
            const SizedBox(width: 8),
            _buildFilterChip('Declined', 'declined'),
          ],
        ),
      ),
    );
  }

  Widget _buildNewMeetingFAB() {
    return FloatingActionButton.extended(
      onPressed: () async {
        final type = _isB2B ? 'b2b' : 'b2g';
        await context.push('/events/${widget.eventId}/meetings/new?type=$type');
        // Always refresh data when returning from create meeting flow
        if (mounted) {
          _fetchData();
        }
      },
      backgroundColor: const Color(0xFF151A4A),
      icon: const Icon(Icons.add, color: Colors.white),
      label: Text(
        'New',
        style: GoogleFonts.roboto(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => _onFilterChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF151A4A) : const Color(0xFF9CA4CC),
          borderRadius: BorderRadius.circular(42),
        ),
        child: Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildDayTabs() {
    if (_agendaDays.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 55,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _agendaDays.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final day = _agendaDays[index];
          final isSelected = _selectedDayIndex == index;

          // Parse day info from date string or model fields
          int dayNumber;
          String dayName;

          if (day['day_number'] != null) {
            dayNumber = day['day_number'];
          } else if (day['date'] != null) {
            try {
              final date = DateTime.parse(day['date']);
              dayNumber = date.day;
            } catch (e) {
              dayNumber = index + 1;
            }
          } else {
            dayNumber = index + 1;
          }

          if (day['day_name'] != null) {
            dayName = day['day_name'];
          } else if (day['date'] != null) {
            try {
              final date = DateTime.parse(day['date']);
              dayName = _getDayNameFromWeekday(date.weekday);
            } catch (e) {
              dayName = _getDayName(index);
            }
          } else {
            dayName = _getDayName(index);
          }

          return GestureDetector(
            onTap: () => _onDaySelected(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF151A4A) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Text(
                    '$dayNumber',
                    style: GoogleFonts.roboto(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? const Color(0xFFF4F4F2)
                          : const Color(0xFF20306C),
                    ),
                  ),
                  Container(
                    height: 35,
                    width: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    color: isSelected
                        ? const Color(0xFFF4F4F2)
                        : const Color(0xFF20306C),
                  ),
                  Text(
                    dayName,
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: isSelected
                          ? const Color(0xFFF4F4F2)
                          : const Color(0xFF20306C),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getDayName(int index) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
    return days[index % days.length];
  }

  String _getDayNameFromWeekday(int weekday) {
    const weekdays = [
      '', // No 0
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return weekdays[weekday];
  }

  Widget _buildMeetingsList() {
    if (_filteredMeetings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No meetings found',
              style: GoogleFonts.roboto(
                fontSize: 18,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final type = _isB2B ? 'b2b' : 'b2g';
                await context.push(
                  '/events/${widget.eventId}/meetings/new?type=$type',
                );
                // Always refresh when returning
                if (mounted) {
                  _fetchData();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Create New Meeting'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF3C4494),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _filteredMeetings.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _buildMeetingCard(_filteredMeetings[index]);
      },
    );
  }

  Widget _buildMeetingCard(Map<String, dynamic> meeting) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    final status = meeting['status'] ?? 'PENDING';
    final isSender = meeting['is_sender'] ?? true;

    // Role-based status labels
    final statusColor = _getStatusColor(status);
    String statusLabel;
    if (status == 'PENDING') {
      statusLabel = isSender ? 'Awaiting Response' : 'Action Required';
    } else {
      statusLabel = _getStatusLabel(status);
    }

    // Get display info based on role
    String displayName;
    String companyName;
    String? photoUrl;
    final subject = meeting['subject'] ?? 'No subject';

    if (isSender) {
      // OUTGOING: Show target user info
      final targetUser = meeting['target_user'] as Map<String, dynamic>?;
      final firstName = targetUser?['first_name'] ?? '';
      final lastName = targetUser?['last_name'] ?? '';
      final fullName = '$firstName $lastName'.trim();
      displayName = fullName.isNotEmpty ? fullName : 'Unknown';
      companyName = targetUser?['company_name'] ?? 'N/A';

      final rawPhotoUrl = targetUser?['photo_url'];
      if (rawPhotoUrl != null && rawPhotoUrl.toString().isNotEmpty) {
        if (rawPhotoUrl.toString().startsWith('http')) {
          photoUrl = rawPhotoUrl.toString();
        } else {
          photoUrl = '${AppConfig.b2cApiBaseUrl}$rawPhotoUrl';
        }
      }
    } else {
      // INCOMING: Show requester info
      final requesterInfo = meeting['requester_info'] as Map<String, dynamic>?;
      final firstName = requesterInfo?['first_name'] ?? '';
      final lastName = requesterInfo?['last_name'] ?? '';
      final fullName = '$firstName $lastName'.trim();
      displayName = fullName.isNotEmpty ? fullName : 'Unknown Sender';
      companyName = requesterInfo?['company_name'] ?? 'N/A';

      final rawPhotoUrl = requesterInfo?['photo_url'];
      if (rawPhotoUrl != null && rawPhotoUrl.toString().isNotEmpty) {
        if (rawPhotoUrl.toString().startsWith('http')) {
          photoUrl = rawPhotoUrl.toString();
        } else {
          photoUrl = '${AppConfig.b2cApiBaseUrl}$rawPhotoUrl';
        }
      }
    }

    if (isMobile) {
      return _buildMobileMeetingCard(
        meeting: meeting,
        photoUrl: photoUrl,
        displayName: displayName,
        companyName: companyName,
        subject: subject,
        status: status,
        statusColor: statusColor,
        statusLabel: statusLabel,
        isSender: isSender,
      );
    } else {
      return _buildDesktopMeetingCard(
        meeting: meeting,
        photoUrl: photoUrl,
        displayName: displayName,
        companyName: companyName,
        subject: subject,
        status: status,
        statusColor: statusColor,
        statusLabel: statusLabel,
        isSender: isSender,
      );
    }
  }

  /// Mobile Meeting Card - 2-row layout
  Widget _buildMobileMeetingCard({
    required Map<String, dynamic> meeting,
    required String? photoUrl,
    required String displayName,
    required String companyName,
    required String subject,
    required String status,
    required Color statusColor,
    required String statusLabel,
    required bool isSender,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Row 1: Photo | Data Column | Status & Menu
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo - 1:1 square
                _buildPhoto(photoUrl, displayName, 80),
                const SizedBox(width: 14),
                // Data column (date, location, time)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMobileInfoChip(
                        'assets/meeting/date.png',
                        _formatDate(meeting['start_time']),
                      ),
                      const SizedBox(height: 8),
                      _buildMobileInfoChip(
                        'assets/meeting/location.png',
                        meeting['location'] ?? 'TBD',
                      ),
                      const SizedBox(height: 8),
                      _buildMobileInfoChip(
                        'assets/meeting/time.png',
                        _formatTime(meeting['start_time']),
                      ),
                    ],
                  ),
                ),
                // Status & 3-dots menu
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        statusLabel,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Menu
                    _buildPopupMenu(meeting),
                  ],
                ),
              ],
            ),
          ),
          // Divider
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: const Color(0xFFE8E8E8),
          ),
          // Row 2: Name & Company & Subject with labels
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 70,
                      child: Text(
                        'Name:',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF374151),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        displayName,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1A1A2E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Company row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 70,
                      child: Text(
                        'Company:',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF374151),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        companyName,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6B7280),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Subject row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 70,
                      child: Text(
                        'Subject:',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF374151),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        subject,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF3C4494),
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
        ],
      ),
    );
  }

  /// Desktop Meeting Card - Bigger photo, larger fonts, horizontal layout
  Widget _buildDesktopMeetingCard({
    required Map<String, dynamic> meeting,
    required String? photoUrl,
    required String displayName,
    required String companyName,
    required String subject,
    required String status,
    required Color statusColor,
    required String statusLabel,
    required bool isSender,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFF3C4494).withValues(alpha: 0.03),
            blurRadius: 40,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Main content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Large Photo - 1:1 square (1.5x bigger = 210)
                _buildPhoto(photoUrl, displayName, 210),
                const SizedBox(width: 32),
                // User Info with labels: Name, Company, Subject
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 100,
                            child: Text(
                              'Name:',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF374151),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              displayName,
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1A1A2E),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Company row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 100,
                            child: Text(
                              'Company:',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF374151),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              companyName,
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF6B7280),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Subject row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 100,
                            child: Text(
                              'Subject:',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF374151),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              subject,
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF3C4494),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 28),
                // Vertical divider (solid)
                Container(
                  width: 3,
                  height: 180,
                  color: const Color(0xFFE5E7EB),
                ),
                const SizedBox(width: 28),
                // Date/Location/Time column
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDesktopInfoRow(
                        'assets/meeting/date.png',
                        _formatDate(meeting['start_time']),
                      ),
                      const SizedBox(height: 18),
                      _buildDesktopInfoRow(
                        'assets/meeting/location.png',
                        meeting['location'] ?? 'TBD',
                      ),
                      const SizedBox(height: 18),
                      _buildDesktopInfoRow(
                        'assets/meeting/time.png',
                        _formatTime(meeting['start_time']),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Status badge & Menu - Top right corner
          Positioned(
            top: 16,
            right: 16,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    statusLabel,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Menu
                _buildPopupMenu(meeting),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoto(String? photoUrl, String displayName, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3C4494).withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.12),
        child: photoUrl != null
            ? Image.network(
                photoUrl,
                fit: BoxFit.cover,
                width: size,
                height: size,
                errorBuilder: (context, error, stackTrace) =>
                    _buildPhotoPlaceholder(displayName, size),
              )
            : _buildPhotoPlaceholder(displayName, size),
      ),
    );
  }

  Widget _buildPhotoPlaceholder(String name, double size) {
    final initials = name
        .split(' ')
        .take(2)
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
        .join();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF3C4494).withValues(alpha: 0.15),
            const Color(0xFF5B6BC0).withValues(alpha: 0.25),
          ],
        ),
      ),
      child: Center(
        child: initials.isNotEmpty
            ? Text(
                initials,
                style: GoogleFonts.inter(
                  fontSize: size * 0.32,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF3C4494),
                ),
              )
            : Icon(
                Icons.person_rounded,
                size: size * 0.45,
                color: const Color(0xFF3C4494).withValues(alpha: 0.5),
              ),
      ),
    );
  }

  Widget _buildMobileInfoChip(String assetPath, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          assetPath,
          width: 20,
          height: 20,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.info_outline, size: 20, color: Colors.grey),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1F2937),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopInfoRow(String assetPath, String text) {
    return Row(
      children: [
        Image.asset(
          assetPath,
          width: 28,
          height: 28,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.info_outline, size: 28, color: Colors.grey),
        ),
        const SizedBox(width: 14),
        Flexible(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF374151),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPopupMenu(Map<String, dynamic> meeting) {
    final isSender = meeting['is_sender'] ?? true;
    final status = (meeting['status'] ?? 'PENDING').toString().toUpperCase();
    final isPending = status == 'PENDING';
    final isConfirmed = status == 'CONFIRMED';

    // Build menu items based on role and status
    final items = <PopupMenuItem<String>>[];

    if (isSender) {
      // SENDER can:
      // - Edit if PENDING
      // - Cancel if PENDING or CONFIRMED
      // - Nothing if CANCELLED or DECLINED
      if (isPending) {
        items.add(
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: const Color(0xFF3C4494),
                ),
                const SizedBox(width: 10),
                Text(
                  'Edit',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        );
      }
      if (isPending || isConfirmed) {
        items.add(
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                const Icon(Icons.cancel_outlined, size: 18, color: Colors.red),
                const SizedBox(width: 10),
                Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } else {
      // RECIPIENT can:
      // - Accept/Decline if PENDING
      // - Nothing after accepting/declining/cancelled
      if (isPending) {
        items.add(
          PopupMenuItem(
            value: 'accept',
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 18,
                  color: Colors.green,
                ),
                const SizedBox(width: 10),
                Text(
                  'Accept',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        );
        items.add(
          PopupMenuItem(
            value: 'decline',
            child: Row(
              children: [
                const Icon(Icons.cancel_outlined, size: 18, color: Colors.red),
                const SizedBox(width: 10),
                Text(
                  'Decline',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    // If no actions available, show a disabled/hidden button
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: PopupMenuButton<String>(
        icon: const Icon(
          Icons.more_vert_rounded,
          color: Color(0xFF6B7280),
          size: 22,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 8,
        onSelected: (value) {
          switch (value) {
            case 'delete':
              _deleteMeeting(meeting['id'].toString());
              break;
            case 'edit':
              _editMeeting(meeting);
              break;
            case 'accept':
              _respondToMeeting(meeting['id'].toString(), 'accept');
              break;
            case 'decline':
              _respondToMeeting(meeting['id'].toString(), 'decline');
              break;
          }
        },
        itemBuilder: (context) => items,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMED':
        return const Color(0xFF008000);
      case 'PENDING':
        return const Color(0xFFED873F);
      case 'DECLINED':
        return const Color(0xFFC60404);
      case 'CANCELLED':
        return const Color(0xFF6B7280);
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMED':
        return 'Approved';
      case 'PENDING':
        return 'Pending';
      case 'DECLINED':
        return 'Declined';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String _formatDate(String? dateTime) {
    if (dateTime == null) return 'N/A';
    try {
      final dt = DateTime.parse(dateTime);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatTime(String? dateTime) {
    if (dateTime == null) return 'N/A';
    try {
      final dt = DateTime.parse(dateTime);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }
}
