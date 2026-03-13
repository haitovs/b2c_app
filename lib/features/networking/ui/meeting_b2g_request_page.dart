import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/config/app_config.dart';
import '../../../core/providers/event_context_provider.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../providers/meeting_providers.dart';
import '../services/meeting_service.dart';

/// B2G Meeting Request Page - for creating a meeting with government entities.
/// Rendered inside EventShellLayout (sidebar/topbar provided).
class MeetingB2GRequestPage extends ConsumerStatefulWidget {
  final String eventId;
  final String govEntityId;
  final Map<String, dynamic>? govEntityData;

  const MeetingB2GRequestPage({
    super.key,
    required this.eventId,
    required this.govEntityId,
    this.govEntityData,
  });

  @override
  ConsumerState<MeetingB2GRequestPage> createState() =>
      _MeetingB2GRequestPageState();
}

class _MeetingB2GRequestPageState
    extends ConsumerState<MeetingB2GRequestPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Form controllers
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  // Attendee list (dynamic)
  final List<TextEditingController> _attendeeControllers = [
    TextEditingController(),
  ];

  // Meeting with list (dynamic) - officials/positions
  final List<TextEditingController> _meetingWithControllers = [
    TextEditingController(),
  ];

  // Language dropdown
  String _selectedLanguage = 'EN';
  static const _languages = ['EN', 'RU', 'TK'];

  // Agenda days dropdown
  List<Map<String, dynamic>> _agendaDays = [];
  Map<String, dynamic>? _selectedDay;

  // Date and time (manual pickers as fallback when no agenda days)
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // Data
  Map<String, dynamic>? _govEntity;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (widget.govEntityData != null) {
      _govEntity = widget.govEntityData;
    } else {
      await _fetchGovEntity();
    }
    await _fetchAgendaDays();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchAgendaDays() async {
    final tourismSiteId = ref.read(eventContextProvider).siteId;
    if (tourismSiteId == null) return;

    try {
      final response = await http.get(
        Uri.parse(
          '${AppConfig.tourismApiBaseUrl}/agenda/days?site_id=$tourismSiteId',
        ),
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        _agendaDays = data.cast<Map<String, dynamic>>();
        if (_agendaDays.isNotEmpty) {
          _selectedDay = _agendaDays.first;
        }
      }
    } catch (e) {
      debugPrint('Error fetching agenda days: $e');
    }
  }

  Future<void> _fetchGovEntity() async {
    try {
      final meetingService = ref.read(meetingServiceProvider);
      final entities = await meetingService.fetchGovEntities();
      final entity = entities.firstWhere(
        (e) => e['id'].toString() == widget.govEntityId,
        orElse: () => <String, dynamic>{},
      );
      _govEntity = entity.isNotEmpty ? entity : null;
    } catch (e) {
      debugPrint('Error fetching gov entity: $e');
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    for (var c in _attendeeControllers) {
      c.dispose();
    }
    for (var c in _meetingWithControllers) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Dynamic list helpers ──────────────────────────────────────────────

  void _addAttendee() {
    setState(() => _attendeeControllers.add(TextEditingController()));
  }

  void _removeAttendee(int index) {
    if (_attendeeControllers.length > 1) {
      setState(() {
        _attendeeControllers[index].dispose();
        _attendeeControllers.removeAt(index);
      });
    }
  }

  void _addMeetingWith() {
    setState(() => _meetingWithControllers.add(TextEditingController()));
  }

  void _removeMeetingWith(int index) {
    if (_meetingWithControllers.length > 1) {
      setState(() {
        _meetingWithControllers[index].dispose();
        _meetingWithControllers.removeAt(index);
      });
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    // Determine start/end time from agenda day or manual pickers
    DateTime startTime;
    DateTime endTime;

    if (_agendaDays.isNotEmpty) {
      if (_selectedDay == null) {
        AppSnackBar.showWarning(
            context, 'Please select a day for the meeting');
        return;
      }
      final dayDate = _selectedDay!['date'] as String;
      startTime = DateTime.parse('${dayDate}T09:00:00');
      endTime = DateTime.parse('${dayDate}T10:00:00');
    } else {
      if (_selectedDate == null) {
        AppSnackBar.showWarning(
            context, 'Please select a date for the meeting');
        return;
      }
      if (_selectedTime == null) {
        AppSnackBar.showWarning(
            context, 'Please select a time for the meeting');
        return;
      }
      startTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
      endTime = startTime.add(const Duration(hours: 1));
    }

    setState(() => _isSubmitting = true);

    try {
      final meetingService = ref.read(meetingServiceProvider);

      final attendeesText = _attendeeControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .join(', ');

      await meetingService.createMeeting(
        eventId: int.parse(widget.eventId),
        type: MeetingType.b2g,
        subject: _subjectController.text.trim(),
        startTime: startTime,
        endTime: endTime,
        location: 'Ashgabat, TKM',
        targetGovEntityId: int.tryParse(widget.govEntityId),
        attendeesText: attendeesText.isEmpty ? null : attendeesText,
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
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── Pickers ───────────────────────────────────────────────────────────

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

  // ── Image URL helper ──────────────────────────────────────────────────

  String _buildImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';
    if (imagePath.startsWith('http')) return imagePath;
    return '${AppConfig.b2cApiBaseUrl}$imagePath';
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_govEntity == null) {
      return const Center(child: Text('Government entity not found'));
    }

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
          const Divider(
              height: 0.5, thickness: 0.5, color: Color(0xFFCACACA)),
          const SizedBox(height: 24),

          // Two cards side by side (desktop) or stacked (mobile)
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 288, child: _buildEntityCard()),
                const SizedBox(width: 24),
                Expanded(child: _buildFormCard()),
              ],
            )
          else
            Column(
              children: [
                _buildEntityCard(),
                const SizedBox(height: 24),
                _buildFormCard(),
              ],
            ),
        ],
      ),
    );
  }

  // ── Entity Card (left) ────────────────────────────────────────────────

  Widget _buildEntityCard() {
    final entity = _govEntity!;
    final name = entity['name'] as String? ?? 'Unknown Entity';
    final logoUrl = _buildImageUrl(entity['logo_url'] as String?);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(5),
          bottomLeft: Radius.circular(5),
          bottomRight: Radius.circular(5),
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x40000000), blurRadius: 10),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (logoUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                logoUrl,
                width: 200,
                height: 200,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => _buildPlaceholder(name),
              ),
            )
          else
            _buildPlaceholder(name),
          const SizedBox(height: 16),
          Text(
            name,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(String name) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              name,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Form Card (right) ─────────────────────────────────────────────────

  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        boxShadow: const [
          BoxShadow(color: Color(0x40000000), blurRadius: 10),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Attendee section
            _buildDynamicSection(
              label: 'Attendee:',
              controllers: _attendeeControllers,
              hintText: 'Name & Surname',
              onAdd: _addAttendee,
              onRemove: _removeAttendee,
            ),
            const SizedBox(height: 16),

            // Meeting with section
            _buildDynamicSection(
              label: 'Meeting with:',
              controllers: _meetingWithControllers,
              hintText: 'Position',
              onAdd: _addMeetingWith,
              onRemove: _removeMeetingWith,
            ),
            const SizedBox(height: 16),

            // Subject
            AppTextField(
              labelText: 'Subject:',
              hintText: 'Enter subject...',
              controller: _subjectController,
              required: true,
              borderRadius: 5,
            ),
            const SizedBox(height: 16),

            // Day or Date+Time
            if (_agendaDays.isNotEmpty)
              _buildDayDropdown()
            else
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

            // Language
            _buildLanguageDropdown(),
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

  // ── Dynamic list section ──────────────────────────────────────────────

  Widget _buildDynamicSection({
    required String label,
    required List<TextEditingController> controllers,
    required String hintText,
    required VoidCallback onAdd,
    required void Function(int) onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 4),
          child: Text(label, style: AppTextStyles.label),
        ),
        ...List.generate(controllers.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.inputBorder),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: TextField(
                      controller: controllers[index],
                      style: AppTextStyles.inputText,
                      decoration: InputDecoration(
                        hintText: hintText,
                        hintStyle: AppTextStyles.placeholder,
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.inputBorder),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: IconButton(
                    onPressed: index == 0 ? onAdd : () => onRemove(index),
                    icon: Icon(
                      index == 0 ? Icons.add : Icons.remove,
                      color: AppColors.textPlaceholder,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── Day dropdown ──────────────────────────────────────────────────────

  Widget _buildDayDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 4),
          child: Text('Meeting day:', style: AppTextStyles.label),
        ),
        Container(
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.inputBorder),
            borderRadius: BorderRadius.circular(5),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Map<String, dynamic>>(
              value: _selectedDay,
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.textPlaceholder,
              ),
              items: _agendaDays.map((day) {
                String label;
                final date = day['date'] as String?;
                if (date != null) {
                  try {
                    final dt = DateTime.parse(date);
                    final weekdays = [
                      '', 'Monday', 'Tuesday', 'Wednesday',
                      'Thursday', 'Friday', 'Saturday', 'Sunday',
                    ];
                    label = '${dt.day} ${weekdays[dt.weekday]}';
                  } catch (_) {
                    label = date;
                  }
                } else {
                  label = day['name'] ??
                      'Day ${_agendaDays.indexOf(day) + 1}';
                }
                return DropdownMenuItem(
                  value: day,
                  child: Text(label, style: AppTextStyles.inputText),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedDay = value);
              },
            ),
          ),
        ),
      ],
    );
  }

  // ── Language dropdown ─────────────────────────────────────────────────

  Widget _buildLanguageDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 4),
          child: Text('Language of meeting:', style: AppTextStyles.label),
        ),
        Container(
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.inputBorder),
            borderRadius: BorderRadius.circular(5),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedLanguage,
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.textPlaceholder,
              ),
              items: _languages.map((lang) {
                return DropdownMenuItem(
                  value: lang,
                  child: Text(lang, style: AppTextStyles.inputText),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedLanguage = value);
              },
            ),
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

  // ── Time field ────────────────────────────────────────────────────────

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

  // ── Action buttons ────────────────────────────────────────────────────

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          width: 183,
          height: 43,
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
        const SizedBox(width: 16),
        SizedBox(
          width: 183,
          height: 43,
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
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
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
      ],
    );
  }
}
