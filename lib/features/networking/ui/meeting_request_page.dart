import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart' as legacy_provider;

import '../../../core/config/app_config.dart';
import '../../../core/services/event_context_service.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../auth/services/auth_service.dart';
import '../../events/ui/widgets/profile_dropdown.dart';
import '../../notifications/ui/notification_drawer.dart';
import '../services/meeting_service.dart';

/// B2B Meeting Request Page - for creating a new meeting request
class MeetingRequestPage extends ConsumerStatefulWidget {
  final String eventId;
  final String participantId;
  final Map<String, dynamic>? participantData;

  const MeetingRequestPage({
    super.key,
    required this.eventId,
    required this.participantId,
    this.participantData,
  });

  @override
  ConsumerState<MeetingRequestPage> createState() => _MeetingRequestPageState();
}

class _MeetingRequestPageState extends ConsumerState<MeetingRequestPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isProfileOpen = false;

  // Form fields
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _commentsController = TextEditingController();

  // Attendee list (dynamic)
  final List<TextEditingController> _attendeeControllers = [
    TextEditingController(),
  ];

  // Meeting with list (dynamic) - positions
  final List<TextEditingController> _meetingWithControllers = [
    TextEditingController(),
  ];

  // Language dropdown
  String _selectedLanguage = 'EN';
  final List<String> _languages = ['EN', 'RU', 'TK'];

  // Agenda days dropdown
  List<Map<String, dynamic>> _agendaDays = [];
  Map<String, dynamic>? _selectedDay;

  // Time pickers
  TimeOfDay _startTime = TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = TimeOfDay(hour: 10, minute: 0);

  // Attachment image
  Uint8List? _attachmentImage;
  String? _attachmentImageName;

  // Data
  Map<String, dynamic>? _participant;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initializeAndFetch();
  }

  Future<void> _initializeAndFetch() async {
    // Ensure the event context is loaded for this event
    final eventId = int.tryParse(widget.eventId);
    if (eventId != null) {
      await eventContextService.ensureEventContext(eventId);
    }
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (widget.participantData != null) {
      _participant = widget.participantData;
    } else {
      await _fetchParticipant();
    }
    await _fetchAgendaDays();
    setState(() => _isLoading = false);
  }

  Future<void> _fetchAgendaDays() async {
    // Use EventContextService for site_id (already initialized at app startup)
    final tourismSiteId = eventContextService.siteId;

    if (tourismSiteId == null) {
      debugPrint('Warning: No Tourism site_id available, using fallback days');
      _agendaDays = _getFallbackDays();
      if (_agendaDays.isNotEmpty) {
        _selectedDay = _agendaDays.first;
      }
      return;
    }

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
      } else {
        debugPrint('Failed to fetch agenda days: ${response.statusCode}');
        _agendaDays = _getFallbackDays();
        if (_agendaDays.isNotEmpty) {
          _selectedDay = _agendaDays.first;
        }
      }
    } catch (e) {
      debugPrint('Error fetching agenda days: $e');
      _agendaDays = _getFallbackDays();
      if (_agendaDays.isNotEmpty) {
        _selectedDay = _agendaDays.first;
      }
    }
  }

  List<Map<String, dynamic>> _getFallbackDays() {
    // Generate 3 days starting from tomorrow
    final now = DateTime.now();
    final List<Map<String, dynamic>> days = [];
    for (int i = 1; i <= 3; i++) {
      final date = now.add(Duration(days: i));
      days.add({
        'id': i,
        'date':
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        'day_number': date.day,
        'day_name': _getDayName(date.weekday),
      });
    }
    return days;
  }

  String _getDayName(int weekday) {
    const names = [
      '',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return names[weekday];
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _commentsController.dispose();
    for (var controller in _attendeeControllers) {
      controller.dispose();
    }
    for (var controller in _meetingWithControllers) {
      controller.dispose();
    }
    super.dispose();
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

  Future<void> _fetchParticipant() async {
    try {
      final siteId = eventContextService.siteId;
      var uriString =
          '${AppConfig.tourismApiBaseUrl}/participants/${widget.participantId}';
      if (siteId != null) {
        uriString += '?site_id=$siteId';
      }

      final response = await http.get(Uri.parse(uriString));
      if (response.statusCode == 200) {
        setState(() {
          _participant = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching participant: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    // Image attachments not supported for meetings
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image attachments are not available for meetings'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  void _removeImage() {
    setState(() {
      _attachmentImage = null;
      _attachmentImageName = null;
    });
  }

  void _addAttendee() {
    setState(() {
      _attendeeControllers.add(TextEditingController());
    });
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
    setState(() {
      _meetingWithControllers.add(TextEditingController());
    });
  }

  void _removeMeetingWith(int index) {
    if (_meetingWithControllers.length > 1) {
      setState(() {
        _meetingWithControllers[index].dispose();
        _meetingWithControllers.removeAt(index);
      });
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate day selection
    if (_selectedDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a day for the meeting'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Get auth service for token
      final authService = legacy_provider.Provider.of<AuthService>(
        context,
        listen: false,
      );

      final meetingService = MeetingService(authService);

      // Collect attendees as comma-separated text
      final attendeesText = _attendeeControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .join(', ');

      // Calculate start and end time from selected day and time pickers
      final dayDate = _selectedDay!['date'] as String;
      final startTime = DateTime.parse(
        '${dayDate}T${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}:00',
      );
      final endTime = DateTime.parse(
        '${dayDate}T${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}:00',
      );

      // Get the target user ID - use route param (which is the B2C user UUID)
      // Or fallback to participant data 'id' field
      String? targetUserId = widget.participantId;
      if (targetUserId.isEmpty && _participant != null) {
        targetUserId = _participant!['id']?.toString();
      }

      // Make API call to create meeting
      await meetingService.createMeeting(
        eventId: int.parse(widget.eventId),
        type: MeetingType.b2b,
        subject: _subjectController.text.trim(),
        startTime: startTime,
        endTime: endTime,
        location: 'Ashgabat, TKM', // Default location
        targetUserId: targetUserId,
        attendeesText: attendeesText.isEmpty ? null : attendeesText,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meeting request sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop(true); // Return true to signal refresh needed
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final horizontalMargin = isMobile ? 10.0 : 50.0;
    final contentPadding = isMobile ? 20.0 : 50.0;

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
                  _buildHeader(isMobile, horizontalMargin),
                  SizedBox(height: isMobile ? 10 : 20),
                  // Content
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
                              child: _buildFormContent(),
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

  Widget _buildHeader(bool isMobile, double horizontalPadding) {
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
            'Meeting Request',
            style: GoogleFonts.montserrat(
              fontSize: 28,
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

  Widget _buildFormContent() {
    final participant = _participant;
    if (participant == null) {
      return const Center(child: Text('Participant not found'));
    }

    final name = participant['name'] ?? 'Unknown Company';
    final logo = participant['logo'];
    final logoUrl = _buildImageUrl(logo);

    return Form(
      key: _formKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;

          if (isWide) {
            // Desktop layout: image on left, form on right
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side - Participant image in white card
                _buildImageCard(logoUrl, name),
                const SizedBox(width: 39),
                // Right side - Form in white card
                Expanded(child: _buildFormCard()),
              ],
            );
          } else {
            // Mobile layout: image on top, form below
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildImageCard(logoUrl, name),
                const SizedBox(height: 30),
                _buildFormCard(),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildImageCard(String logoUrl, String name) {
    return Container(
      width: 300,
      height: 351,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Center(
        child: logoUrl.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.all(20),
                child: Image.network(
                  logoUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildImagePlaceholder(name),
                ),
              )
            : _buildImagePlaceholder(name),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with title and save button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Information',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              _buildSaveButton(),
            ],
          ),
          const SizedBox(height: 25),
          // Form fields in two columns
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 500) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAttendeeSection(),
                          const SizedBox(height: 20),
                          _buildSubjectsField(),
                          const SizedBox(height: 20),
                          _buildCommentsField(),
                          const SizedBox(height: 20),
                          _buildAttachmentSection(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Right column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMeetingWithSection(),
                          const SizedBox(height: 20),
                          _buildDayDropdown(),
                          const SizedBox(height: 20),
                          _buildTimePickers(),
                          const SizedBox(height: 20),
                          _buildLanguageDropdown(),
                        ],
                      ),
                    ),
                  ],
                );
              } else {
                // Single column for mobile
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
                    _buildTimePickers(),
                    const SizedBox(height: 20),
                    _buildLanguageDropdown(),
                    const SizedBox(height: 20),
                    _buildCommentsField(),
                    const SizedBox(height: 20),
                    _buildAttachmentSection(),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAttendeeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attendee:',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 15),
        // Dynamic attendee fields
        ...List.generate(_attendeeControllers.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
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
        Text(
          'Meeting with:',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 15),
        // Dynamic meeting with fields
        ...List.generate(_meetingWithControllers.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
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
            height: 50,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFB7B7B7)),
              borderRadius: BorderRadius.circular(5),
            ),
            child: TextField(
              controller: controller,
              style: GoogleFonts.roboto(fontSize: 18),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: GoogleFonts.roboto(
                  fontSize: 18,
                  color: Colors.black.withValues(alpha: 0.7),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 15),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Add/Remove button
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFB7B7B7)),
            borderRadius: BorderRadius.circular(5),
          ),
          child: IconButton(
            onPressed: isFirst ? onAdd : onRemove,
            icon: Icon(
              isFirst ? Icons.add : Icons.remove,
              color: const Color(0xFF808080),
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
        Text(
          'Subjects:',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 15),
        Container(
          height: 50,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFB7B7B7)),
            borderRadius: BorderRadius.circular(5),
          ),
          child: TextField(
            controller: _subjectController,
            style: GoogleFonts.roboto(fontSize: 18),
            decoration: InputDecoration(
              hintText: 'Enter subject...',
              hintStyle: GoogleFonts.roboto(
                fontSize: 18,
                color: Colors.black.withValues(alpha: 0.7),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 15),
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
        Text(
          'Language of meeting:',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 15),
        Container(
          height: 50,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFB7B7B7)),
            borderRadius: BorderRadius.circular(5),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedLanguage,
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: Colors.black.withValues(alpha: 0.4),
              ),
              items: _languages.map((lang) {
                return DropdownMenuItem(
                  value: lang,
                  child: Text(
                    lang,
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      color: Colors.black.withValues(alpha: 0.7),
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedLanguage = value);
                }
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
        Text(
          'Meeting day:',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 15),
        Container(
          height: 50,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFB7B7B7)),
            borderRadius: BorderRadius.circular(5),
          ),
          child: _agendaDays.isEmpty
              ? Center(
                  child: Text(
                    'No days available',
                    style: GoogleFonts.roboto(fontSize: 16, color: Colors.grey),
                  ),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<Map<String, dynamic>>(
                    value: _selectedDay,
                    isExpanded: true,
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.black.withValues(alpha: 0.4),
                    ),
                    items: _agendaDays.map((day) {
                      // Format day label
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
                        } catch (e) {
                          label = date;
                        }
                      } else {
                        label =
                            day['name'] ??
                            'Day ${_agendaDays.indexOf(day) + 1}';
                      }
                      return DropdownMenuItem(
                        value: day,
                        child: Text(
                          label,
                          style: GoogleFonts.roboto(
                            fontSize: 18,
                            color: Colors.black.withValues(alpha: 0.7),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedDay = value);
                      }
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildTimePickers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meeting time:',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            // Start time
            Expanded(
              child: GestureDetector(
                onTap: () => _selectTime(isStart: true),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFB7B7B7)),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 15),
                      Icon(
                        Icons.access_time,
                        color: Colors.black.withValues(alpha: 0.5),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _formatTimeOfDay(_startTime),
                        style: GoogleFonts.roboto(
                          fontSize: 18,
                          color: Colors.black.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'to',
                style: GoogleFonts.inter(fontSize: 16, color: Colors.grey),
              ),
            ),
            // End time
            Expanded(
              child: GestureDetector(
                onTap: () => _selectTime(isStart: false),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFB7B7B7)),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 15),
                      Icon(
                        Icons.access_time,
                        color: Colors.black.withValues(alpha: 0.5),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _formatTimeOfDay(_endTime),
                        style: GoogleFonts.roboto(
                          fontSize: 18,
                          color: Colors.black.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _selectTime({required bool isStart}) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF3C4494)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
          // If start time is after end time, adjust end time
          if (_timeToMinutes(_startTime) >= _timeToMinutes(_endTime)) {
            _endTime = TimeOfDay(
              hour: (_startTime.hour + 1) % 24,
              minute: _startTime.minute,
            );
          }
        } else {
          _endTime = picked;
        }
      });
    }
  }

  int _timeToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildCommentsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comments:',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 15),
        Container(
          height: 117,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFB7B7B7)),
            borderRadius: BorderRadius.circular(5),
          ),
          child: TextField(
            controller: _commentsController,
            maxLines: 5,
            style: GoogleFonts.roboto(fontSize: 18),
            decoration: InputDecoration(
              hintText: 'Enter comments...',
              hintStyle: GoogleFonts.roboto(
                fontSize: 18,
                color: Colors.black.withValues(alpha: 0.7),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attachment:',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 15),
        Container(
          height: 120,
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFFB7B7B7),
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(5),
          ),
          child: _attachmentImage != null
              ? Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.memory(
                        _attachmentImage!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: _removeImage,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                    if (_attachmentImageName != null)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _attachmentImageName!,
                            style: GoogleFonts.roboto(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                  ],
                )
              : InkWell(
                  onTap: _pickImage,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Click to upload image',
                          style: GoogleFonts.roboto(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return OutlinedButton(
      onPressed: _isSubmitting ? null : _submitRequest,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF008000),
        side: const BorderSide(color: Color(0xFF008000)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      ),
      child: _isSubmitting
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF008000)),
              ),
            )
          : Text(
              'Save',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF008000),
              ),
            ),
    );
  }

  Widget _buildImagePlaceholder(String name) {
    return Column(
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
    );
  }
}
