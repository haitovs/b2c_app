import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';

/// A multi-step progress indicator with percentage text.
///
/// Renders a horizontal bar divided into [totalSteps] segments. Segments up to
/// [currentStep] are filled with [AppTheme.primaryColor]; the rest are grey.
/// Step dots sit on the bar to indicate each checkpoint, and optional labels
/// can be displayed below the dots.
///
/// ```dart
/// StepProgressBar(
///   currentStep: 2,
///   totalSteps: 4,
///   stepLabels: ['Info', 'Docs', 'Review', 'Done'],
/// )
/// ```
class StepProgressBar extends StatelessWidget {
  /// The current active step (1-based). A value of 0 means no steps are
  /// completed; [totalSteps] means all steps are completed.
  final int currentStep;

  /// Total number of steps.
  final int totalSteps;

  /// Optional labels displayed beneath each step dot. When provided its length
  /// should equal [totalSteps].
  final List<String>? stepLabels;

  const StepProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.stepLabels,
  });

  @override
  Widget build(BuildContext context) {
    final clampedStep = currentStep.clamp(0, totalSteps);
    final percentage =
        totalSteps > 0 ? ((clampedStep / totalSteps) * 100).round() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Percentage label
        Text(
          '$percentage% Complete',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 8),

        // Bar + dots
        LayoutBuilder(
          builder: (context, constraints) {
            final totalWidth = constraints.maxWidth;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Background bar
                Container(
                  height: 6,
                  width: totalWidth,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),

                // Filled portion
                Container(
                  height: 6,
                  width: totalSteps > 0
                      ? totalWidth * (clampedStep / totalSteps)
                      : 0,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),

                // Step dots
                for (int i = 0; i < totalSteps; i++)
                  Positioned(
                    left: totalSteps > 1
                        ? (totalWidth - _dotSize) * (i / (totalSteps - 1))
                        : 0,
                    top: -((_dotSize - 6) / 2), // vertically center on bar
                    child: _StepDot(isFilled: i < clampedStep),
                  ),
              ],
            );
          },
        ),

        // Optional step labels
        if (stepLabels != null && stepLabels!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: stepLabels!.map((label) {
              final index = stepLabels!.indexOf(label);
              final isFilled = index < clampedStep;
              return Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight:
                        isFilled ? FontWeight.w600 : FontWeight.w400,
                    color: isFilled
                        ? AppTheme.primaryColor
                        : Colors.grey.shade500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  static const double _dotSize = 16;
}

class _StepDot extends StatelessWidget {
  final bool isFilled;

  const _StepDot({required this.isFilled});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: StepProgressBar._dotSize,
      height: StepProgressBar._dotSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isFilled ? AppTheme.primaryColor : Colors.white,
        border: Border.all(
          color: isFilled ? AppTheme.primaryColor : Colors.grey.shade400,
          width: 2,
        ),
      ),
      child: isFilled
          ? const Icon(Icons.check, size: 10, color: Colors.white)
          : null,
    );
  }
}
