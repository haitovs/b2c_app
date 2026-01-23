import 'package:flutter/material.dart';

/// Loading indicator utilities
class AppLoading {
  /// Centered circular progress indicator
  static Widget circular({Color? color}) =>
      Center(child: CircularProgressIndicator(color: color));

  /// Full-screen loading overlay with dark background
  static Widget overlay({Color? color}) => Container(
    color: Colors.black54,
    child: Center(
      child: CircularProgressIndicator(color: color ?? Colors.white),
    ),
  );

  /// Small inline loading indicator
  static Widget small({Color? color}) => SizedBox(
    width: 20,
    height: 20,
    child: CircularProgressIndicator(strokeWidth: 2, color: color),
  );
}
