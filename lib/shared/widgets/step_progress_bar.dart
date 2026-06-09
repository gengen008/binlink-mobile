import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';

/// Animated 5-step horizontal progress bar for the booking wizard.
class StepProgressBar extends StatelessWidget {
  const StepProgressBar({
    super.key,
    required this.totalSteps,
    required this.currentStep,
  });

  final int totalSteps;
  final int currentStep; // 0-indexed

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (i) {
        final isDone   = i < currentStep;
        final isActive = i == currentStep;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Circle
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      width: isActive ? 32 : 26,
                      height: isActive ? 32 : 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone || isActive
                            ? AppColors.primary
                            : AppColors.fieldFill,
                        border: Border.all(
                          color: isDone || isActive
                              ? AppColors.primary
                              : AppColors.fieldFill,
                          width: isActive ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(LucideIcons.check,
                                color: AppColors.white, size: 14)
                            : Text(
                                '${i + 1}',
                                style: TextStyle(
                                  color: isDone || isActive
                                      ? Colors.white
                                      : AppColors.muted,
                                  fontWeight: FontWeight.w700,
                                  fontSize: isActive ? 12 : 11,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              // Connector line (not after last step)
              if (i < totalSteps - 1)
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    height: 2,
                    decoration: BoxDecoration(
                      color: i < currentStep
                          ? AppColors.primary
                          : AppColors.fieldFill,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}
