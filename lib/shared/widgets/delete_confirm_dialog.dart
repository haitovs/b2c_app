import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';

/// A confirmation dialog for destructive / delete actions.
///
/// Displays a warning icon, a bold title, a descriptive message, and two action
/// buttons: a grey "Cancel" text button and a red filled "Delete" button.
///
/// ### Using the convenience method
///
/// ```dart
/// final confirmed = await DeleteConfirmDialog.show(
///   context,
///   title: 'Delete Booking',
///   message: 'Are you sure you want to delete this booking? This action cannot be undone.',
/// );
/// if (confirmed == true) { /* proceed */ }
/// ```
///
/// ### Using the widget directly
///
/// ```dart
/// showDialog(
///   context: context,
///   builder: (_) => DeleteConfirmDialog(
///     title: 'Remove Item',
///     message: 'This will remove the item from your cart.',
///     onConfirm: () => ref.read(cartProvider.notifier).remove(itemId),
///   ),
/// );
/// ```
class DeleteConfirmDialog extends StatelessWidget {
  /// Title displayed below the warning icon.
  final String title;

  /// Explanatory message shown below the title.
  final String message;

  /// Called when the user taps "Delete". The dialog is automatically closed
  /// before invoking this callback.
  final VoidCallback onConfirm;

  const DeleteConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
  });

  /// Convenience method that shows the dialog and returns `true` when the user
  /// confirms, `false` when they cancel, or `null` when dismissed.
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return DeleteConfirmDialog(
          title: title,
          message: message,
          onConfirm: () => Navigator.of(dialogContext).pop(true),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Warning icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppTheme.errorColor,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),

          // Message
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        Row(
          children: [
            // Cancel
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                  side: BorderSide(color: Colors.grey.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),

            // Delete
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                  onConfirm();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Delete'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
