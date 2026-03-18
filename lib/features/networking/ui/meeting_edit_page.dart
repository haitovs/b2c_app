import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';
import '../../../core/providers/event_context_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../providers/meeting_providers.dart';

/// Meeting Edit Page - for editing an existing meeting (only if PENDING).
/// Renders inside EventShellLayout (no Scaffold needed).
class MeetingEditPage extends ConsumerStatefulWidget {
  final String eventId;
  final String meetingId;
  final Map<String, dynamic>? meetingData;

  const MeetingEditPage({
    super.key,
    required this.eventId,
    required this.meetingId,
    this.meetingData,
  });

  @override
  ConsumerState<MeetingEditPage> createState() => _MeetingEditPageState();
}

class _MeetingEditPageState extends ConsumerState<MeetingEditPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Form fields
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _commentsController = TextEditingController();

  // Attendee list (dynamic)
  List<TextEditingController> _attendeeControllers = [];

  // Meeting with list (dynamic)
  List<TextEditingController> _meetingWithControllers = [];

  // Location
  String? _selectedLocation;

  // Language dropdown
  final List<String> _languages = ['English', 'Russian', 'Turkmen'];
  String _selectedLanguage = 'English';

  // Agenda days dropdown
  List<Map<String, dynamic>> _agendaDays = [];
  Map<String, dynamic>? _selectedDay;

  // Data
  Map<String, dynamic>? _meeting;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _canEdit = false;

  @override
  void initState() {
    super.initState();
    _initializeAndFetch();
  }

  Future<void> _initializeAndFetch() async {
    final eventId = int.tryParse(widget.eventId);
    if (eventId != null) {
      await ref.read(eventContextProvider.notifier).ensureEventContext(eventId);
    }
    await _fetchMeetingData();
  }

  Future<void> _fetchMeetingData() async {
    setState(() => _isLoading = true);

    try {
      if (widget.meetingData != null) {
        _meeting = widget.meetingData;
      } else {
        final meetingService = ref.read(meetingServiceProvider);
        _meeting = await meetingService.fetchMeeting(widget.meetingId);
      }

      if (_meeting != null) {
        final status = _meeting!['status']?.toString().toUpperCase() ?? '';
        _canEdit = status == 'PENDING';

        _subjectController.text = _meeting!['subject'] ?? '';
        _commentsController.text = _meeting!['message'] ?? '';
        _selectedLocation = _meeting!['location'] as String?;

        // Pre-fill attendees from attendees_text
        final attendeesText = _meeting!['attendees_text'] as String? ?? '';
        final attendeeNames = attendeesText.isEmpty
            ? <String>[]
            : attendeesText
                  .split(',')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();
        _attendeeControllers = attendeeNames.isEmpty
            ? [TextEditingController()]
            : attendeeNames
                  .map((name) => TextEditingController(text: name))
                  .toList();

        _meetingWithControllers = [TextEditingController()];

        // Pre-fill language
        final lang = _meeting!['language'] as String?;
        if (lang != null && _languages.contains(lang)) {
          _selectedLanguage = lang;
        }

        await _fetchAgendaDays();

        // Match selected day from meeting start_time
        final startTime = _meeting!['start_time'];
        if (startTime != null && _agendaDays.isNotEmpty) {
          try {
            final meetingDate = DateTime.parse(startTime).toLocal();
            final meetingDateStr =
                '${meetingDate.year}-${meetingDate.month.toString().padLeft(2, '0')}-${meetingDate.day.toString().padLeft(2, '0')}';
            _selectedDay = _agendaDays.firstWhere(
              (d) => d['date'] == meetingDateStr,
              orElse: () => _agendaDays.first,
            );
          } catch (_) {
            _selectedDay = _agendaDays.isNotEmpty ? _agendaDays.first : null;
          }
        } else if (_agendaDays.isNotEmpty) {
          _selectedDay = _agendaDays.first;
        }
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching meeting: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAgendaDays() async {
    try {
      final eventId = int.tryParse(widget.eventId) ?? 0;

      final response = await http.get(
        Uri.parse('${AppConfig.b2cApiBaseUrl}/api/v1/agenda/days?event_id=$eventId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        _agendaDays = data
            .map((item) => <String, dynamic>{
                  'id': item['id'],
                  'date': item['date'],
                  'label': item['label'] ?? item['date'],
                })
            .toList();
      }

      if (_agendaDays.isEmpty) {
        _agendaDays = _getMockDays();
      }
    } catch (_) {
      _agendaDays = _getMockDays();
    }
  }

  List<Map<String, dynamic>> _getMockDays() {
    final now = DateTime.now();
    return List.generate(5, (i) {
      final day = now.add(Duration(days: i));
      return {
        'id': i + 1,
        'date':
            '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}',
        'label':
            '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}',
      };
    });
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _commentsController.dispose();
    for (var c in _attendeeControllers) {
      c.dispose();
    }
    for (var c in _meetingWithControllers) {
      c.dispose();
    }
    super.dispose();
  }

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

  Future<void> _saveMeeting() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDay == null) {
      AppSnackBar.showInfo(context, 'Please select a day');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final meetingService = ref.read(meetingServiceProvider);

      final attendeesText = _attendeeControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .join(', ');

      // Preserve original time-of-day, update only the date from selected day
      final dayDate = _selectedDay!['date'] as String;
      final dayParts = dayDate.split('-');
      final year = int.parse(dayParts[0]);
      final month = int.parse(dayParts[1]);
      final day = int.parse(dayParts[2]);

      int startHour = 9, startMinute = 0, endHour = 10, endMinute = 0;
      if (_meeting != null && _meeting!['start_time'] != null) {
        try {
          final origStart = DateTime.parse(_meeting!['start_time']).toLocal();
          final origEnd = DateTime.parse(_meeting!['end_time']).toLocal();
          startHour = origStart.hour;
          startMinute = origStart.minute;
          endHour = origEnd.hour;
          endMinute = origEnd.minute;
        } catch (_) {}
      }
      final startTime = DateTime(year, month, day, startHour, startMinute);
      final endTime = DateTime(year, month, day, endHour, endMinute);

      await meetingService.updateMeeting(
        meetingId: widget.meetingId,
        subject: _subjectController.text.trim(),
        startTime: startTime,
        endTime: endTime,
        location: _selectedLocation,
        attendeesText: attendeesText.isEmpty ? null : attendeesText,
        message: _commentsController.text.trim().isEmpty
            ? null
            : _commentsController.text.trim(),
      );

      if (mounted) {
        final eventId = int.tryParse(widget.eventId);
        if (eventId != null) ref.invalidate(myMeetingsProvider(eventId));
        AppSnackBar.showSuccess(context, 'Meeting updated successfully!');
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Failed to update meeting: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _buildImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '${AppConfig.b2cApiBaseUrl}$path';
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back + Title row
          Row(
            children: [
              InkWell(
                onTap: () => context.pop(),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.arrow_back, size: 20, color: Colors.grey.shade600),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Edit Meeting',
                  style: GoogleFonts.montserrat(
                    fontSize: isMobile ? 18 : 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildFormContent(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Form content
  // ---------------------------------------------------------------------------

  Widget _buildFormContent() {
    if (_meeting == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Meeting not found',
              style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    if (!_canEdit) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'This meeting cannot be edited',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Only pending meetings can be modified',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Go Back'),
              style: AppTheme.primaryButtonStyle,
            ),
          ],
        ),
      );
    }

    final targetUser = _meeting!['target_user'] as Map<String, dynamic>?;
    final firstName = targetUser?['first_name'] ?? '';
    final lastName = targetUser?['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    final displayName = fullName.isNotEmpty ? fullName : 'Meeting Participant';
    final companyName = targetUser?['company_name'] ?? '';
    final photoUrl = _buildImageUrl(targetUser?['photo_url']);

    return Form(
      key: _formKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;
          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImageCard(photoUrl, displayName, companyName),
                const SizedBox(width: 24),
                Expanded(child: _buildFormCard()),
              ],
            );
          } else {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildImageCard(photoUrl, displayName, companyName),
                const SizedBox(height: 24),
                _buildFormCard(),
              ],
            );
          }
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Image card (left side)
  // ---------------------------------------------------------------------------

  Widget _buildImageCard(String imageUrl, String name, String company) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Container(
      constraints: isMobile
          ? const BoxConstraints(maxHeight: 280)
          : const BoxConstraints(maxWidth: 300, maxHeight: 351),
      width: isMobile ? double.infinity : 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: 200,
                      height: 200,
                      errorBuilder: (_, __, ___) => _buildImagePlaceholder(name),
                    )
                  : _buildImagePlaceholder(name),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              name,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (company.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                company,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Form card (right side)
  // ---------------------------------------------------------------------------

  Widget _buildFormCard() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Information',
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
              _buildSaveButton(),
            ],
          ),
          const SizedBox(height: 4),
          Divider(color: Colors.grey.shade200),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 500) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAttendeeSection(),
                          const SizedBox(height: 20),
                          _buildSubjectsField(),
                          const SizedBox(height: 20),
                          _buildMessageField(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMeetingWithSection(),
                          const SizedBox(height: 20),
                          _buildDayDropdown(),
                          const SizedBox(height: 20),
                          _buildLocationDropdown(),
                          const SizedBox(height: 20),
                          _buildLanguageDropdown(),
                        ],
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAttendeeSection(),
                    const SizedBox(height: 20),
                    _buildMeetingWithSection(),
                    const SizedBox(height: 20),
                    _buildSubjectsField(),
                    const SizedBox(height: 20),
                    _buildDayDropdown(),
                    const SizedBox(height: 20),
                    _buildLocationDropdown(),
                    const SizedBox(height: 20),
                    _buildLanguageDropdown(),
                    const SizedBox(height: 20),
                    _buildMessageField(),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Form field widgets
  // ---------------------------------------------------------------------------

  Widget _buildAttendeeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Attendee:', style: AppTheme.labelText),
        const SizedBox(height: 8),
        ...List.generate(_attendeeControllers.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildDynamicField(
              controller: _attendeeControllers[index],
              hintText: 'Name & Surname',
              isFirst: index == 0,
              onAdd: _addAttendee,
              onRemove: () => _removeAttendee(index),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMeetingWithSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Meeting with:', style: AppTheme.labelText),
        const SizedBox(height: 8),
        ...List.generate(_meetingWithControllers.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildDynamicField(
              controller: _meetingWithControllers[index],
              hintText: 'Position',
              isFirst: index == 0,
              onAdd: _addMeetingWith,
              onRemove: () => _removeMeetingWith(index),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDynamicField({
    required TextEditingController controller,
    required String hintText,
    required bool isFirst,
    required VoidCallback onAdd,
    required VoidCallback onRemove,
  }) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: controller,
              style: GoogleFonts.inter(fontSize: 14),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade500),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            onPressed: isFirst ? onAdd : onRemove,
            icon: Icon(
              isFirst ? Icons.add : Icons.remove,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Subjects:', style: AppTheme.labelText),
        const SizedBox(height: 8),
        Container(
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _subjectController,
            style: GoogleFonts.inter(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Enter subject...',
              hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade500),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Language of meeting:', style: AppTheme.labelText),
        const SizedBox(height: 8),
        Container(
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedLanguage,
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade500),
              items: _languages.map((lang) {
                return DropdownMenuItem(
                  value: lang,
                  child: Text(
                    lang,
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade700),
                  ),
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

  Widget _buildDayDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Meeting day:', style: AppTheme.labelText),
        const SizedBox(height: 8),
        Container(
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _agendaDays.isEmpty
              ? Center(
                  child: Text(
                    'No days available',
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade500),
                  ),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<Map<String, dynamic>>(
                    value: _selectedDay,
                    isExpanded: true,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade500),
                    items: _agendaDays.map((day) {
                      String label;
                      final date = day['date'] as String?;
                      if (date != null) {
                        try {
                          final dt = DateTime.parse(date);
                          const weekdays = [
                            '', 'Monday', 'Tuesday', 'Wednesday',
                            'Thursday', 'Friday', 'Saturday', 'Sunday',
                          ];
                          label = '${dt.day} ${weekdays[dt.weekday]}';
                        } catch (_) {
                          label = date;
                        }
                      } else {
                        label = day['name'] ?? 'Day ${_agendaDays.indexOf(day) + 1}';
                      }
                      return DropdownMenuItem(
                        value: day,
                        child: Text(
                          label,
                          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade700),
                        ),
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

  Widget _buildLocationDropdown() {
    final eventId = int.tryParse(widget.eventId);
    if (eventId == null) return const SizedBox.shrink();

    final locationsAsync = ref.watch(meetingLocationsProvider(eventId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Location:', style: AppTheme.labelText),
        const SizedBox(height: 8),
        locationsAsync.when(
          data: (locations) {
            if (locations.isEmpty) {
              return Container(
                height: 48,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.centerLeft,
                child: Text(
                  'No locations available',
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade500),
                ),
              );
            }
            // If pre-filled value doesn't match any location, reset it
            final locationNames = locations.map((l) => l['name'] as String).toList();
            final effectiveValue = locationNames.contains(_selectedLocation) ? _selectedLocation : null;
            return Container(
              height: 48,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: effectiveValue,
                  isExpanded: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  hint: Text(
                    'Select location...',
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade500),
                  ),
                  icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade500),
                  items: locations.map<DropdownMenuItem<String>>((loc) {
                    final name = loc['name'] as String;
                    final desc = loc['description'] as String?;
                    return DropdownMenuItem(
                      value: name,
                      child: Text(
                        desc != null && desc.isNotEmpty ? '$name - $desc' : name,
                        style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade700),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedLocation = value);
                  },
                ),
              ),
            );
          },
          loading: () => Container(
            height: 48,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (_, __) => Container(
            height: 48,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.centerLeft,
            child: Text(
              'Failed to load locations',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade500),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Message:', style: AppTheme.labelText),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _commentsController,
            maxLines: 5,
            style: GoogleFonts.inter(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Enter message...',
              hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade500),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Save / Cancel buttons
  // ---------------------------------------------------------------------------

  Widget _buildSaveButton() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton(
          onPressed: () => context.pop(),
          style: AppTheme.secondaryButtonStyle,
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveMeeting,
          style: AppTheme.primaryButtonStyle,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Image placeholder
  // ---------------------------------------------------------------------------

  Widget _buildImagePlaceholder(String name) {
    final initials = name
        .split(' ')
        .take(2)
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
        .join();

    return Container(
      width: 200,
      height: 200,
      color: AppTheme.primaryColor.withValues(alpha: 0.15),
      child: Center(
        child: initials.isNotEmpty
            ? Text(
                initials,
                style: GoogleFonts.inter(
                  fontSize: 48,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              )
            : Icon(Icons.person, size: 60, color: Colors.grey.shade400),
      ),
    );
  }
}
