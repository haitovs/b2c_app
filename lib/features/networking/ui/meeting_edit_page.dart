import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart' as legacy_provider;

import '../../../core/config/app_config.dart';
import '../../../core/models/api_exception.dart';
import '../../../core/services/event_context_service.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../auth/services/auth_service.dart';
import '../../events/ui/widgets/profile_dropdown.dart';
import '../../notifications/ui/notification_drawer.dart';

/// Meeting Edit Page - for editing an existing meeting (only if PENDING)
/// Layout matches the MeetingRequestPage (image card + form card)
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isProfileOpen = false;

  // Form fields
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _commentsController = TextEditingController();

  // Attendee list (dynamic)
  List<TextEditingController> _attendeeControllers = [];

  // Meeting with list (dynamic)
  List<TextEditingController> _meetingWithControllers = [];

  // Language dropdown
  final List<String> _languages = [
    'English',
    'German',
    'French',
    'Spanish',
    'Russian',
    'Chinese',
  ];
  String _selectedLanguage = 'English';

  // Agenda days dropdown
  List<Map<String, dynamic>> _agendaDays = [];
  Map<String, dynamic>? _selectedDay;

  // Attachment
  Uint8List? _attachmentImage;
  String? _attachmentImageName;

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
      await eventContextService.ensureEventContext(eventId);
    }
    await _fetchMeetingData();
  }

  Future<void> _fetchMeetingData() async {
    setState(() => _isLoading = true);

    try {
      final authService = legacy_provider.Provider.of<AuthService>(
        context,
        listen: false,
      );
      final token = await authService.getToken();

      // Get meeting data - either from extra or fetch from API
      if (widget.meetingData != null) {
        _meeting = widget.meetingData;
      } else {
        // Fetch meeting from API
        final response = await http.get(
          Uri.parse(
            '${AppConfig.b2cApiBaseUrl}/api/v1/meetings/${widget.meetingId}',
          ),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
        if (response.statusCode == 200) {
          _meeting = jsonDecode(response.body);
        }
      }

      if (_meeting != null) {
        // Check if editable (only PENDING status)
        final status = _meeting!['status']?.toString().toUpperCase() ?? '';
        _canEdit = status == 'PENDING';

        // Pre-fill form fields
        _subjectController.text = _meeting!['subject'] ?? '';

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

        // Initialize meeting with
        _meetingWithControllers = [TextEditingController()];

        // Fetch agenda days
        await _fetchAgendaDays(token);

        // Try to match the selected day from meeting start_time
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
          } catch (e) {
            _selectedDay = _agendaDays.isNotEmpty ? _agendaDays.first : null;
          }
        } else if (_agendaDays.isNotEmpty) {
          _selectedDay = _agendaDays.first;
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error fetching meeting: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAgendaDays(String? token) async {
    try {
      final siteId = eventContextService.siteId;

      if (siteId == null) {
        _agendaDays = _getMockDays();
        return;
      }

      final response = await http.get(
        Uri.parse('${AppConfig.tourismApiBaseUrl}/agenda/?site_id=$siteId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        _agendaDays = data
            .map((item) {
              return {
                'id': item['id'],
                'date': item['date'],
                'label': item['date'],
              };
            })
            .toList()
            .cast<Map<String, dynamic>>();
      }

      if (_agendaDays.isEmpty) {
        _agendaDays = _getMockDays();
      }
    } catch (e) {
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

  void _toggleProfile() {
    setState(() => _isProfileOpen = !_isProfileOpen);
  }

  void _closeProfile() {
    if (_isProfileOpen) {
      setState(() => _isProfileOpen = false);
    }
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

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _attachmentImage = result.files.first.bytes;
          _attachmentImageName = result.files.first.name;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _removeImage() {
    setState(() {
      _attachmentImage = null;
      _attachmentImageName = null;
    });
  }

  Future<void> _saveMeeting() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDay == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a day')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final authService = legacy_provider.Provider.of<AuthService>(
        context,
        listen: false,
      );
      final token = await authService.getToken();

      // Collect attendees as comma-separated text
      final attendeesText = _attendeeControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .join(', ');

      // Calculate start and end time from selected day
      final dayDate = _selectedDay!['date'] as String;
      final startTime = DateTime.parse('${dayDate}T09:00:00');
      final endTime = DateTime.parse('${dayDate}T10:00:00');

      final body = {
        'subject': _subjectController.text.trim(),
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'attendees_text': attendeesText.isEmpty ? null : attendeesText,
      };

      final response = await http.put(
        Uri.parse(
          '${AppConfig.b2cApiBaseUrl}/api/v1/meetings/${widget.meetingId}',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Meeting updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop(true); // Return true to indicate success
        }
      } else {
        throw Exception(ApiException.extractErrorMessage(response.statusCode, response.body));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update meeting: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _buildImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '${AppConfig.b2cApiBaseUrl}$path';
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
                  _buildHeader(isMobile, horizontalMargin),
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
                              child: _buildFormContent(),
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

  Widget _buildHeader(bool isMobile, double horizontalPadding) {
    return Padding(
      padding: EdgeInsets.only(
        left: horizontalPadding,
        right: horizontalPadding,
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
              'Edit Meeting',
              style: GoogleFonts.montserrat(
                fontSize: isMobile ? 20 : 28,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFF1F1F6),
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

  Widget _buildFormContent() {
    if (_meeting == null) {
      return const Center(child: Text('Meeting not found'));
    }

    if (!_canEdit) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'This meeting cannot be edited',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Only pending meetings can be modified',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
            ),
          ],
        ),
      );
    }

    // Get target user info for display
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
            // Desktop layout: image on left, form on right
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side - Participant image in white card
                _buildImageCard(photoUrl, displayName, companyName),
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
                _buildImageCard(photoUrl, displayName, companyName),
                const SizedBox(height: 30),
                _buildFormCard(),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildImageCard(String imageUrl, String name, String company) {
    return Container(
      width: 300,
      height: 351,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Photo
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: 200,
                      height: 200,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildImagePlaceholder(name),
                    )
                  : _buildImagePlaceholder(name),
            ),
          ),
          const SizedBox(height: 20),
          // Name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              name,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
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
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
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
      onPressed: _isSaving ? null : _saveMeeting,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF008000),
        side: const BorderSide(color: Color(0xFF008000)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      ),
      child: _isSaving
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
    final initials = name
        .split(' ')
        .take(2)
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
        .join();

    return Container(
      width: 200,
      height: 200,
      color: const Color(0xFF3C4494).withValues(alpha: 0.2),
      child: Center(
        child: initials.isNotEmpty
            ? Text(
                initials,
                style: GoogleFonts.inter(
                  fontSize: 48,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3C4494),
                ),
              )
            : Icon(Icons.person, size: 60, color: Colors.grey[400]),
      ),
    );
  }
}
