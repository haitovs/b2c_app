import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/config/app_config.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../providers/meeting_providers.dart';
import '../services/meeting_service.dart';

/// Confirmation page shown after filling in a B2B or B2G meeting request form.
/// Displays a summary of the meeting data and Confirm / Decline buttons.
class MeetingConfirmationPage extends ConsumerStatefulWidget {
  final MeetingType meetingType;
  final Map<String, dynamic> meetingData;

  const MeetingConfirmationPage({
    super.key,
    required this.meetingType,
    required this.meetingData,
  });

  @override
  ConsumerState<MeetingConfirmationPage> createState() =>
      _MeetingConfirmationPageState();
}

class _MeetingConfirmationPageState
    extends ConsumerState<MeetingConfirmationPage> {
  bool _isSubmitting = false;

  bool get _isB2B => widget.meetingType == MeetingType.b2b;

  Map<String, dynamic> get _data => widget.meetingData;

  Future<void> _handleConfirm() async {
    setState(() => _isSubmitting = true);

    try {
      final meetingService = ref.read(meetingServiceProvider);

      await meetingService.createMeeting(
        eventId: _data['event_id'] as int,
        type: widget.meetingType,
        subject: _data['subject'] as String,
        startTime: _data['start_time'] as DateTime,
        endTime: _data['end_time'] as DateTime,
        location: _data['location'] as String?,
        targetUserId: _data['target_user_id'] as String?,
        targetGovEntityId: _data['target_gov_entity_id'] as int?,
        targetOfficialId: _data['target_official_id'] as int?,
        attendeesText: _data['attendees_text'] as String?,
        language: _data['language'] as String?,
        message: _data['message'] as String?,
      );

      if (mounted) {
        // Invalidate cached meetings so the list refetches
        final eventId = _data['event_id'] as int;
        ref.invalidate(myMeetingsProvider(eventId));

        AppSnackBar.showSuccess(context, 'Meeting request sent successfully!');
        context.go('/events/$eventId/meetings');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Failed to send request: $e');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _buildImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';
    if (imagePath.startsWith('http')) return imagePath;
    return '${AppConfig.b2cApiBaseUrl}$imagePath';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Request',
            style: GoogleFonts.montserrat(
              fontSize: 30,
              fontWeight: FontWeight.w600,
              color: AppColors.gradientStart,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(color: Color(0x20000000), blurRadius: 10),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Target info card (person or entity)
                _buildTargetCard(),
                const SizedBox(height: 24),

                // Meeting information section
                Text(
                  'Meeting information',
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                _buildInfoRow('Subject:', _data['subject'] as String? ?? ''),

                // Date
                if (_data['start_time'] != null)
                  _buildInfoRow(
                    'Date:',
                    DateFormat('dd.MM.yyyy')
                        .format(_data['start_time'] as DateTime),
                  ),

                // Time
                if (_data['start_time'] != null)
                  _buildInfoRow(
                    'Time:',
                    DateFormat('HH:mm').format(_data['start_time'] as DateTime),
                  ),

                // Location
                if (_data['location'] != null &&
                    (_data['location'] as String).isNotEmpty)
                  _buildInfoRow('Location:', _data['location'] as String),

                // Language (B2G only)
                if (!_isB2B && _data['language_display'] != null)
                  _buildInfoRow(
                      'Language:', _data['language_display'] as String),

                // Attendees (B2G only)
                if (!_isB2B && _data['attendees_text'] != null)
                  _buildInfoRow(
                      'Attendees:', _data['attendees_text'] as String),

                // Meeting With (B2G only)
                if (!_isB2B && _data['meeting_with_display'] != null)
                  _buildInfoRow(
                      'Meeting With:', _data['meeting_with_display'] as String),

                // Message
                if (_data['message_display'] != null &&
                    (_data['message_display'] as String).isNotEmpty)
                  _buildInfoRow('Message:', _data['message_display'] as String),

                const SizedBox(height: 32),

                // Buttons
                _buildButtons(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetCard() {
    if (_isB2B) {
      return _buildB2BTargetCard();
    } else {
      return _buildB2GTargetCard();
    }
  }

  Widget _buildB2BTargetCard() {
    final target = _data['target_display'] as Map<String, dynamic>? ?? {};
    final firstName = target['first_name'] as String? ?? '';
    final lastName = target['last_name'] as String? ?? '';
    final fullName = '$firstName $lastName'.trim();
    final position = target['position'] as String? ?? '';
    final companyName = target['company_name'] as String? ?? '';
    final photoUrl = _buildImageUrl(target['photo_url'] as String?);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.inputBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gradientStart, width: 2),
            ),
            child: ClipOval(
              child: photoUrl.isNotEmpty
                  ? Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(fullName),
                    )
                  : _buildAvatarPlaceholder(fullName),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName.isNotEmpty ? fullName : 'Participant',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (position.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    position,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                if (companyName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    companyName,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildB2GTargetCard() {
    final entity = _data['target_display'] as Map<String, dynamic>? ?? {};
    final name = entity['name'] as String? ?? 'Government Entity';
    final logoUrl = _buildImageUrl(entity['logo_url'] as String?);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.inputBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: logoUrl.isNotEmpty
                  ? Image.network(
                      logoUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.account_balance,
                        size: 36,
                        color: Colors.grey[400],
                      ),
                    )
                  : Icon(
                      Icons.account_balance,
                      size: 36,
                      color: Colors.grey[400],
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder(String name) {
    final initials = name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    return Container(
      color: AppColors.cardBackground,
      alignment: Alignment.center,
      child: Text(
        initials.isNotEmpty ? initials : '?',
        style: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.gradientStart,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 183),
            child: SizedBox(
              height: 48,
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isSubmitting ? null : () => context.pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                  side: BorderSide(color: AppTheme.errorColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Decline',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.errorColor,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 183),
            child: SizedBox(
              height: 48,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gradientStart,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Confirm',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
