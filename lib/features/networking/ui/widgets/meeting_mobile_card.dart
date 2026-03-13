import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

/// Mobile card view for a single meeting - matches Figma mobile design
class MeetingMobileCard extends StatelessWidget {
  final Map<String, dynamic> meeting;
  final bool isB2B;
  final void Function(Map<String, dynamic> meeting, String action) onAction;

  const MeetingMobileCard({
    super.key,
    required this.meeting,
    required this.isB2B,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isSender = meeting['is_sender'] ?? true;
    final status = (meeting['status'] ?? 'PENDING').toString().toUpperCase();

    // Extract display info
    String displayName;
    String companyOrRole;

    if (isB2B) {
      if (isSender) {
        final targetUser = meeting['target_user'] as Map<String, dynamic>?;
        final firstName = targetUser?['first_name'] ?? '';
        final lastName = targetUser?['last_name'] ?? '';
        displayName = '$firstName $lastName'.trim();
        if (displayName.isEmpty) displayName = 'Unknown';
        companyOrRole = targetUser?['company_name'] ?? 'N/A';
      } else {
        final requesterInfo =
            meeting['requester_info'] as Map<String, dynamic>?;
        final firstName = requesterInfo?['first_name'] ?? '';
        final lastName = requesterInfo?['last_name'] ?? '';
        displayName = '$firstName $lastName'.trim();
        if (displayName.isEmpty) displayName = 'Unknown Sender';
        companyOrRole = requesterInfo?['company_name'] ?? 'N/A';
      }
    } else {
      // B2G
      displayName = meeting['attendees_text'] ?? 'N/A';
      companyOrRole = meeting['target_gov_entity_name'] ?? 'Gov Entity';
    }

    final subject = meeting['subject'] ?? 'No subject';
    final date = _formatDate(meeting['start_time']?.toString());
    final time = _formatTime(meeting['start_time']?.toString());
    final location = meeting['location'] ?? 'TBD';

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
            color: Color.fromRGBO(60, 68, 148, 0.5),
            blurRadius: 3.4,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Subject + Status + Menu
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    subject,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1A1A2E),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusBadge(status, isSender),
                _buildActionsMenu(isSender, status),
              ],
            ),
            const SizedBox(height: 12),
            // Row 2: Company/Name
            Text(
              companyOrRole,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryColor,
              ),
            ),
            if (isB2B) ...[
              const SizedBox(height: 4),
              Text(
                displayName,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Row 3: Date, Time, Location chips
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildInfoChip(Icons.calendar_today_outlined, date),
                _buildInfoChip(Icons.access_time, time),
                _buildInfoChip(Icons.location_on_outlined, location),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF6B7280)),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.roboto(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status, bool isSender) {
    final color = _getStatusColor(status);
    String label;
    if (status == 'PENDING') {
      label = isSender ? 'Awaiting' : 'Action Required';
    } else {
      label = _getStatusLabel(status);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

  Widget _buildActionsMenu(bool isSender, String status) {
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
      if (isPending) {
        items.add(PopupMenuItem(
          value: 'delete',
          child: Row(children: [
            const Icon(Icons.delete_outline, size: 18, color: Colors.red),
            const SizedBox(width: 10),
            Text('Delete',
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
            const Icon(Icons.check_circle_outline,
                size: 18, color: Colors.green),
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

    if (items.isEmpty) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Color(0xFF6B7280), size: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 4,
      onSelected: (value) => onAction(meeting, value),
      itemBuilder: (_) => items,
    );
  }

  Color _getStatusColor(String status) {
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

  String _getStatusLabel(String status) {
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
