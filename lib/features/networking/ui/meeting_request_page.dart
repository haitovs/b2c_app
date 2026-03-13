import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/config/app_config.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../providers/meeting_providers.dart';
import '../services/meeting_service.dart';

/// B2B Meeting Request Page - for creating a new meeting request.
/// Rendered inside EventShellLayout (sidebar/topbar provided).
class MeetingRequestPage extends ConsumerStatefulWidget {
  final String eventId;
  final String participantId;
  final Map<String, dynamic>? participantData;

  /// When set, this is a speaker meeting request (uses targetOfficialId).
  final int? speakerId;
  final String? speakerName;

  const MeetingRequestPage({
    super.key,
    required this.eventId,
    required this.participantId,
    this.participantData,
    this.speakerId,
    this.speakerName,
  });

  @override
  ConsumerState<MeetingRequestPage> createState() =>
      _MeetingRequestPageState();
}

class _MeetingRequestPageState extends ConsumerState<MeetingRequestPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Form controllers
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  // Date and time
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  bool _isSubmitting = false;

  bool get _isSpeakerMeeting => widget.speakerId != null;

  /// Resolve participant display data from either participantData or speaker fields.
  Map<String, dynamic> get _displayData {
    if (_isSpeakerMeeting) {
      return {
        'first_name': widget.speakerName ?? 'Speaker',
        'last_name': '',
      };
    }
    return widget.participantData ?? {};
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _locationController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // ── Submit ──────────────────────────────────────────────────────────────

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      AppSnackBar.showWarning(context, 'Please select a date for the meeting');
      return;
    }
    if (_selectedTime == null) {
      AppSnackBar.showWarning(context, 'Please select a time for the meeting');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final meetingService = ref.read(meetingServiceProvider);

      final startTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
      final endTime = startTime.add(const Duration(hours: 1));

      // Determine target based on meeting type
      String? targetUserId;
      int? targetOfficialId;

      if (_isSpeakerMeeting) {
        targetOfficialId = widget.speakerId;
      } else {
        targetUserId = widget.participantId;
      }

      await meetingService.createMeeting(
        eventId: int.parse(widget.eventId),
        type: MeetingType.b2b,
        subject: _subjectController.text.trim(),
        startTime: startTime,
        endTime: endTime,
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        targetUserId: targetUserId,
        targetOfficialId: targetOfficialId,
        message: _messageController.text.trim().isEmpty
            ? null
            : _messageController.text.trim(),
      );

      if (mounted) {
        AppSnackBar.showSuccess(context, 'Meeting request sent successfully!');
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Failed to send request: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // ── Pickers ─────────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(2050),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme:
                const ColorScheme.light(primary: AppColors.gradientStart),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme:
                const ColorScheme.light(primary: AppColors.gradientStart),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => _selectedTime = picked);
    }
  }

  // ── Image URL helper ────────────────────────────────────────────────────

  String _buildImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';
    if (imagePath.startsWith('http')) return imagePath;
    return '${AppConfig.b2cApiBaseUrl}$imagePath';
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Meetings',
            style: GoogleFonts.montserrat(
              fontSize: 30,
              fontWeight: FontWeight.w600,
              color: AppColors.gradientStart,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 0.5, thickness: 0.5, color: Color(0xFFCACACA)),
          const SizedBox(height: 24),

          // Two cards side by side (desktop) or stacked (mobile)
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 288, child: _buildPersonCard()),
                const SizedBox(width: 24),
                Expanded(child: _buildFormCard()),
              ],
            )
          else
            Column(
              children: [
                _buildPersonCard(),
                const SizedBox(height: 24),
                _buildFormCard(),
              ],
            ),
        ],
      ),
    );
  }

  // ── Person Card (left) ──────────────────────────────────────────────────

  Widget _buildPersonCard() {
    final data = _displayData;
    final firstName = data['first_name'] as String? ?? '';
    final lastName = data['last_name'] as String? ?? '';
    final fullName = '$firstName $lastName'.trim();
    final position = data['position'] as String? ?? '';
    final companyName = data['company_name'] as String? ?? '';
    final categories = data['company_categories'];
    final categoryText = categories is List
        ? categories.join(', ')
        : (categories as String? ?? '');
    final photoUrl = _buildImageUrl(
      data['profile_photo_url'] as String? ??
          data['company_logo_url'] as String?,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(5),
          bottomLeft: Radius.circular(5),
          bottomRight: Radius.circular(5),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 10,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          // Circle avatar
          CircleAvatar(
            radius: 101,
            backgroundColor: AppColors.cardBackground,
            backgroundImage:
                photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
            child: photoUrl.isEmpty
                ? Icon(Icons.person, size: 64, color: Colors.grey[400])
                : null,
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            fullName.isNotEmpty ? fullName : 'Unknown',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),

          // Position
          if (position.isNotEmpty)
            Text(
              position,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF747474),
              ),
            ),
          const SizedBox(height: 16),
          const Divider(
            height: 0.5,
            thickness: 0.5,
            color: Color(0xFFCACACA),
            indent: 20,
            endIndent: 20,
          ),

          // Company
          if (companyName.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoRow(
              svgAsset: 'assets/meeting/company.svg',
              label: 'Company',
              value: companyName,
            ),
            const SizedBox(height: 16),
            const Divider(
              height: 0.5,
              thickness: 0.5,
              color: Color(0xFFCACACA),
              indent: 20,
              endIndent: 20,
            ),
          ],

          // Industry
          if (categoryText.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoRow(
              svgAsset: 'assets/meeting/industry.svg',
              label: 'Industry',
              value: categoryText,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String svgAsset,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture.asset(
            svgAsset,
            width: 20,
            height: 20,
            colorFilter: const ColorFilter.mode(
              AppColors.gradientStart,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
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
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF747474),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Form Card (right) ──────────────────────────────────────────────────

  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 10,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subject
            AppTextField(
              labelText: 'Subject:',
              hintText: 'Enter subject...',
              controller: _subjectController,
              required: true,
              borderRadius: 5,
            ),
            const SizedBox(height: 16),

            // Date + Time row
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 500) {
                  return Row(
                    children: [
                      Expanded(child: _buildDateField()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTimeField()),
                    ],
                  );
                }
                return Column(
                  children: [
                    _buildDateField(),
                    const SizedBox(height: 16),
                    _buildTimeField(),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // Location
            AppTextField(
              labelText: 'Location:',
              hintText: 'Enter location...',
              controller: _locationController,
              borderRadius: 5,
            ),
            const SizedBox(height: 16),

            // Message
            AppTextField(
              labelText: 'Message:',
              hintText: 'Enter message...',
              controller: _messageController,
              maxLines: 6,
              height: 160,
              borderRadius: 5,
            ),
            const SizedBox(height: 24),

            // Action buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  // ── Date field ──────────────────────────────────────────────────────────

  Widget _buildDateField() {
    final dateText = _selectedDate != null
        ? DateFormat('dd.MM.yyyy').format(_selectedDate!)
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 4),
          child: Text('Date:', style: AppTextStyles.label),
        ),
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.inputBorder),
              borderRadius: BorderRadius.circular(5),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    dateText.isNotEmpty ? dateText : 'Select date...',
                    style: dateText.isNotEmpty
                        ? AppTextStyles.inputText
                        : AppTextStyles.placeholder,
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: AppColors.textPlaceholder,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Time field ──────────────────────────────────────────────────────────

  Widget _buildTimeField() {
    final timeText = _selectedTime != null
        ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 4),
          child: Text('Time:', style: AppTextStyles.label),
        ),
        GestureDetector(
          onTap: _pickTime,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.inputBorder),
              borderRadius: BorderRadius.circular(5),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    timeText.isNotEmpty ? timeText : 'Select time...',
                    style: timeText.isNotEmpty
                        ? AppTextStyles.inputText
                        : AppTextStyles.placeholder,
                  ),
                ),
                Icon(
                  Icons.access_time,
                  size: 20,
                  color: AppColors.textPlaceholder,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Action buttons ──────────────────────────────────────────────────────

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 183),
            child: SizedBox(
              height: 43,
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF474747),
                  side: const BorderSide(color: AppColors.inputBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF474747),
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
              height: 43,
              width: double.infinity,
              child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitRequest,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gradientStart,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              elevation: 0,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Send',
                    style: GoogleFonts.inter(
                      fontSize: 18,
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
