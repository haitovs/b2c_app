import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/event_context_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../providers/meeting_providers.dart';
import 'widgets/delete_confirmation_dialog.dart';
import 'widgets/meeting_mobile_card.dart';
import 'widgets/meetings_table.dart';

/// Main Meeting Page - Shows list of user's scheduled meetings
/// Desktop: Table layout matching Figma (B2B/B2G column variants)
/// Mobile: Card layout
class MeetingsPage extends ConsumerStatefulWidget {
  final String eventId;

  const MeetingsPage({super.key, required this.eventId});

  @override
  ConsumerState<MeetingsPage> createState() => _MeetingsPageState();
}

class _MeetingsPageState extends ConsumerState<MeetingsPage> {
  bool _isB2B = true;
  String _selectedFilter = 'all'; // all, approved, pending, declined
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<Map<String, dynamic>> _filteredMeetings = [];

  int? get _eventIdInt => int.tryParse(widget.eventId);

  @override
  void initState() {
    super.initState();
    final eventId = _eventIdInt;
    if (eventId != null) {
      ref.read(eventContextProvider.notifier).ensureEventContext(eventId);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Invalidate the provider to trigger a reactive refetch in build().
  void _refreshMeetings() {
    ref.invalidate(myMeetingsProvider(_eventIdInt));
  }

  List<Map<String, dynamic>> _meetings = [];

  void _applyFilters() {
    List<Map<String, dynamic>> result = List.from(_meetings);

    // Filter by B2B/B2G type
    final typeFilter = _isB2B ? 'B2B' : 'B2G';
    result = result.where((m) => m['type'] == typeFilter).toList();

    // Filter by status
    if (_selectedFilter != 'all') {
      final statusMap = {
        'approved': 'CONFIRMED',
        'pending': 'PENDING',
        'declined': 'DECLINED',
      };
      result = result
          .where((m) => m['status'] == statusMap[_selectedFilter])
          .toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((m) {
        final subject = (m['subject'] ?? '').toString().toLowerCase();
        final company = (m['target_user'] as Map<String, dynamic>?)?['company_name']?.toString().toLowerCase() ?? '';
        final requesterCompany = (m['requester_info'] as Map<String, dynamic>?)?['company_name']?.toString().toLowerCase() ?? '';
        return subject.contains(query) ||
            company.contains(query) ||
            requesterCompany.contains(query);
      }).toList();
    }

    _filteredMeetings = result;
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _applyFilters();
    });
  }

  void _onFilterChanged(String? filter) {
    if (filter == null) return;
    setState(() {
      _selectedFilter = filter;
      _applyFilters();
    });
  }

  void _onTypeToggled(bool isB2B) {
    setState(() {
      _isB2B = isB2B;
      _applyFilters();
    });
  }

  Future<void> _handleMeetingAction(
      Map<String, dynamic> meeting, String action) async {
    final meetingId = meeting['id'].toString();

    switch (action) {
      case 'view':
        final isSender = meeting['is_sender'] ?? true;
        if (!isSender && meeting['status'] == 'PENDING') {
          context.push(
            '/events/${widget.eventId}/meetings/review/$meetingId',
            extra: meeting,
          );
        }
        break;
      case 'edit':
        final result = await context.push(
          '/events/${widget.eventId}/meetings/review/$meetingId/edit',
          extra: meeting,
        );
        if (result == true && mounted) _refreshMeetings();
        break;
      case 'cancel':
        await _cancelMeeting(meetingId);
        break;
      case 'delete':
        await _deleteMeeting(meetingId);
        break;
      case 'accept':
        await _respondToMeeting(meetingId, 'accept');
        break;
      case 'decline':
        await _respondToMeeting(meetingId, 'decline');
        break;
    }
  }

  Future<void> _deleteMeeting(String meetingId) async {
    final confirmed = await showDeleteConfirmationDialog(context);
    if (!confirmed) return;

    try {
      final meetingService = ref.read(meetingServiceProvider);
      await meetingService.deleteMeeting(meetingId);
      _refreshMeetings();
      if (mounted) {
        AppSnackBar.showSuccess(context, 'Meeting deleted successfully');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Error: $e');
      }
    }
  }

  Future<void> _cancelMeeting(String meetingId) async {
    final confirmed = await showDeleteConfirmationDialog(context);
    if (!confirmed) return;

    try {
      final meetingService = ref.read(meetingServiceProvider);
      await meetingService.cancelMeeting(meetingId);
      _refreshMeetings();
      if (mounted) {
        AppSnackBar.showSuccess(context, 'Meeting cancelled successfully');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Error: $e');
      }
    }
  }

