import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Styled **top-positioned** toast notification with icon, shadow, and slide
/// animation. Appears from the top, auto-dismisses, and can be swiped away.
///
/// Uses an [Overlay] instead of [SnackBar] so it renders at the top of the
/// screen regardless of Scaffold configuration.
///
/// ```dart
/// AppSnackBar.showSuccess(context, 'Company saved!');
/// AppSnackBar.showError(context, 'Failed to save');
/// AppSnackBar.showInfo(context, 'Copied to clipboard');
/// AppSnackBar.showWarning(context, 'Check your input');
/// ```
class AppSnackBar {
  AppSnackBar._();

  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

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

  /// Immediately remove the current toast if visible.
  static void dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _currentEntry?.remove();
    _currentEntry = null;
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  static void _show(
    BuildContext context, {
    required String message,
    required _SnackType type,
  }) {
    // Remove any existing toast first
    dismiss();

    final overlay = Overlay.of(context, rootOverlay: true);
    final config = _configFor(type);
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _TopToast(
        message: message,
        config: config,
        topPadding: topPadding,
        onDismiss: () {
          dismiss();
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);

    // Auto-dismiss after duration
    _dismissTimer = Timer(Duration(seconds: config.durationSeconds), dismiss);
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

// =============================================================================
// Toast widget with slide-down animation
// =============================================================================

class _TopToast extends StatefulWidget {
  final String message;
  final _SnackConfig config;
  final double topPadding;
  final VoidCallback onDismiss;

  const _TopToast({
    required this.message,
    required this.config,
    required this.topPadding,
    required this.onDismiss,
  });

  @override
  State<_TopToast> createState() => _TopToastState();
}

class _TopToastState extends State<_TopToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.topPadding + 8,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Dismissible(
            key: UniqueKey(),
            direction: DismissDirection.up,
            onDismissed: (_) => widget.onDismiss(),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: widget.config.color,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: widget.config.color.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(widget.config.icon,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    // Message
                    Expanded(
                      child: Text(
                        widget.message,
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
                    const SizedBox(width: 8),
                    // Close button
                    GestureDetector(
                      onTap: widget.onDismiss,
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Config
// =============================================================================

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
