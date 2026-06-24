import 'package:flutter/material.dart';
import '../theme/app_typography.dart';

class ProgressStepper extends StatelessWidget {
  final int currentStep;
  final List<String>? labels;

  const ProgressStepper({
    super.key,
    required this.currentStep,
    this.labels,
  });

  static const List<String> _defaultLabels = ['1', '2', '3', '4'];

  @override
  Widget build(BuildContext context) {
    final stepLabels = labels ?? _defaultLabels;
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final isCompleted = index < currentStep;
        final isCurrent = index == currentStep - 1;
        return Row(
          children: [
            _buildStep(
                colorScheme, index + 1, isCompleted, isCurrent, stepLabels[index]),
            if (index < 3) _buildConnector(colorScheme, isCompleted),
          ],
        );
      }),
    );
  }

  Widget _buildStep(ColorScheme colorScheme, int step, bool isCompleted,
      bool isCurrent, String label) {
    final Color backgroundColor;
    final Color textColor;
    final Color borderColor;

    if (isCompleted) {
      backgroundColor = colorScheme.primary;
      textColor = colorScheme.onPrimary;
      borderColor = colorScheme.primary;
    } else if (isCurrent) {
      backgroundColor = colorScheme.primaryFixed;
      textColor = colorScheme.onPrimaryFixed;
      borderColor = colorScheme.primary;
    } else {
      backgroundColor = colorScheme.surfaceContainerLow;
      textColor = colorScheme.onSurfaceVariant;
      borderColor = colorScheme.outlineVariant;
    }

    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Center(
            child: isCompleted
                ? Icon(Icons.check, color: colorScheme.onPrimary, size: 20)
                : Text(
                    label,
                    style: AppTypography.labelBold.copyWith(color: textColor),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnector(ColorScheme colorScheme, bool isCompleted) {
    return Container(
      width: 32,
      height: 2,
      color: isCompleted ? colorScheme.primary : colorScheme.outlineVariant,
    );
  }
}