import 'package:flutter/material.dart';

/// Wraps a child in a staggered fade + slide animation based on its index.
///
/// Use in lists/grids for a smooth cascading reveal effect:
/// ```dart
/// ListView.builder(
///   itemCount: items.length,
///   itemBuilder: (context, index) => StaggeredFadeIn(
///     index: index,
///     child: MyCard(item: items[index]),
///   ),
/// )
/// ```
class StaggeredFadeIn extends StatefulWidget {
  final int index;
  final Widget child;
  final Duration baseDelay;
  final Duration duration;

  const StaggeredFadeIn({
    super.key,
    required this.index,
    required this.child,
    this.baseDelay = const Duration(milliseconds: 50),
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  State<StaggeredFadeIn> createState() => _StaggeredFadeInState();
}

class _StaggeredFadeInState extends State<StaggeredFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    final curved = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _opacity = Tween<double>(begin: 0, end: 1).animate(curved);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(curved);

    // Cap stagger delay to avoid very long waits for large lists
    final cappedIndex = widget.index.clamp(0, 10);
    final delay = widget.baseDelay * cappedIndex;
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _opacity,
        child: widget.child,
      ),
    );
  }
}
