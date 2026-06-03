import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

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
                        gradient: isDone || isActive
                            ? AppColors.primaryGradient
                            : null,
                        color: isDone || isActive ? null : AppColors.surface,
                        border: Border.all(
                          color: isDone || isActive
                              ? AppColors.steelBlue
                              : AppColors.border,
                          width: isActive ? 2 : 1,
                        ),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: AppColors.steelBlue.withAlpha(80),
                                  blurRadius: 12,
                                  spreadRadius: 0,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(Icons.check_rounded,
                                color: AppColors.white, size: 14)
                            : Text(
                                '${i + 1}',
                                style: AppTextStyles.caption.copyWith(
                                  color: isActive
                                      ? AppColors.white
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
                      gradient: i < currentStep
                          ? AppColors.primaryGradient
                          : null,
                      color: i < currentStep ? null : AppColors.border,
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
