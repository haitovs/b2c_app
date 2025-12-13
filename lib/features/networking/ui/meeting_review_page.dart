import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/services/event_context_service.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../events/ui/widgets/profile_dropdown.dart';
import '../../notifications/ui/notification_drawer.dart';

/// Meeting Review Page - for viewing and approving/declining incoming meeting requests
/// Used when viewing a meeting that was sent to the current user
class MeetingReviewPage extends ConsumerStatefulWidget {
  final String eventId;
  final String meetingId;
  final Map<String, dynamic>? meetingData;

  const MeetingReviewPage({
    super.key,
    required this.eventId,
    required this.meetingId,
    this.meetingData,
  });

  @override
  ConsumerState<MeetingReviewPage> createState() => _MeetingReviewPageState();
}

class _MeetingReviewPageState extends ConsumerState<MeetingReviewPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isProfileOpen = false;

  // Data
  Map<String, dynamic>? _meeting;
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    if (widget.meetingData != null) {
      _meeting = widget.meetingData;
      _isLoading = false;
    } else {
      _fetchMeeting();
    }
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

  Future<void> _fetchMeeting() async {
    try {
      final siteId = eventContextService.siteId;
      var uriString =
          '${AppConfig.tourismApiBaseUrl}/meetings/${widget.meetingId}';
      if (siteId != null) {
        uriString += '?site_id=$siteId';
      }

      final response = await http.get(Uri.parse(uriString));
      if (response.statusCode == 200) {
        setState(() {
          _meeting = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching meeting: $e');
      setState(() => _isLoading = false);

      // For demo purposes, use mock data
      setState(() {
        _meeting = {
          'id': int.parse(widget.meetingId),
          'subject': 'Marketing Campaign Brainstorm',
          'scheduled_date': '2025-05-20',
          'scheduled_time': '13:30',
          'location': 'Ashgabat, TKM',
          'status': 'pending',
          'requester': {'id': 1, 'name': 'Balkan Tour', 'logo': null},
        };
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmMeeting() async {
    setState(() => _isProcessing = true);

    try {
      // TODO: Implement API call to approve meeting
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meeting confirmed!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to confirm: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _declineMeeting() async {
    // Show confirmation dialog first
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline Meeting'),
        content: const Text(
          'Are you sure you want to decline this meeting request?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Decline'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);

    try {
      // TODO: Implement API call to decline meeting
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meeting declined'),
            backgroundColor: Colors.orange,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to decline: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  String _buildImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';
    if (imagePath.startsWith('http')) return imagePath;
    return '${AppConfig.tourismApiBaseUrl}$imagePath';
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
                  // Header
                  _buildHeader(),
                  const SizedBox(height: 20),
                  // Content
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F1F6),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : SingleChildScrollView(
                              padding: const EdgeInsets.all(30),
                              child: _buildContent(),
                            ),
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
            'Meeting',
            style: GoogleFonts.montserrat(
              fontSize: 32,
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

  Widget _buildContent() {
    final meeting = _meeting;
    if (meeting == null) {
      return const Center(child: Text('Meeting not found'));
    }

    final requester = meeting['requester'] as Map<String, dynamic>?;
    final requesterName = requester?['name'] ?? 'Unknown Company';
    final requesterLogo = requester?['logo'];
    final logoUrl = _buildImageUrl(requesterLogo);

    final subject = meeting['subject'] ?? '';
    final date = meeting['scheduled_date'] ?? '';
    final time = meeting['scheduled_time'] ?? '';
    final location = meeting['location'] ?? '';

    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;

          if (isWide) {
            // Desktop layout
            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left side - Requester image
                    SizedBox(
                      width: 250,
                      height: 300,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: logoUrl.isNotEmpty
                            ? Image.network(
                                logoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildImagePlaceholder(requesterName),
                              )
                            : _buildImagePlaceholder(requesterName),
                      ),
                    ),
                    const SizedBox(width: 40),
                    // Right side - Meeting details
                    Expanded(
                      child: _buildMeetingDetails(
                        subject: subject,
                        date: date,
                        time: time,
                        location: location,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                // Action buttons
                _buildActionButtons(),
              ],
            );
          } else {
            // Mobile layout
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Requester image
                SizedBox(
                  height: 200,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: logoUrl.isNotEmpty
                        ? Image.network(
                            logoUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildImagePlaceholder(requesterName),
                          )
                        : _buildImagePlaceholder(requesterName),
                  ),
                ),
                const SizedBox(height: 24),
                // Meeting details
                _buildMeetingDetails(
                  subject: subject,
                  date: date,
                  time: time,
                  location: location,
                ),
                const SizedBox(height: 30),
                // Action buttons
                _buildActionButtons(),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildMeetingDetails({
    required String subject,
    required String date,
    required String time,
    required String location,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text(
          'Information',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 24),
        // Subject and Date row
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 400) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildReadOnlyField('Subjects:', subject)),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildReadOnlyField('Date:', date, hasIcon: true),
                  ),
                ],
              );
            } else {
              return Column(
                children: [
                  _buildReadOnlyField('Subjects:', subject),
                  const SizedBox(height: 16),
                  _buildReadOnlyField('Date:', date, hasIcon: true),
                ],
              );
            }
          },
        ),
        const SizedBox(height: 16),
        // Time and Location row
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 400) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildReadOnlyField('Time:', time)),
                  const SizedBox(width: 20),
                  Expanded(child: _buildReadOnlyField('Location:', location)),
                ],
              );
            } else {
              return Column(
                children: [
                  _buildReadOnlyField('Time:', time),
                  const SizedBox(height: 16),
                  _buildReadOnlyField('Location:', location),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(
    String label,
    String value, {
    bool hasIcon = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFB7B7B7)),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  value.isEmpty ? '-' : value,
                  style: const TextStyle(fontSize: 16, color: Colors.black),
                ),
              ),
              if (hasIcon)
                Icon(
                  Icons.calendar_today_outlined,
                  size: 20,
                  color: Colors.grey[600],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Decline button
        OutlinedButton(
          onPressed: _isProcessing ? null : _declineMeeting,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
          ),
          child: Text(
            'Decline',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(width: 20),
        // Confirm button
        ElevatedButton(
          onPressed: _isProcessing ? null : _confirmMeeting,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF008000),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
          ),
          child: _isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'Confirm',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder(String name) {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
