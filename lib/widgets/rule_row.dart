import 'package:flutter/material.dart';

import '../data/format.dart';
import '../data/labels.dart';
import '../data/models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'rule_status_badge.dart';

/// Rules list row: a 64 px row with the rule's latest version — code and
/// description, version, action, status, 7-day hits, precision, last
/// change and a chevron.
///
/// [rule] is the rule to show; the row reads `rule.latest`. [now] is the
/// reference time for the last change ("hoy", "ayer"). [onTap] is called
/// on tap; `null` makes the row read-only (no click cursor, no tap
/// handling). [compact] is for narrow tables: the last change shows only the
/// date, in a column of [compactDateWidth], and the rule column takes the
/// remaining space instead of its fixed 300 px.
class RuleRow extends StatefulWidget {
  const RuleRow({
    super.key,
    required this.rule,
    required this.now,
    this.onTap,
    this.compact = false,
  });

  static const double compactDateWidth = 84;

  final RuleView rule;
  final DateTime now;
  final VoidCallback? onTap;
  final bool compact;

  @override
  State<RuleRow> createState() => _RuleRowState();
}

class _RuleRowState extends State<RuleRow> {
  static const double _height = 64;

  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final rule = widget.rule.rule;
    final latest = widget.rule.latest;
    final enabled = widget.onTap != null;
    final backtest = latest.backtest;
    final hits = latest.hits7d == null ? '—' : formatInt(latest.hits7d!);
    final date = formatDayAgo(
      latest.submittedAt ?? latest.createdAt,
      widget.now,
    );
    final precision =
        backtest == null ||
            latest.status == RuleStatus.RETIRED ||
            latest.status == RuleStatus.DRAFT
        ? '—'
        : formatDecimal(backtest.candidate.precision);
    final strong = AppTextStyles.bodyStrong.copyWith(
      color: AppColors.textPrimary,
    );
    const gap = SizedBox(width: AppSpacing.lg);
    final ruleCell = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rule.code,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: strong,
        ),
        Text(
          rule.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
    Widget lastChange(String text) => Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.right,
      style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
    );

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          height: _height,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          decoration: BoxDecoration(
            color: _hover ? AppColors.bgHover : AppColors.bgSurface,
            border: const Border(
              bottom: BorderSide(color: AppColors.borderDefault),
            ),
          ),
          child: Row(
            children: [
              if (widget.compact)
                Expanded(child: ruleCell)
              else
                SizedBox(width: 300, child: ruleCell),
              gap,
              SizedBox(
                width: 56,
                child: Text(
                  'v${latest.version}',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              gap,
              SizedBox(
                width: 96,
                child: Text(
                  latest.action.label,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              gap,
              SizedBox(
                width: 130,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: RuleStatusBadge(status: latest.status),
                ),
              ),
              gap,
              SizedBox(
                width: 90,
                child: Text(hits, textAlign: TextAlign.right, style: strong),
              ),
              gap,
              SizedBox(
                width: 80,
                child: Text(
                  precision,
                  textAlign: TextAlign.right,
                  style: strong,
                ),
              ),
              gap,
              if (widget.compact)
                SizedBox(
                  width: RuleRow.compactDateWidth,
                  child: lastChange(date),
                )
              else
                Expanded(
                  child: lastChange('$date · ${latest.createdBy.fullName}'),
                ),
              gap,
              Icon(
                AppIcons.chevronRight,
                size: AppIcons.size,
                color: _hover ? AppColors.textPrimary : AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
