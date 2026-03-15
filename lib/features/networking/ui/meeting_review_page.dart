import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_snackbar.dart';
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
        final eventId = int.tryParse(widget.eventId);
        if (eventId != null) ref.invalidate(myMeetingsProvider(eventId));
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
        final eventId = int.tryParse(widget.eventId);
        if (eventId != null) ref.invalidate(myMeetingsProvider(eventId));
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button + title row
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 24),
                onPressed: () => context.pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              Text(
                'Meeting Request',
                style: GoogleFonts.montserrat(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildContent(),
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
              _buildSenderInfoCard(
                requesterName: requesterName,
                company: requesterCompany,
                logoUrl: logoUrl,
              ),
              const SizedBox(width: 30),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: Offset.zero,
                      ),
                    ],
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
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: Offset.zero,
                    ),
                  ],
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
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: Offset.zero,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 142,
            height: 142,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: logoUrl.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      logoUrl,
                      width: 142,
                      height: 142,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.person,
                        size: 60,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  )
                : Icon(Icons.person, size: 60, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            requesterName,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          if (company.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.business, size: 16, color: Color(0xFF747474)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    company,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF747474),
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
        const Divider(color: Color(0xFFCACACA), thickness: 0.5, height: 32),
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
        const Divider(color: Color(0xFFCACACA), thickness: 0.5, height: 32),
        _buildReadOnlyField('Location:', location),
        if (message.isNotEmpty) ...[
          const Divider(color: Color(0xFFCACACA), thickness: 0.5, height: 32),
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
            fontSize: 18,
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
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  value.isEmpty ? '-' : value,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
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
    final buttonWidth = isMobile ? 300.0 : 183.0;
    final buttonHeight = isMobile ? 33.0 : 43.0;

    if (isMobile) {
      return Column(
        children: [
          SizedBox(
            width: buttonWidth,
            height: buttonHeight,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _confirmMeeting,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.zero,
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
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: buttonWidth,
            height: buttonHeight,
            child: OutlinedButton(
              onPressed: _isProcessing ? null : _declineMeeting,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFCA0000),
                side: const BorderSide(color: Color(0xFFCA0000), width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.zero,
              ),
              child: Text(
                'Decline',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFCA0000),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: buttonWidth,
          height: buttonHeight,
          child: OutlinedButton(
            onPressed: _isProcessing ? null : _declineMeeting,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFCA0000),
              side: const BorderSide(color: Color(0xFFCA0000), width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.zero,
            ),
            child: Text(
              'Decline',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFCA0000),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: buttonWidth,
          height: buttonHeight,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _confirmMeeting,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.zero,
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
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
