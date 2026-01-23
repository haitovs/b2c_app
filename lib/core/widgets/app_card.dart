import 'package:flutter/material.dart';

/// Reusable card wrapper with consistent styling
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? borderRadius;
  final Color? color;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(borderRadius ?? 12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
