import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';

/// A horizontally scrollable row of filter chips for category selection.
///
/// Includes an "All" chip at the start. When a chip is tapped, [onSelected] is
/// called with the category name (or `null` for "All"). The currently selected
/// chip is highlighted with [AppTheme.primaryColor].
///
/// ```dart
/// CategoryFilter(
///   categories: ['Electronics', 'Books', 'Fashion'],
///   selected: 'Books',
///   onSelected: (category) => setState(() => _selected = category),
/// )
/// ```
class CategoryFilter extends StatelessWidget {
  /// List of category names to display as filter chips.
  final List<String> categories;

  /// The currently selected category. `null` means "All" is selected.
  final String? selected;

  /// Called when a chip is tapped. Receives the category name, or `null` when
  /// the "All" chip is selected.
  final ValueChanged<String?> onSelected;

  const CategoryFilter({
    super.key,
    required this.categories,
    this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length + 1, // +1 for "All"
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _FilterChip(
              label: 'All',
              isSelected: selected == null,
              onTap: () => onSelected(null),
            );
          }

          final category = categories[index - 1];
          return _FilterChip(
            label: category,
            isSelected: selected == category,
            onTap: () => onSelected(category),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade400,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade800,
          ),
        ),
      ),
    );
  }
}
