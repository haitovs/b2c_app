import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/config/app_config.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../team/providers/team_providers.dart';
import '../../team/models/team_member.dart';
import '../providers/meeting_providers.dart';

/// B2G Meeting Request Page - for creating a meeting with government entities.
/// Features: Our Attendees (autocomplete + custom), Meeting With (name/surname/position),
/// Language multi-select with flags, Subject, Date/Time, Location, Message.
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

  // Subject + Message
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  // Our Attendees
  final List<TeamMember> _selectedAttendees = [];
  final List<String> _customAttendees = [];

  // Meeting With
  final TextEditingController _meetingWithNameController =
      TextEditingController();
  final TextEditingController _meetingWithSurnameController =
      TextEditingController();
  final TextEditingController _meetingWithPositionController =
      TextEditingController();

  // Location
  String? _selectedLocation;

  // Language multi-select
  final Set<String> _selectedLanguages = {'EN'};
  static const _languageOptions = [
    {'code': 'EN', 'flag': '🇬🇧', 'label': 'English'},
    {'code': 'RU', 'flag': '🇷🇺', 'label': 'Russian'},
    {'code': 'TK', 'flag': '🇹🇲', 'label': 'Turkmen'},
  ];

  // Agenda days
  List<Map<String, dynamic>> _agendaDays = [];
  Map<String, dynamic>? _selectedDay;

  // Date and time (fallback when no agenda days)
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // Data
  Map<String, dynamic>? _govEntity;
  bool _isLoading = true;

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
    final eventId = int.tryParse(widget.eventId) ?? 0;
    if (eventId == 0) return;

    try {
      final response = await http.get(
        Uri.parse(
          '${AppConfig.b2cApiBaseUrl}/api/v1/agenda/days?event_id=$eventId',
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
      if (kDebugMode) debugPrint('Error fetching agenda days: $e');
    }
  }

  Future<void> _fetchGovEntity() async {
    try {
      final meetingService = ref.read(meetingServiceProvider);
      final eventId = int.tryParse(widget.eventId) ?? 0;
      final entities = await meetingService.fetchGovEntities(eventId: eventId);
      final entity = entities.firstWhere(
        (e) => e['id'].toString() == widget.govEntityId,
        orElse: () => <String, dynamic>{},
      );
      _govEntity = entity.isNotEmpty ? entity : null;
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching gov entity: $e');
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    _meetingWithNameController.dispose();
    _meetingWithSurnameController.dispose();
    _meetingWithPositionController.dispose();
    super.dispose();
  }

  // ── Submit ────────────────────────────────────────────────────────────

  void _submitRequest() {
    if (!_formKey.currentState!.validate()) return;

    // Validate position is required for Meeting With
    if (_meetingWithPositionController.text.trim().isEmpty) {
      AppSnackBar.showWarning(
          context, 'Please enter the position of the person you want to meet');
      return;
    }

    // Determine start/end time
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

    // Build attendees text from selected team members + custom entries
    final attendeeNames = [
      ..._selectedAttendees.map((m) => m.fullName),
      ..._customAttendees,
    ];
    final attendeesText =
        attendeeNames.isNotEmpty ? attendeeNames.join(', ') : null;

    // Build "Meeting With" display info
    final meetingWithName = _meetingWithNameController.text.trim();
    final meetingWithSurname = _meetingWithSurnameController.text.trim();
    final meetingWithPosition = _meetingWithPositionController.text.trim();
    final meetingWithParts = <String>[];
    if (meetingWithName.isNotEmpty || meetingWithSurname.isNotEmpty) {
      meetingWithParts.add('$meetingWithName $meetingWithSurname'.trim());
    }
    meetingWithParts.add(meetingWithPosition);
    final meetingWithDisplay = meetingWithParts.join(', ');

    final userMessage = _messageController.text.trim();
    final fullMessage = [
      'Meeting with: $meetingWithDisplay',
      if (userMessage.isNotEmpty) userMessage,
    ].join('\n\n');

    // Language as comma-separated codes and display names
    final languageText = _selectedLanguages.isNotEmpty
        ? _selectedLanguages.join(', ')
        : null;
    final languageDisplay = _selectedLanguages
        .map((code) {
          final opt = _languageOptions.firstWhere((o) => o['code'] == code);
          return opt['label'];
        })
        .join(', ');

    final confirmData = <String, dynamic>{
      'meeting_type': 'b2g',
      'event_id': int.parse(widget.eventId),
      'subject': _subjectController.text.trim(),
      'start_time': startTime,
      'end_time': endTime,
      'location': _selectedLocation,
      'target_gov_entity_id': int.tryParse(widget.govEntityId),
      'attendees_text': attendeesText,
      'language': languageText,
      'language_display': languageDisplay,
      'message': fullMessage,
      'message_display': userMessage,
      'meeting_with_display': meetingWithDisplay,
      // Display data for the confirmation card
      'target_display': _govEntity,
    };

    context.push(
      '/events/${widget.eventId}/meetings/confirm',
      extra: confirmData,
    );
  }

  // ── Pickers ───────────────────────────────────────────────────────────

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
    if (imagePath.startsWith('http') || imagePath.startsWith('data:')) {
      return imagePath;
    }
    return '${AppConfig.b2cApiBaseUrl}$imagePath';
  }

  Widget _buildImageWidget(String imageUrl,
      {double? width, double? height, BoxFit fit = BoxFit.contain}) {
    if (imageUrl.startsWith('data:')) {
      try {
        final base64Str = imageUrl.split(',').last;
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) =>
              _buildPlaceholder(_govEntity?['name'] ?? ''),
        );
      } catch (_) {
        return _buildPlaceholder(_govEntity?['name'] ?? '');
      }
    }
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) =>
          _buildPlaceholder(_govEntity?['name'] ?? ''),
    );
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
          topRight: Radius.circular(8),
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
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
              child: _buildImageWidget(
                logoUrl,
                width: 200,
                height: 200,
                fit: BoxFit.contain,
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
            // Our Attendees
            _buildAttendeesSection(),
            const SizedBox(height: 20),

            // Meeting With
            _buildMeetingWithSection(),
            const SizedBox(height: 20),

            // Subject
            AppTextField(
              labelText: 'Subject:',
              hintText: 'Enter subject...',
              controller: _subjectController,
              required: true,
              borderRadius: 8,
            ),
            const SizedBox(height: 20),

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
            const SizedBox(height: 20),

            // Location
            _buildLocationDropdown(),
            const SizedBox(height: 20),

            // Language
            _buildLanguageMultiSelect(),
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

            // Action buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  // ── Our Attendees Section ─────────────────────────────────────────────

  Widget _buildAttendeesSection() {
    final eventId = int.tryParse(widget.eventId);
    final teamMembersAsync = eventId != null
        ? ref.watch(allTeamMembersProvider(eventId))
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Text('Our Attendees:', style: AppTextStyles.label),
        ),

        // Unified autocomplete: shows team members as suggestions, allows custom text entry
        if (teamMembersAsync != null)
          teamMembersAsync.when(
            data: (members) {
              final available = members.where(
                (m) => !_selectedAttendees.any((s) => s.id == m.id),
              ).toList();

              return _UnifiedAttendeeAutocomplete(
                available: available,
                onTeamMemberSelected: (member) {
                  setState(() => _selectedAttendees.add(member));
                },
                onCustomAttendeeAdded: (name) {
                  setState(() => _customAttendees.add(name));
                },
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
            error: (_, __) => const SizedBox.shrink(),
          ),

        // Selected team member chips
        if (_selectedAttendees.isNotEmpty || _customAttendees.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ..._selectedAttendees.map((m) {
                return Chip(
                  label: Text(m.fullName, style: AppTextStyles.inputText),
                  deleteIcon:
                      const Icon(Icons.close, size: 16, color: Colors.grey),
                  onDeleted: () {
                    setState(() => _selectedAttendees.remove(m));
                  },
                  backgroundColor: AppColors.cardBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: AppColors.inputBorder),
                  ),
                );
              }),
              ..._customAttendees.asMap().entries.map((entry) {
                return Chip(
                  label: Text(entry.value, style: AppTextStyles.inputText),
                  deleteIcon:
                      const Icon(Icons.close, size: 16, color: Colors.grey),
                  onDeleted: () {
                    setState(() => _customAttendees.removeAt(entry.key));
                  },
                  backgroundColor: const Color(0xFFFFF8E1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.amber.shade300),
                  ),
                );
              }),
            ],
          ),
        ],
      ],
    );
  }

  // ── Meeting With Section ──────────────────────────────────────────────

  Widget _buildMeetingWithSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Text('Meeting With:', style: AppTextStyles.label),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.inputBorder),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 500) {
                    return Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            labelText: 'Name:',
                            hintText: 'Name (optional)',
                            controller: _meetingWithNameController,
                            borderRadius: 8,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AppTextField(
                            labelText: 'Surname:',
                            hintText: 'Surname (optional)',
                            controller: _meetingWithSurnameController,
                            borderRadius: 8,
                          ),
                        ),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      AppTextField(
                        labelText: 'Name:',
                        hintText: 'Name (optional)',
                        controller: _meetingWithNameController,
                        borderRadius: 8,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        labelText: 'Surname:',
                        hintText: 'Surname (optional)',
                        controller: _meetingWithSurnameController,
                        borderRadius: 8,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                labelText: 'Position:',
                hintText: 'Enter position...',
                controller: _meetingWithPositionController,
                required: true,
                borderRadius: 8,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Language Multi-Select ─────────────────────────────────────────────

  Widget _buildLanguageMultiSelect() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Text('Language of meeting:', style: AppTextStyles.label),
        ),
        GestureDetector(
          onTap: _showLanguagePicker,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.inputBorder),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _selectedLanguages.isEmpty
                      ? Text('Select languages...',
                          style: AppTextStyles.placeholder)
                      : Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: _selectedLanguages.map((code) {
                            final opt = _languageOptions.firstWhere(
                              (o) => o['code'] == code,
                            );
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.gradientStart
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${opt['flag']} ${opt['label']}',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.gradientStart,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                ),
                Icon(Icons.keyboard_arrow_down,
                    color: AppColors.textPlaceholder),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Languages',
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gradientStart,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._languageOptions.map((opt) {
                    final code = opt['code']!;
                    final isSelected = _selectedLanguages.contains(code);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Text(opt['flag']!,
                          style: const TextStyle(fontSize: 28)),
                      title: Text(
                        '${opt['label']} (${opt['code']})',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: Checkbox(
                        value: isSelected,
                        activeColor: AppColors.gradientStart,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        onChanged: (value) {
                          setSheetState(() {
                            if (value == true) {
                              _selectedLanguages.add(code);
                            } else {
                              _selectedLanguages.remove(code);
                            }
                          });
                          setState(() {});
                        },
                      ),
                      onTap: () {
                        setSheetState(() {
                          if (isSelected) {
                            _selectedLanguages.remove(code);
                          } else {
                            _selectedLanguages.add(code);
                          }
                        });
                        setState(() {});
                      },
                    );
                  }),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gradientStart,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Done',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                      height: MediaQuery.of(context).viewPadding.bottom + 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Location dropdown ─────────────────────────────────────────────────

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
            final effectiveValue = locationNames.contains(_selectedLocation)
                ? _selectedLocation
                : null;
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

  // ── Day dropdown ──────────────────────────────────────────────────────

  Widget _buildDayDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Text('Meeting day:', style: AppTextStyles.label),
        ),
        Container(
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.inputBorder),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Map<String, dynamic>>(
              value: _selectedDay,
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              icon: Icon(Icons.keyboard_arrow_down,
                  color: AppColors.textPlaceholder),
              items: _agendaDays.map((day) {
                String label;
                final date = day['date'] as String?;
                if (date != null) {
                  try {
                    final dt = DateTime.parse(date);
                    final weekdays = [
                      '',
                      'Monday',
                      'Tuesday',
                      'Wednesday',
                      'Thursday',
                      'Friday',
                      'Saturday',
                      'Sunday',
                    ];
                    label = '${dt.day} ${weekdays[dt.weekday]}';
                  } catch (_) {
                    label = date;
                  }
                } else {
                  label =
                      day['name'] ?? 'Day ${_agendaDays.indexOf(day) + 1}';
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

/// A unified attendee input that shows team member suggestions on focus/tap
/// and also allows typing custom attendee names.
class _UnifiedAttendeeAutocomplete extends StatefulWidget {
  final List<TeamMember> available;
  final ValueChanged<TeamMember> onTeamMemberSelected;
  final ValueChanged<String> onCustomAttendeeAdded;

  const _UnifiedAttendeeAutocomplete({
    required this.available,
    required this.onTeamMemberSelected,
    required this.onCustomAttendeeAdded,
  });

  @override
  State<_UnifiedAttendeeAutocomplete> createState() =>
      _UnifiedAttendeeAutocompleteState();
}

class _UnifiedAttendeeAutocompleteState
    extends State<_UnifiedAttendeeAutocomplete> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<TeamMember> _filteredMembers = [];

  static final _subtitleStyle = GoogleFonts.inter(
    fontSize: 12,
    color: AppColors.textSecondary,
  );

  @override
  void initState() {
    super.initState();
    _filteredMembers = widget.available;
    _focusNode.addListener(_onFocusChanged);
    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant _UnifiedAttendeeAutocomplete oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.available != widget.available) {
      _filterMembers();
      _overlayEntry?.markNeedsBuild();
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    _focusNode.removeListener(_onFocusChanged);
    _controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _filterMembers();
      _showOverlay();
    } else {
      // Delay so overlay onTap can fire before removal
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!_focusNode.hasFocus && mounted) {
          _removeOverlay();
        }
      });
    }
  }

  void _onTextChanged() {
    _filterMembers();
    // Update existing overlay content — don't recreate it
    if (_overlayEntry != null) {
      if (_filteredMembers.isEmpty) {
        _removeOverlay();
      } else {
        _overlayEntry!.markNeedsBuild();
      }
    } else if (_focusNode.hasFocus && _filteredMembers.isNotEmpty) {
      _showOverlay();
    }
  }

  void _filterMembers() {
    final query = _controller.text.toLowerCase().trim();
    if (query.isEmpty) {
      _filteredMembers = widget.available;
    } else {
      _filteredMembers = widget.available
          .where((m) => m.fullName.toLowerCase().contains(query))
          .toList();
    }
  }

  void _showOverlay() {
    _removeOverlay();
    if (_filteredMembers.isEmpty) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    final width = renderBox?.size.width ?? 300.0;

    _overlayEntry = OverlayEntry(
      builder: (_) {
        final members = _filteredMembers;
        if (members.isEmpty) return const SizedBox.shrink();

        return CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: const Offset(0, 4),
          child: SizedBox(
            width: width,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];
                    return ListTile(
                      dense: true,
                      title: Text(member.fullName,
                          style: AppTextStyles.inputText),
                      subtitle: member.position != null
                          ? Text(member.position!, style: _subtitleStyle)
                          : null,
                      onTap: () {
                        widget.onTeamMemberSelected(member);
                        _controller.clear();
                        _removeOverlay();
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _addCustomAttendee() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      final match = widget.available.where(
        (m) => m.fullName.toLowerCase() == text.toLowerCase(),
      );
      if (match.isNotEmpty) {
        widget.onTeamMemberSelected(match.first);
      } else {
        widget.onCustomAttendeeAdded(text);
      }
      _controller.clear();
      _removeOverlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.inputBorder),
          borderRadius: BorderRadius.circular(8),
        ),
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          style: AppTextStyles.inputText,
          decoration: InputDecoration(
            hintText: 'Search team members or type a name...',
            hintStyle: AppTextStyles.placeholder,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14),
            suffixIcon: IconButton(
              onPressed: _addCustomAttendee,
              icon: const Icon(Icons.add,
                  color: AppColors.textPlaceholder, size: 20),
            ),
          ),
          onSubmitted: (_) => _addCustomAttendee(),
        ),
      ),
    );
  }
}
