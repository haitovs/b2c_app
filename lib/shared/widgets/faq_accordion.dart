import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';

/// An FAQ accordion item based on [ExpansionTile].
///
/// Displays a question in semibold text with an animated chevron. When expanded,
/// reveals the answer in regular-weight text. The tile has a white background
/// with a subtle border matching the codebase's card style.
///
/// ```dart
/// FAQAccordion(
///   question: 'How do I register for an event?',
///   answer: 'Navigate to the Events page and tap "Register" on ...',
/// )
/// ```
class FAQAccordion extends StatefulWidget {
  /// The question / title shown when collapsed.
  final String question;

  /// The answer body revealed on expansion.
  final String answer;

  /// Whether the tile starts in the expanded state.
  final bool initiallyExpanded;

  const FAQAccordion({
    super.key,
    required this.question,
    required this.answer,
    this.initiallyExpanded = false,
  });

  @override
  State<FAQAccordion> createState() => _FAQAccordionState();
}

class _FAQAccordionState extends State<FAQAccordion> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Theme(
          // Remove the default divider line that ExpansionTile adds.
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: PageStorageKey<String>(widget.question),
            initiallyExpanded: widget.initiallyExpanded,
            onExpansionChanged: (expanded) {
              setState(() => _isExpanded = expanded);
            },
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            trailing: AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: _isExpanded
                    ? AppTheme.primaryColor
                    : Colors.grey.shade500,
              ),
            ),
            title: Text(
              widget.question,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _isExpanded ? AppTheme.primaryColor : Colors.black87,
              ),
            ),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.answer,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
