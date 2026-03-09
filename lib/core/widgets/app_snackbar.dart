import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Styled top-positioned snackbar with icon, shadow, and smooth animation.
///
/// Usage:
/// ```dart
/// AppSnackBar.showSuccess(context, 'Company saved!');
/// AppSnackBar.showError(context, 'Failed to save');
/// AppSnackBar.showInfo(context, 'Copied to clipboard');
/// AppSnackBar.showWarning(context, 'Check your input');
/// ```
class AppSnackBar {
  AppSnackBar._();

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  static void showSuccess(BuildContext context, String message) {
    _show(context, message: message, type: _SnackType.success);
  }

  static void showError(BuildContext context, String message) {
    _show(context, message: message, type: _SnackType.error);
  }

  static void showInfo(BuildContext context, String message) {
    _show(context, message: message, type: _SnackType.info);
  }

  static void showWarning(BuildContext context, String message) {
    _show(context, message: message, type: _SnackType.warning);
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  static void _show(
    BuildContext context, {
    required String message,
    required _SnackType type,
  }) {
    // Remove any existing snackbar first
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final config = _configFor(type);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(config.icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  height: 1.3,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: config.color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(top: 12, left: 16, right: 16, bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
        dismissDirection: DismissDirection.horizontal,
        duration: Duration(seconds: config.durationSeconds),
        action: SnackBarAction(
          label: '✕',
          textColor: Colors.white.withValues(alpha: 0.8),
          onPressed: () =>
              ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  static _SnackConfig _configFor(_SnackType type) {
    switch (type) {
      case _SnackType.success:
        return const _SnackConfig(
          color: Color(0xFF2E7D32),
          icon: Icons.check_circle_rounded,
          durationSeconds: 3,
        );
      case _SnackType.error:
        return const _SnackConfig(
          color: Color(0xFFC62828),
          icon: Icons.error_rounded,
          durationSeconds: 4,
        );
      case _SnackType.warning:
        return const _SnackConfig(
          color: Color(0xFFE65100),
          icon: Icons.warning_amber_rounded,
          durationSeconds: 4,
        );
      case _SnackType.info:
        return const _SnackConfig(
          color: Color(0xFF1565C0),
          icon: Icons.info_rounded,
          durationSeconds: 3,
        );
    }
  }
}

enum _SnackType { success, error, warning, info }

class _SnackConfig {
  final Color color;
  final IconData icon;
  final int durationSeconds;

  const _SnackConfig({
    required this.color,
    required this.icon,
    required this.durationSeconds,
  });
}
