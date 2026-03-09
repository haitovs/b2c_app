import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../events/ui/widgets/profile_dropdown.dart';
import '../../notifications/ui/notification_drawer.dart';
import '../providers/meeting_providers.dart';
import '../services/meeting_service.dart';

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
      final meetingService = ref.read(meetingServiceProvider);
      final data = await meetingService.fetchMeeting(widget.meetingId);
      if (mounted) {
        setState(() {
          _meeting = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching meeting: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmMeeting() async {
    setState(() => _isProcessing = true);

    try {
      final meetingService = ref.read(meetingServiceProvider);

      await meetingService.updateMeetingStatus(
        meetingId: widget.meetingId,
        status: MeetingStatus.confirmed,
      );

      if (mounted) {
        AppSnackBar.showSuccess(context, 'Meeting confirmed!');
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Failed to confirm: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _declineMeeting() async {
    // Capture context-dependent values before any async gap
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
      final meetingService = ref.read(meetingServiceProvider);

      await meetingService.updateMeetingStatus(
        meetingId: widget.meetingId,
        status: MeetingStatus.declined,
      );

      if (mounted) {
        AppSnackBar.showWarning(context, 'Meeting declined');
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Failed to decline: $e');
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
    return imagePath;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final horizontalMargin = isMobile ? 10.0 : 20.0;
    final contentPadding = isMobile ? 16.0 : 30.0;

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
                  _buildHeader(isMobile),
                  SizedBox(height: isMobile ? 10 : 20),
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: horizontalMargin,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F1F6),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : SingleChildScrollView(
                              padding: EdgeInsets.all(contentPadding),
                              child: _buildContent(),
                            ),
                    ),
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

  Widget _buildHeader(bool isMobile) {
    return Padding(
      padding: EdgeInsets.only(
        left: isMobile ? 12 : 20,
        right: isMobile ? 12 : 20,
        top: isMobile ? 12 : 20,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
            onPressed: () => context.pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          SizedBox(width: isMobile ? 4 : 8),
          Flexible(
            child: Text(
              'Request',
              style: GoogleFonts.montserrat(
                fontSize: isMobile ? 20 : 28,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Spacer(),
          CustomAppBar(
            onNotificationTap: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
            onProfileTap: _toggleProfile,
            isMobile: isMobile,
            showLogo: false,
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

    // Use requester_info from the API response (for incoming meetings)
    final requesterInfo = meeting['requester_info'] as Map<String, dynamic>?;
    final firstName = requesterInfo?['first_name'] ?? '';
    final lastName = requesterInfo?['last_name'] ?? '';
    final requesterName = '$firstName $lastName'.trim().isNotEmpty
        ? '$firstName $lastName'.trim()
        : 'Unknown Sender';
    final requesterLogo = requesterInfo?['photo_url'];
    final logoUrl = _buildImageUrl(requesterLogo);
    final requesterCompany = requesterInfo?['company_name'] ?? '';

    final subject = meeting['subject'] ?? '';
    final message = meeting['message'] ?? '';
    // Parse start_time/end_time instead of scheduled_date/scheduled_time
    final startTime = meeting['start_time']?.toString() ?? '';
    final date = _formatDate(startTime);
    final time = _formatTime(startTime);
    final location = meeting['location'] ?? '';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Sender personal info card
              _buildSenderInfoCard(
                requesterName: requesterName,
                company: requesterCompany,
                logoUrl: logoUrl,
              ),
              const SizedBox(width: 30),
              // Right: Meeting details + action buttons
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
                      Text(
                        'Meeting information',
                        style: GoogleFonts.montserrat(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildMeetingDetails(
                        subject: subject,
                        date: date,
                        time: time,
                        location: location,
                        message: message,
                      ),
                      const SizedBox(height: 32),
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSenderInfoCard(
                requesterName: requesterName,
                company: requesterCompany,
                logoUrl: logoUrl,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Meeting information',
                      style: GoogleFonts.montserrat(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildMeetingDetails(
                      subject: subject,
                      date: date,
                      time: time,
                      location: location,
                      message: message,
                    ),
                    const SizedBox(height: 24),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildSenderInfoCard({
    required String requesterName,
    required String company,
    required String logoUrl,
  }) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 288),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Photo/Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: logoUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      logoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.person,
                        size: 40,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  )
                : Icon(Icons.person, size: 40, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            requesterName,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1A1A2E),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          if (company.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.business, size: 16, color: Color(0xFF6B7280)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    company,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6B7280),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMeetingDetails({
    required String subject,
    required String date,
    required String time,
    required String location,
    String message = '',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildReadOnlyField('Subject:', subject),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 400) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildReadOnlyField('Date:', date, hasIcon: true),
                  ),
                  const SizedBox(width: 20),
                  Expanded(child: _buildReadOnlyField('Time:', time)),
                ],
              );
            } else {
              return Column(
                children: [
                  _buildReadOnlyField('Date:', date, hasIcon: true),
                  const SizedBox(height: 16),
                  _buildReadOnlyField('Time:', time),
                ],
              );
            }
          },
        ),
        const SizedBox(height: 16),
        _buildReadOnlyField('Location:', location),
        if (message.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildReadOnlyField('Message:', message),
        ],
      ],
    );
  }

  String _formatDate(String? dateTime) {
    if (dateTime == null || dateTime.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(dateTime);
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return dateTime;
    }
  }

  String _formatTime(String? dateTime) {
    if (dateTime == null || dateTime.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(dateTime);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateTime;
    }
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
    final isMobile = MediaQuery.of(context).size.width < 600;
    final buttonPadding = isMobile
        ? const EdgeInsets.symmetric(horizontal: 24, vertical: 12)
        : const EdgeInsets.symmetric(horizontal: 40, vertical: 14);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: OutlinedButton(
            onPressed: _isProcessing ? null : _declineMeeting,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF374151),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              padding: buttonPadding,
            ),
            child: Text(
              'Decline',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _confirmMeeting,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              padding: buttonPadding,
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
        ),
      ],
    );
  }

}
