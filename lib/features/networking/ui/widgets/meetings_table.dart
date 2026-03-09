import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

/// Desktop table view for meetings list - matches Figma design
/// B2B columns: Company, Position, Subject, Date, Time, Location, Status
/// B2G columns: Attendee, Meeting with, Subjects, Date, Time, Location, Status
class MeetingsTable extends StatelessWidget {
  final List<Map<String, dynamic>> meetings;
  final bool isB2B;
  final void Function(Map<String, dynamic> meeting, String action) onAction;

  const MeetingsTable({
    super.key,
    required this.meetings,
    required this.isB2B,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          _buildHeaderRow(),
          Expanded(
            child: meetings.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    itemCount: meetings.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      color: Color(0xFFE9EBF8),
                    ),
                    itemBuilder: (context, index) =>
                        _buildDataRow(meetings[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderRow() {
    final headers = isB2B
        ? ['Company', 'Position', 'Subject', 'Date', 'Time', 'Location', 'Status', '']
        : ['Attendee', 'Meeting with', 'Subjects', 'Date', 'Time', 'Location', 'Status', ''];

    final flexValues = [3, 3, 4, 2, 1, 2, 2, 1];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFE9EBF8),
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      child: Row(
        children: List.generate(headers.length, (i) {
          return Expanded(
            flex: flexValues[i],
            child: Text(
              headers[i],
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF374151),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDataRow(Map<String, dynamic> meeting) {
    final isSender = meeting['is_sender'] ?? true;
    final status = (meeting['status'] ?? 'PENDING').toString().toUpperCase();

    // Extract display data based on B2B vs B2G and sender vs target
    String col1, col2;

    if (isB2B) {
      if (isSender) {
        final targetUser = meeting['target_user'] as Map<String, dynamic>?;
        final firstName = targetUser?['first_name'] ?? '';
        final lastName = targetUser?['last_name'] ?? '';
        col1 = targetUser?['company_name'] ?? 'N/A';
        col2 = '$firstName $lastName'.trim();
        if (col2.isEmpty) col2 = 'N/A';
      } else {
        final requesterInfo = meeting['requester_info'] as Map<String, dynamic>?;
        col1 = requesterInfo?['company_name'] ?? 'N/A';
        final firstName = requesterInfo?['first_name'] ?? '';
        final lastName = requesterInfo?['last_name'] ?? '';
        col2 = '$firstName $lastName'.trim();
        if (col2.isEmpty) col2 = 'N/A';
      }
    } else {
      // B2G: Attendee = requester info, Meeting with = gov entity/official
      if (isSender) {
        col1 = meeting['attendees_text'] ?? 'N/A';
        col2 = meeting['target_gov_entity_name'] ?? 'Gov Entity';
      } else {
        final requesterInfo = meeting['requester_info'] as Map<String, dynamic>?;
        final firstName = requesterInfo?['first_name'] ?? '';
        final lastName = requesterInfo?['last_name'] ?? '';
        col1 = '$firstName $lastName'.trim();
        if (col1.isEmpty) col1 = 'N/A';
        col2 = meeting['target_gov_entity_name'] ?? 'Gov Entity';
      }
    }

    final subject = meeting['subject'] ?? 'No subject';
    final date = _formatDate(meeting['start_time']?.toString());
    final time = _formatTime(meeting['start_time']?.toString());
    final location = meeting['location'] ?? 'TBD';

    final flexValues = [3, 3, 4, 2, 1, 2, 2, 1];

    return InkWell(
      onTap: () => onAction(meeting, 'view'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            // Column 1 - Company / Attendee
            Expanded(
              flex: flexValues[0],
              child: Text(
                col1,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1A1A2E),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Column 2 - Position / Meeting with
            Expanded(
              flex: flexValues[1],
              child: Text(
                col2,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B7280),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Subject
            Expanded(
              flex: flexValues[2],
              child: Text(
                subject,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1A1A2E),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Date
            Expanded(
              flex: flexValues[3],
              child: Text(
                date,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ),
            // Time
            Expanded(
              flex: flexValues[4],
              child: Text(
                time,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ),
            // Location
            Expanded(
              flex: flexValues[5],
              child: Text(
                location,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B7280),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Status badge
            Expanded(
              flex: flexValues[6],
              child: Align(
                alignment: Alignment.centerLeft,
                child: _StatusBadge(status: status, isSender: isSender),
              ),
            ),
            // Actions menu
            Expanded(
              flex: flexValues[7],
              child: _ActionsMenu(
                meeting: meeting,
                onAction: onAction,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'No meetings found',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateTime) {
    if (dateTime == null) return 'N/A';
    try {
      final dt = DateTime.parse(dateTime);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return 'N/A';
    }
  }

  String _formatTime(String? dateTime) {
    if (dateTime == null) return 'N/A';
    try {
      final dt = DateTime.parse(dateTime);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return 'N/A';
    }
  }
}

/// Status badge widget matching Figma colors
class _StatusBadge extends StatelessWidget {
  final String status;
  final bool isSender;

  const _StatusBadge({required this.status, required this.isSender});

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final label = _getLabel();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(155),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }

  Color _getColor() {
    switch (status) {
      case 'CONFIRMED':
        return const Color(0xFF06AC06);
      case 'PENDING':
        return const Color(0xFFED873F);
      case 'DECLINED':
        return const Color(0xFFC60404);
      case 'CANCELLED':
        return const Color(0xFF6B7280);
      default:
        return Colors.grey;
    }
  }

  String _getLabel() {
    if (status == 'PENDING') {
      return isSender ? 'Awaiting' : 'Action Required';
    }
    switch (status) {
      case 'CONFIRMED':
        return 'Approved';
      case 'DECLINED':
        return 'Declined';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }
}

/// 3-dot actions menu for each meeting row
class _ActionsMenu extends StatelessWidget {
  final Map<String, dynamic> meeting;
  final void Function(Map<String, dynamic> meeting, String action) onAction;

  const _ActionsMenu({required this.meeting, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final isSender = meeting['is_sender'] ?? true;
    final status = (meeting['status'] ?? 'PENDING').toString().toUpperCase();
    final isPending = status == 'PENDING';
    final isConfirmed = status == 'CONFIRMED';

    final items = <PopupMenuItem<String>>[];

    if (isSender) {
      if (isPending) {
        items.add(PopupMenuItem(
          value: 'edit',
          child: Row(children: [
            Icon(Icons.edit_outlined, size: 18, color: AppTheme.primaryColor),
            const SizedBox(width: 10),
            Text('Edit', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
          ]),
        ));
      }
      if (isPending || isConfirmed) {
        items.add(PopupMenuItem(
          value: 'cancel',
          child: Row(children: [
            const Icon(Icons.cancel_outlined, size: 18, color: Colors.red),
            const SizedBox(width: 10),
            Text('Cancel',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500, color: Colors.red)),
          ]),
        ));
      }
    } else {
      if (isPending) {
        items.add(PopupMenuItem(
          value: 'accept',
          child: Row(children: [
            const Icon(Icons.check_circle_outline, size: 18, color: Colors.green),
            const SizedBox(width: 10),
            Text('Accept',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500, color: Colors.green)),
          ]),
        ));
        items.add(PopupMenuItem(
          value: 'decline',
          child: Row(children: [
            const Icon(Icons.cancel_outlined, size: 18, color: Colors.red),
            const SizedBox(width: 10),
            Text('Decline',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500, color: Colors.red)),
          ]),
        ));
      }
    }

    if (items.isEmpty) return const SizedBox(width: 18);

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Color(0xFF6B7280), size: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 4,
      onSelected: (value) => onAction(meeting, value),
      itemBuilder: (_) => items,
    );
  }
}
