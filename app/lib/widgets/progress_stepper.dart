import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final isCompleted = index < currentStep;
        final isCurrent = index == currentStep - 1;
        return Row(
          children: [
            _buildStep(index + 1, isCompleted, isCurrent, stepLabels[index]),
            if (index < 3) _buildConnector(isCompleted),
          ],
        );
      }),
    );
  }

  Widget _buildStep(int step, bool isCompleted, bool isCurrent, String label) {
    final Color backgroundColor;
    final Color textColor;
    final Color borderColor;

    if (isCompleted) {
      backgroundColor = AppColors.primary;
      textColor = AppColors.onPrimary;
      borderColor = AppColors.primary;
    } else if (isCurrent) {
      backgroundColor = AppColors.primaryFixed;
      textColor = AppColors.onPrimaryFixed;
      borderColor = AppColors.primary;
    } else {
      backgroundColor = AppColors.surfaceContainerLow;
      textColor = AppColors.onSurfaceVariant;
      borderColor = AppColors.outlineVariant;
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
                ? const Icon(Icons.check, color: AppColors.onPrimary, size: 20)
                : Text(
                    label,
                    style: AppTypography.labelBold.copyWith(color: textColor),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnector(bool isCompleted) {
    return Container(
      width: 32,
      height: 2,
      color: isCompleted ? AppColors.primary : AppColors.outlineVariant,
    );
  }
}