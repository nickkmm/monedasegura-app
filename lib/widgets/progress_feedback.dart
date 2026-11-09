import 'package:flutter/material.dart';

import '../data/models.dart';
import '../theme/tokens.dart';
import 'badges.dart';
import 'ms_icon.dart';

enum FlowStepState { done, current, pending }

/// One step of the rule-lifecycle stepper.
class StepperStep extends StatelessWidget {
  const StepperStep({super.key, required this.label, required this.state});

  final String label;
  final FlowStepState state;

  @override
  Widget build(BuildContext context) {
    Widget dot;
    switch (state) {
      case FlowStepState.done:
        dot = Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: MsColors.bgInverse,
            shape: BoxShape.circle,
          ),
          child: const MsIcon(MsIconName.check, size: 12, color: Colors.white),
        );
      case FlowStepState.current:
        dot = Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: MsColors.reviewBg,
            shape: BoxShape.circle,
            border: Border.all(color: MsColors.review, width: 1.5),
          ),
        );
      case FlowStepState.pending:
        dot = Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: MsColors.bgSurface,
            shape: BoxShape.circle,
            border: Border.all(color: MsColors.borderStrong),
          ),
        );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        dot,
        const SizedBox(width: MsSpace.xs),
        Text(
          label,
          style: MsText.caption.copyWith(
            color: state == FlowStepState.pending
                ? MsColors.textTertiary
                : MsColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// Dot, title and meta line of an approval history.
class TimelineEvent extends StatelessWidget {
  const TimelineEvent({super.key, required this.title, required this.meta});

  final String title;
  final String meta;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: MsColors.bgInverse,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: MsSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: MsText.bodyStrong),
              const SizedBox(height: MsSpace.xxs),
              Text(meta, style: MsText.caption),
            ],
          ),
        ),
      ],
    );
  }
}

/// Inline information banner with a Shadow badge.
class MsBanner extends StatelessWidget {
  const MsBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MsSpace.md,
        vertical: MsSpace.sm,
      ),
      decoration: BoxDecoration(
        color: MsColors.accentSubtle,
        borderRadius: BorderRadius.circular(MsRadius.md),
      ),
      child: Row(
        children: [
          const RuleStatusBadge(status: RuleStatus.shadow),
          const SizedBox(width: MsSpace.sm),
          Expanded(
            child: Text(
              message,
              style: MsText.caption.copyWith(color: MsColors.accent),
            ),
          ),
        ],
      ),
    );
  }
}

/// Centered icon, title and hint for screens without data yet.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.hint,
    this.icon = MsIconName.play,
  });

  final String title;
  final String hint;
  final MsIconName icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: MsColors.bgSubtle,
              shape: BoxShape.circle,
            ),
            child: MsIcon(icon, color: MsColors.textSecondary),
          ),
          const SizedBox(height: MsSpace.sm),
          Text(title, style: MsText.bodyStrong),
          const SizedBox(height: MsSpace.sm),
          Text(hint, style: MsText.caption, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
