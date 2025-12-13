import 'dart:convert';

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

/// B2G Meeting Request Page - for creating a meeting with government entities
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

class _MeetingB2GRequestPageState extends ConsumerState<MeetingB2GRequestPage> {
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

  // Meeting with list (dynamic) - officials/positions
  final List<TextEditingController> _meetingWithControllers = [
    TextEditingController(),
  ];

  // Language dropdown
  String _selectedLanguage = 'EN';
  final List<String> _languages = ['EN', 'RU', 'TK'];

  // Agenda days dropdown
  List<Map<String, dynamic>> _agendaDays = [];
  Map<String, dynamic>? _selectedDay;

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
    setState(() => _isLoading = false);
  }

  Future<void> _fetchAgendaDays() async {
    // Use eventContextService for correct Tourism site_id
    final tourismSiteId = eventContextService.siteId;
    if (tourismSiteId == null) {
      debugPrint('Warning: No Tourism site_id available');
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
      }
    } catch (e) {
      debugPrint('Error fetching agenda days: $e');
    }
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

  Future<void> _fetchGovEntity() async {
    try {
      final authService = legacy_provider.Provider.of<AuthService>(
        context,
        listen: false,
      );
      final token = await authService.getToken();

      // Fetch from B2C backend
      final response = await http.get(
        Uri.parse('${AppConfig.b2cApiBaseUrl}/api/v1/meetings/gov-entities'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        // Find the specific gov entity
        final entity = data.firstWhere(
          (e) => e['id'].toString() == widget.govEntityId,
          orElse: () => null,
        );
        setState(() {
          _govEntity = entity;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching gov entity: $e');
      setState(() => _isLoading = false);
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

      // Calculate start and end time from selected day
      final dayDate = _selectedDay!['date'] as String;
      final startTime = DateTime.parse('${dayDate}T09:00:00');
      final endTime = DateTime.parse('${dayDate}T10:00:00');

      // Make API call to create B2G meeting
      await meetingService.createMeeting(
        type: MeetingType.B2G,
        subject: _subjectController.text.trim(),
        startTime: startTime,
        endTime: endTime,
        location: 'Ashgabat, TKM',
        targetGovEntityId: int.tryParse(widget.govEntityId),
        attendeesText: attendeesText.isEmpty ? null : attendeesText,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meeting request sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
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
    return '${AppConfig.b2cApiBaseUrl}$imagePath';
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
              'Meeting',
              style: GoogleFonts.montserrat(
                fontSize: isMobile ? 24 : 40,
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
          ),
        ],
      ),
    );
  }

  Widget _buildFormContent() {
    final entity = _govEntity;
    if (entity == null) {
      return const Center(child: Text('Government entity not found'));
    }

    final name = entity['name'] ?? 'Unknown Entity';
    final logo = entity['logo_url'];
    final logoUrl = _buildImageUrl(logo);

    return Form(
      key: _formKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImageCard(logoUrl, name),
                const SizedBox(width: 39),
                Expanded(child: _buildFormCard()),
              ],
            );
          } else {
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
                          _buildCommentsField(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
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
                  color: Colors.black.withOpacity(0.7),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 15),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
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
                color: Colors.black.withOpacity(0.7),
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
                color: Colors.black.withOpacity(0.4),
              ),
              items: _languages.map((lang) {
                return DropdownMenuItem(
                  value: lang,
                  child: Text(
                    lang,
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      color: Colors.black.withOpacity(0.7),
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
                      color: Colors.black.withOpacity(0.4),
                    ),
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
                            color: Colors.black.withOpacity(0.7),
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
                color: Colors.black.withOpacity(0.7),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(15),
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
        Icon(Icons.account_balance, size: 48, color: Colors.grey[400]),
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
