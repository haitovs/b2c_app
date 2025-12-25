import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Professional attention-seeking animation widget
/// Inspired by flutter_animate and flutter_bounceable packages
///
/// Usage:
/// ```dart
/// AttentionSeeker(
///   animate: _showHighlight,
///   child: MyWidget(),
/// )
/// ```
class AttentionSeeker extends StatefulWidget {
  final Widget child;
  final bool animate;
  final Duration duration;
  final Color glowColor;
  final int repeatCount;
  final VoidCallback? onAnimationComplete;

  const AttentionSeeker({
    super.key,
    required this.child,
    this.animate = false,
    this.duration = const Duration(milliseconds: 600),
    this.glowColor = Colors.greenAccent,
    this.repeatCount = 3,
    this.onAnimationComplete,
  });

  @override
  State<AttentionSeeker> createState() => _AttentionSeekerState();
}

class _AttentionSeekerState extends State<AttentionSeeker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  int _currentRepeat = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // Slower for smoother feel
    );

    // Gentle scale animation - smaller movements
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.05, // Reduced from 1.12
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.05,
          end: 0.98, // Reduced from 0.96
        ).chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.98, end: 1.0).chain(
          CurveTween(curve: Curves.easeOutCubic),
        ), // Smoother than elasticOut
        weight: 30,
      ),
    ]).animate(_controller);

    // Smooth glow fade in/out
    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 0.8, // Reduced from 1.0 for subtler glow
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(tween: Tween<double>(begin: 0.8, end: 0.5), weight: 40),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.5,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
    ]).animate(_controller);

    _controller.addStatusListener(_handleAnimationStatus);
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _currentRepeat++;
      if (_currentRepeat < widget.repeatCount && widget.animate) {
        _controller.forward(from: 0);
      } else {
        _currentRepeat = 0;
        widget.onAnimationComplete?.call();
      }
    }
  }

  @override
  void didUpdateWidget(AttentionSeeker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !oldWidget.animate) {
      // Start animation
      _currentRepeat = 0;
      _controller.forward(from: 0);
    } else if (!widget.animate && oldWidget.animate) {
      // Stop animation
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_handleAnimationStatus);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final glowOpacity = _glowAnimation.value;
        final scale = widget.animate ? _scaleAnimation.value : 1.0;

        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: widget.animate && glowOpacity > 0
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: widget.glowColor.withValues(
                          alpha: 0.6 * glowOpacity,
                        ),
                        blurRadius: 24 * glowOpacity,
                        spreadRadius: 4 * glowOpacity,
                      ),
                      // Inner glow
                      BoxShadow(
                        color: widget.glowColor.withValues(
                          alpha: 0.3 * glowOpacity,
                        ),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  )
                : null,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Ripple circles that expand outward - for extra emphasis
class ExpandingRipple extends StatefulWidget {
  final bool animate;
  final Color color;
  final double size;
  final int rippleCount;

  const ExpandingRipple({
    super.key,
    this.animate = false,
    this.color = Colors.greenAccent,
    this.size = 60,
    this.rippleCount = 2,
  });

  @override
  State<ExpandingRipple> createState() => _ExpandingRippleState();
}

class _ExpandingRippleState extends State<ExpandingRipple>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void didUpdateWidget(ExpandingRipple oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !oldWidget.animate) {
      _controller.repeat();
    } else if (!widget.animate && oldWidget.animate) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return SizedBox(
          width: widget.size * 2,
          height: widget.size * 2,
          child: Stack(
            alignment: Alignment.center,
            children: List.generate(widget.rippleCount, (index) {
              // Offset each ripple
              final delay = index / widget.rippleCount;
              final progress = (_controller.value + delay) % 1.0;
              final scale = 0.5 + (progress * 1.0);
              final opacity = math.max(0.0, 1.0 - progress);

              return Transform.scale(
                scale: scale,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.color.withValues(alpha: opacity * 0.6),
                      width: 2,
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
