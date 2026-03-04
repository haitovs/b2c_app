import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';


/// A single item in the breadcrumb trail.
class BreadcrumbItem {
  /// Display label for this breadcrumb segment.
  final String label;

  /// Navigation path. When `null` the item represents the current page and is
  /// rendered as bold, non-clickable text.
  final String? path;

  const BreadcrumbItem({required this.label, this.path});
}

/// A clickable breadcrumb trail widget.
///
/// Renders items separated by ">" characters. All items except the last one are
/// tappable and navigate using [GoRouter.go]. The final item is displayed in
/// bold to indicate the current page.
///
/// ```dart
/// BreadcrumbNav(
///   items: [
///     BreadcrumbItem(label: 'Home', path: '/'),
///     BreadcrumbItem(label: 'Shop', path: '/shop'),
///     BreadcrumbItem(label: 'Product Details'),
///   ],
/// )
/// ```
class BreadcrumbNav extends StatelessWidget {
  /// Ordered list of breadcrumb segments from root to current page.
  final List<BreadcrumbItem> items;

  const BreadcrumbNav({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _buildChildren(context),
      ),
    );
  }

  List<Widget> _buildChildren(BuildContext context) {
    final List<Widget> children = [];

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final isLast = i == items.length - 1;

      if (isLast || item.path == null) {
        // Current page — bold, not clickable.
        children.add(
          Text(
            item.label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        );
      } else {
        // Clickable ancestor.
        children.add(
          InkWell(
            onTap: () => context.go(item.path!),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
              child: Text(
                item.label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        );
      }

      // Add separator between items.
      if (!isLast) {
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '>',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade400,
              ),
            ),
          ),
        );
      }
    }

    return children;
  }
}