  Future<void> _respondToMeeting(String meetingId, String action) async {
    try {
      final meetingService = ref.read(meetingServiceProvider);
      await meetingService.respondToMeeting(
        meetingId: meetingId,
        action: action,
      );
      _refreshMeetings();
      if (mounted) {
        final label = action == 'accept' ? 'accepted' : 'declined';
        if (action == 'accept') {
          AppSnackBar.showSuccess(context, 'Meeting $label successfully');
        } else {
          AppSnackBar.showWarning(context, 'Meeting $label successfully');
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    // Watch the provider reactively — refetches when invalidated
    final meetingsAsync = ref.watch(myMeetingsProvider(_eventIdInt));

    // Sync provider data into local state for filtering
    final isLoading = meetingsAsync.isLoading && _meetings.isEmpty;
    meetingsAsync.whenData((data) {
      if (data != _meetings) {
        _meetings = data;
        _applyFilters();
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title row with "New Meeting" button
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(
            children: [
              Text(
                'Meetings',
                style: GoogleFonts.montserrat(
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3C4494),
                ),
              ),
              const Spacer(),
              _buildNewMeetingButton(isMobile),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Divider(color: Color(0xFFCACACA), thickness: 0.5, height: 0.5),
        ),
        const SizedBox(height: 16),
        // B2B / B2G toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildTypeToggle(isMobile),
        ),
        const SizedBox(height: 16),
        // Search + Sort row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildSearchAndSortRow(isMobile),
        ),
        const SizedBox(height: 16),
        // Content
        Expanded(
          child: isLoading
              ? Center(
                  child:
                      CircularProgressIndicator(color: AppTheme.primaryColor))
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: isMobile
                      ? _buildMobileList()
                      : MeetingsTable(
                          meetings: _filteredMeetings,
                          isB2B: _isB2B,
                          onAction: _handleMeetingAction,
                        ),
                ),
        ),
      ],
    );
  }

  Widget _buildNewMeetingButton(bool isMobile) {
    return ElevatedButton.icon(
      onPressed: () async {
        final type = _isB2B ? 'b2b' : 'b2g';
        await context
            .push('/events/${widget.eventId}/meetings/new?type=$type');
        if (mounted) _refreshMeetings();
      },
      icon: const Icon(Icons.add, size: 18, color: Colors.white),
      label: Text(
        isMobile ? 'New' : 'New Meeting',
        style: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 20,
          vertical: isMobile ? 10 : 12,
        ),
      ),
    );
  }

  Widget _buildTypeToggle(bool isMobile) {
    final fontSize = isMobile ? 16.0 : 20.0;
    final hPad = isMobile ? 24.0 : 40.0;
    final vPad = isMobile ? 8.0 : 10.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _onTypeToggled(true),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
            decoration: BoxDecoration(
              color: _isB2B ? AppTheme.primaryColor : const Color(0xFFE6E7F2),
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(5)),
            ),
            child: Text(
              'B2B',
              style: GoogleFonts.montserrat(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: _isB2B ? Colors.white : const Color(0xFF3C4494),
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () => _onTypeToggled(false),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
            decoration: BoxDecoration(
              color: !_isB2B ? AppTheme.primaryColor : const Color(0xFFE6E7F2),
              borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(5)),
            ),
            child: Text(
              'B2G',
              style: GoogleFonts.montserrat(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: !_isB2B ? Colors.white : const Color(0xFF3C4494),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndSortRow(bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          _buildSearchBar(),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildSortDropdown()),
            ],
          ),
        ],
      );
    }
    return Row(
      children: [
        Expanded(flex: 5, child: _buildSearchBar()),
        const SizedBox(width: 12),
        _buildSortDropdown(),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      style: GoogleFonts.inter(fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Search meetings...',
        hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
        prefixIcon: const Icon(Icons.search, size: 20),
        filled: true,
        fillColor: const Color(0xFFE6E7F2),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: Color(0xFFCBCBCB), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: Color(0xFFCBCBCB), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
      ),
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFFCBCBCB), width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFilter,
          icon: const Icon(Icons.keyboard_arrow_down,
              size: 16, color: Color(0xFF6B7280)),
          style: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF757A8A),
          ),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('Sort by: All')),
            DropdownMenuItem(value: 'approved', child: Text('Approved')),
            DropdownMenuItem(value: 'pending', child: Text('Pending')),
            DropdownMenuItem(value: 'declined', child: Text('Declined')),
          ],
          onChanged: _onFilterChanged,
        ),
      ),
    );
  }

  Widget _buildMobileList() {
    if (_filteredMeetings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No meetings found',
              style: GoogleFonts.inter(
                  fontSize: 16, color: const Color(0xFF6B7280)),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final type = _isB2B ? 'b2b' : 'b2g';
                await context.push(
                    '/events/${widget.eventId}/meetings/new?type=$type');
                if (mounted) _refreshMeetings();
              },
              icon: const Icon(Icons.add),
              label: const Text('Create New Meeting'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _filteredMeetings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return MeetingMobileCard(
          meeting: _filteredMeetings[index],
          isB2B: _isB2B,
          onAction: _handleMeetingAction,
        );
      },
    );
  }
}
