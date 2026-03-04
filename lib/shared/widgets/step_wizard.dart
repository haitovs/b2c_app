import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';

/// A horizontal step indicator showing progress through a multi-step wizard.
///
/// Each step is rendered as a numbered circle with a label below. Completed
/// steps display a green check, the active step uses [AppTheme.primaryColor],
/// and future steps are grey-outlined. Steps are connected by horizontal lines.
///
/// ```dart
/// StepWizard(
///   currentStep: 1,
///   stepLabels: ['Personal Info', 'Role in Event', 'Confirmation'],
/// )
/// ```
class StepWizard extends StatelessWidget {
  /// The currently active step (0-indexed).
  final int currentStep;

  /// Labels for each step. The length determines the total number of steps.
  final List<String> stepLabels;

  const StepWizard({
    super.key,
    required this.currentStep,
    required this.stepLabels,
  });

  @override
  Widget build(BuildContext context) {
    final stepCount = stepLabels.length;
    if (stepCount == 0) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: List.generate(stepCount * 2 - 1, (index) {
            // Even indices are step circles; odd indices are connecting lines.
            if (index.isEven) {
              final stepIndex = index ~/ 2;
              return _StepItem(
                stepIndex: stepIndex,
                label: stepLabels[stepIndex],
                state: _stateFor(stepIndex),
              );
            } else {
              final beforeStepIndex = index ~/ 2;
              final isCompleted = beforeStepIndex < currentStep;
              return Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.only(bottom: 20),
                  color: isCompleted
                      ? AppTheme.successColor
                      : Colors.grey.shade300,
                ),
              );
            }
          }),
        );
      },
    );
  }

  _StepState _stateFor(int index) {
    if (index < currentStep) return _StepState.completed;
    if (index == currentStep) return _StepState.active;
    return _StepState.future;
  }
}

enum _StepState { completed, active, future }

class _StepItem extends StatelessWidget {
  final int stepIndex;
  final String label;
  final _StepState state;

  const _StepItem({
    required this.stepIndex,
    required this.label,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Circle
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _circleColor,
            border: state == _StepState.future
                ? Border.all(color: Colors.grey.shade400, width: 2)
                : null,
          ),
          child: Center(child: _circleContent),
        ),
        const SizedBox(height: 6),

        // Label
        SizedBox(
          width: 80,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight:
                  state == _StepState.active ? FontWeight.w600 : FontWeight.w400,
              color: state == _StepState.future
                  ? Colors.grey.shade500
                  : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Color get _circleColor {
    switch (state) {
      case _StepState.completed:
        return AppTheme.successColor;
      case _StepState.active:
        return AppTheme.primaryColor;
      case _StepState.future:
        return Colors.transparent;
    }
  }

  Widget get _circleContent {
    switch (state) {
      case _StepState.completed:
        return const Icon(Icons.check, size: 16, color: Colors.white);
      case _StepState.active:
        return Text(
          '${stepIndex + 1}',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        );
      case _StepState.future:
        return Text(
          '${stepIndex + 1}',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade500,
          ),
        );
    }
  }
}
