import 'package:flutter/material.dart';

import '../data/prototype_labels.dart';
import '../data/models.dart';
import '../theme/tokens.dart';

/// Pill with a 6 px dot and a Badge-style label; base of every badge.
class MsBadge extends StatelessWidget {
  const MsBadge({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.dotColor,
    this.compact = false,
  });

  final String label;
  final Color background;
  final Color foreground;
  final Color? dotColor;

  /// Status-pill sizing (padding 10 x 4, gap 6) instead of the 24 px badge.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? null : 24,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : MsSpace.sm,
        vertical: compact ? MsSpace.xs : 0,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(MsRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor ?? foreground,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: compact ? 6 : MsSpace.xs),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: MsText.badge.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}

/// Decision verdict (`decision.verdict`). [degraded] marks a rules-only
/// decision.
class VerdictBadge extends StatelessWidget {
  const VerdictBadge({super.key, required this.verdict, this.degraded = false});

  final Verdict verdict;
  final bool degraded;

  @override
  Widget build(BuildContext context) {
    if (degraded) {
      return const MsBadge(
        label: 'Degradada',
        background: MsColors.bgSubtle,
        foreground: MsColors.textSecondary,
      );
    }
    switch (verdict) {
      case Verdict.approve:
        return MsBadge(
          label: verdictLabel(verdict),
          background: MsColors.approveBg,
          foreground: MsColors.approve,
        );
      case Verdict.review:
        return MsBadge(
          label: verdictLabel(verdict),
          background: MsColors.reviewBg,
          foreground: MsColors.review,
        );
      case Verdict.block:
        return MsBadge(
          label: verdictLabel(verdict),
          background: MsColors.blockBg,
          foreground: MsColors.block,
        );
    }
  }
}

/// Rule version lifecycle (`rule_version.status`).
class RuleStatusBadge extends StatelessWidget {
  const RuleStatusBadge({super.key, required this.status});

  final RuleStatus status;

  @override
  Widget build(BuildContext context) {
    final label = ruleStatusLabel(status);
    switch (status) {
      case RuleStatus.draft:
        return MsBadge(
          label: label,
          background: MsColors.bgSubtle,
          foreground: MsColors.textSecondary,
        );
      case RuleStatus.shadow:
        return MsBadge(
          label: label,
          background: MsColors.accentSubtle,
          foreground: MsColors.accent,
        );
      case RuleStatus.pendingApproval:
        return MsBadge(
          label: label,
          background: MsColors.reviewBg,
          foreground: MsColors.review,
        );
      case RuleStatus.active:
        return MsBadge(
          label: label,
          background: MsColors.approveBg,
          foreground: MsColors.approve,
        );
      case RuleStatus.retired:
        return MsBadge(
          label: label,
          background: MsColors.bgSubtle,
          foreground: MsColors.textTertiary,
        );
    }
  }
}

enum StatusTone { success, accent, neutral, warning, danger }

/// Status of a model version or any other entity.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.tone});

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (tone) {
      StatusTone.success => (MsColors.approveBg, MsColors.approve),
      StatusTone.accent => (MsColors.accentSubtle, MsColors.accent),
      StatusTone.neutral => (MsColors.bgSubtle, MsColors.textSecondary),
      StatusTone.warning => (MsColors.reviewBg, MsColors.review),
      StatusTone.danger => (MsColors.blockBg, MsColors.block),
    };
    return MsBadge(label: label, background: bg, foreground: fg, compact: true);
  }
}
