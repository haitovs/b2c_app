import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';

/// Segmented progress bar showing Order / Company / Team / Visa completion.
class ParticipationProgress extends StatelessWidget {
  final bool hasPurchased;
  final AsyncValue<List<dynamic>> companies;
  final AsyncValue<List<dynamic>> teamMembers;
  final AsyncValue<List<Map<String, dynamic>>> visas;

  const ParticipationProgress({
    super.key,
    required this.hasPurchased,
    required this.companies,
    required this.teamMembers,
    required this.visas,
  });

  @override
  Widget build(BuildContext context) {
    final segments = _computeSegments();
    final totalPercent =
        segments.fold<int>(0, (sum, s) => sum + s.percent) ~/ segments.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Participation Progress',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$totalPercent%',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Segmented bar
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 12,
            child: Row(
              children: segments.map((s) {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 2),
                    color: s.percent == 100
                        ? AppTheme.successColor
                        : s.percent > 0
                            ? const Color(0xFFFF9800)
                            : Colors.grey.shade300,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Labels
        Wrap(
          spacing: 16,
          runSpacing: 4,
          children: segments.map((s) {
            final isDone = s.percent == 100;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 14,
                  color: isDone ? AppTheme.successColor : Colors.grey.shade400,
                ),
                const SizedBox(width: 4),
                Text(
                  '${s.label} ${s.percent}%',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color:
                        isDone ? AppTheme.successColor : Colors.grey.shade600,
                    fontWeight: isDone ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  List<_Segment> _computeSegments() {
    // Payment (purchasing a service = registration)
    final payPercent = hasPurchased ? 100 : 0;

    // Company info: 100% if company with name exists
    final compPercent = companies.whenOrNull(
          data: (list) => list.isNotEmpty ? 100 : 0,
        ) ??
        0;

    // Team members: 100% if any members exist
    final teamPercent = teamMembers.whenOrNull(
          data: (list) => list.isNotEmpty ? 100 : 0,
        ) ??
        0;

    // Visa: 100% if any visa confirmed/approved
    final visaPercent = visas.whenOrNull(
          data: (list) => list.any((v) {
            final s = (v['status'] ?? '').toString().toUpperCase();
            return s == 'CONFIRMED' || s == 'APPROVED';
          })
              ? 100
              : 0,
        ) ??
        0;

    return [
      _Segment('Order', payPercent),
      _Segment('Company', compPercent),
      _Segment('Team', teamPercent),
      _Segment('Visa', visaPercent),
    ];
  }
}

class _Segment {
  final String label;
  final int percent;

  const _Segment(this.label, this.percent);
}
