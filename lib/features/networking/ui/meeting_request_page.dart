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

/// B2B Meeting Request Page - redesigned with:
/// - Our Attendees (selectable from company + custom writable)
/// - Meeting With (name/surname optional, position required)
/// - Language multi-select with flags (EN, RU, TK)
/// - Location from backend
/// - Company card on the left
class MeetingRequestPage extends ConsumerStatefulWidget {
  final String eventId;
  final String participantId;
  final Map<String, dynamic>? participantData;
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

  // Subject + Message
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  // Location
  String? _selectedLocation;

  // Date and time
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;


  bool get _isSpeakerMeeting => widget.speakerId != null;

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
    _messageController.dispose();
    super.dispose();
  }

  // ── Submit ──────────────────────────────────────────────────────────────

  void _submitRequest() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      AppSnackBar.showWarning(context, 'Please select a date');
      return;
    }
    if (_selectedTime == null) {
      AppSnackBar.showWarning(context, 'Please select a time');
      return;
    }

    final startTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
    final endTime = startTime.add(const Duration(hours: 1));

    String? targetUserId;
    int? targetOfficialId;
    if (_isSpeakerMeeting) {
      targetOfficialId = widget.speakerId;
    } else {
      targetUserId = widget.participantId;
    }

    final messageText = _messageController.text.trim();

    final confirmData = <String, dynamic>{
      'meeting_type': 'b2b',
      'event_id': int.parse(widget.eventId),
      'subject': _subjectController.text.trim(),
      'start_time': startTime,
      'end_time': endTime,
      'location': _selectedLocation,
      'target_user_id': targetUserId,
      'target_official_id': targetOfficialId,
      'message': messageText.isNotEmpty ? messageText : null,
      'message_display': messageText,
      // Display data for the confirmation card
      'target_display': _displayData,
    };

    context.push(
      '/events/${widget.eventId}/meetings/confirm',
      extra: confirmData,
    );
  }

  // ── Pickers ─────────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(2050),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme:
              const ColorScheme.light(primary: AppColors.gradientStart),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme:
              const ColorScheme.light(primary: AppColors.gradientStart),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) setState(() => _selectedTime = picked);
  }

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
          Text(
            'Meetings',
            style: GoogleFonts.montserrat(
              fontSize: 30,
              fontWeight: FontWeight.w600,
              color: AppColors.gradientStart,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(
              height: 0.5, thickness: 0.5, color: Color(0xFFCACACA)),
          const SizedBox(height: 24),
          if (isDesktop)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(width: 288, child: _buildCompanyCard()),
                  const SizedBox(width: 24),
                  Expanded(child: _buildFormCard(wideLayout: true)),
                ],
              ),
            )
          else
            Column(
              children: [
                _buildCompanyCard(),
                const SizedBox(height: 24),
                _buildFormCard(wideLayout: screenWidth > 500),
              ],
            ),
        ],
      ),
    );
  }

  // ── Company Card (left) ─────────────────────────────────────────────────

  Widget _buildCompanyCard() {
    final data = _displayData;
    final firstName = data['first_name'] as String? ?? '';
    final lastName = data['last_name'] as String? ?? '';
    final personName = '$firstName $lastName'.trim();
    final position = data['position'] as String? ??
        data['job_title'] as String? ??
        '';
    final companyName = data['company_name'] as String? ?? '';
    final categories = data['company_categories'];
    final categoryText = categories is List
        ? categories.join(', ')
        : (categories as String? ?? '');
    final profilePhotoUrl = _buildImageUrl(
      data['profile_photo_url'] as String? ??
          data['company_logo_url'] as String?,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Color(0x40000000), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          // Person photo + name + position
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              children: [
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                        color: const Color(0xFFE0E0E0), width: 2),
                  ),
                  child: ClipOval(
                    child: profilePhotoUrl.isNotEmpty
                        ? Image.network(
                            profilePhotoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                                Icons.person,
                                size: 64,
                                color: Colors.grey[400]),
                          )
                        : Icon(Icons.person,
                            size: 64, color: Colors.grey[400]),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  personName.isNotEmpty ? personName : 'Unknown',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                if (position.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    position,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF747474),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Divider
          const Divider(
            height: 0.5,
            thickness: 0.5,
            color: Color(0xFFCACACA),
            indent: 20,
            endIndent: 20,
          ),
          // Company
          if (companyName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SvgPicture.asset(
                    'assets/meeting/company.svg',
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
                          'Company',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          companyName,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF747474),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          // Divider before Industry
          if (categoryText.isNotEmpty) ...[
            const Divider(
              height: 0.5,
              thickness: 0.5,
              color: Color(0xFFCACACA),
              indent: 20,
              endIndent: 20,
            ),
            // Industry with different background
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5FA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SvgPicture.asset(
                    'assets/meeting/industry.svg',
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
                          'Industry',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          categoryText,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF747474),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Form Card (right) ──────────────────────────────────────────────────

  Widget _buildFormCard({bool wideLayout = true}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Color(0x40000000), blurRadius: 10),
        ],
      ),
      padding: const EdgeInsets.all(24),
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
              borderRadius: 8,
            ),
            const SizedBox(height: 20),

            // Date + Time row
            if (wideLayout)
              Row(
                children: [
                  Expanded(child: _buildDateField()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTimeField()),
                ],
              )
            else
              Column(
                children: [
                  _buildDateField(),
                  const SizedBox(height: 16),
                  _buildTimeField(),
                ],
              ),
            const SizedBox(height: 20),

            // Location
            _buildLocationDropdown(),
            const SizedBox(height: 20),

            // Message
            AppTextField(
              labelText: 'Message:',
              hintText: 'Enter message...',
              controller: _messageController,
              minLines: 4,
              maxLines: null,
              borderRadius: 8,
            ),
            const SizedBox(height: 24),

            // Buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  // ── Location dropdown ──────────────────────────────────────────────────

  Widget _buildLocationDropdown() {
    final eventId = int.tryParse(widget.eventId);
    if (eventId == null) return const SizedBox.shrink();

    final locationsAsync = ref.watch(meetingLocationsProvider(eventId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Text('Location:', style: AppTextStyles.label),
        ),
        locationsAsync.when(
          data: (locations) {
            if (locations.isEmpty) {
              return Container(
                height: 48,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.inputBorder),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.centerLeft,
                child: Text('No locations available',
                    style: AppTextStyles.placeholder),
              );
            }
            final locationNames =
                locations.map((l) => l['name'] as String).toList();
            final effectiveValue =
                locationNames.contains(_selectedLocation) ? _selectedLocation : null;
            return Container(
              height: 48,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.inputBorder),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: effectiveValue,
                  isExpanded: true,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  hint: Text('Select location...',
                      style: AppTextStyles.placeholder),
                  icon: Icon(Icons.keyboard_arrow_down,
                      color: AppColors.textPlaceholder),
                  items: locations.map<DropdownMenuItem<String>>((loc) {
                    final name = loc['name'] as String;
                    final desc = loc['description'] as String?;
                    return DropdownMenuItem(
                      value: name,
                      child: Text(
                        desc != null && desc.isNotEmpty
                            ? '$name - $desc'
                            : name,
                        style: AppTextStyles.inputText,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) =>
                      setState(() => _selectedLocation = value),
                ),
              ),
            );
          },
          loading: () => Container(
            height: 48,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.inputBorder),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (_, __) => Container(
            height: 48,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.inputBorder),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.centerLeft,
            child: Text('Failed to load locations',
                style: AppTextStyles.placeholder),
          ),
        ),
      ],
    );
  }

  // ── Date field ────────────────────────────────────────────────────────

  Widget _buildDateField() {
    final dateText = _selectedDate != null
        ? DateFormat('dd.MM.yyyy').format(_selectedDate!)
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Text('Date:', style: AppTextStyles.label),
        ),
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.inputBorder),
              borderRadius: BorderRadius.circular(8),
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
                Icon(Icons.calendar_today,
                    size: 20, color: AppColors.textPlaceholder),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Time field ────────────────────────────────────────────────────────

  Widget _buildTimeField() {
    final timeText = _selectedTime != null
        ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Text('Time:', style: AppTextStyles.label),
        ),
        GestureDetector(
          onTap: _pickTime,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.inputBorder),
              borderRadius: BorderRadius.circular(8),
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
                Icon(Icons.access_time,
                    size: 20, color: AppColors.textPlaceholder),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Action buttons ────────────────────────────────────────────────────

  Widget _buildActionButtons() {
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
                onPressed: () => context.pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF474747),
                  side: const BorderSide(color: AppColors.inputBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
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
              height: 48,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gradientStart,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Text(
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
