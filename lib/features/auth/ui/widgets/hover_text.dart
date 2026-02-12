import 'package:flutter/material.dart';

/// Reusable hover text widget for clickable text with hover color effect.
class HoverText extends StatefulWidget {
  final String text;
  final TextStyle baseStyle;
  final Color hoverColor;
  final TextDecoration? decoration;

  const HoverText({
    super.key,
    required this.text,
    required this.baseStyle,
    required this.hoverColor,
    this.decoration,
  });

  @override
  State<HoverText> createState() => _HoverTextState();
}

class _HoverTextState extends State<HoverText> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Text(
        widget.text,
        style: widget.baseStyle.copyWith(
          color: _isHovering ? widget.hoverColor : widget.baseStyle.color,
          decoration: widget.decoration,
        ),
      ),
    );
  }
}
