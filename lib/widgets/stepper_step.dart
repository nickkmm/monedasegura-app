import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// State of one step of the stepper (Figma "Stepper step" `32:1405`).
/// Prefixed with `Stepper` to avoid the step enum Flutter's Material
/// library already exports.
///
/// [done] steps are finished, [current] is the one in progress and
/// [pending] steps are still ahead.
enum StepperStepState { done, current, pending }

/// One step of the stepper (Figma "Stepper step" `32:1405`): a circle and
/// a label.
///
/// [label] is the Spanish text and [state] picks the circle and the label
/// color.
class StepperStep extends StatelessWidget {
  const StepperStep({super.key, required this.label, required this.state});

  final String label;
  final StepperStepState state;

  static const double _circle = 20;
  static const double _check = 12;
  static const double _currentBorder = 1.5;

  @override
  Widget build(BuildContext context) {
    final decoration = switch (state) {
      StepperStepState.done => const BoxDecoration(
        color: AppColors.bgInverse,
        shape: BoxShape.circle,
      ),
      StepperStepState.current => BoxDecoration(
        color: AppColors.statusReviewBg,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.statusReview,
          width: _currentBorder,
        ),
      ),
      StepperStepState.pending => BoxDecoration(
        color: AppColors.bgSurface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.borderStrong),
      ),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: _circle,
          height: _circle,
          alignment: Alignment.center,
          decoration: decoration,
          child: state == StepperStepState.done
              ? const Icon(
                  AppIcons.check,
                  size: _check,
                  color: AppColors.textInverse,
                )
              : null,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: state == StepperStepState.pending
                ? AppColors.textTertiary
                : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// Row of steps joined by connectors (Figma "Stepper" `9:904`).
///
/// [steps] are the label and state of each step, in order. A connector is
/// dark when the step before it is done.
class AppStepper extends StatelessWidget {
  const AppStepper({super.key, required this.steps});

  final List<(String, StepperStepState)> steps;

  static const double _connectorWidth = 28;
  static const double _connectorHeight = 1.5;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0) ...[
            const SizedBox(width: AppSpacing.sm),
            Container(
              width: _connectorWidth,
              height: _connectorHeight,
              color: steps[i - 1].$2 == StepperStepState.done
                  ? AppColors.bgInverse
                  : AppColors.borderStrong,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          StepperStep(label: steps[i].$1, state: steps[i].$2),
        ],
      ],
    );
  }
}
