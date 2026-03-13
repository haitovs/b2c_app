import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';

/// Animated checkbox with consistent styling across the app.
///
/// Replaces SVG-based, Icon-based, and raw Material checkboxes
/// with a single clean, animated widget.
class AppCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? label;
  final double size;

  const AppCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.size = 22,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: value ? AppTheme.primaryColor : Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: value ? AppTheme.primaryColor : Colors.grey.shade400,
                width: 1.5,
              ),
            ),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: value ? 1.0 : 0.0,
              child: Icon(
                Icons.check,
                size: size - 6,
                color: Colors.white,
              ),
            ),
          ),
          if (label != null) ...[
            const SizedBox(width: 12),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Text(
                  label!,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Checkbox row for filter drawers and lists.
///
/// Label on the left, checkbox on the right.
class AppCheckboxRow extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const AppCheckboxRow({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color:
                      isSelected ? AppTheme.primaryColor : Colors.grey.shade400,
                  width: 1.5,
                ),
              ),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isSelected ? 1.0 : 0.0,
                child: const Icon(
                  Icons.check,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
