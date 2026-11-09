import 'package:flutter/material.dart';

import '../data/format.dart';
import '../data/models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'score_bar.dart';
import 'verdict_badge.dart';

/// Case queue row: a 60 px row with id, customer, amount, type, score,
/// verdict, age and a chevron.
///
/// [caseView] is the case to show. [now] is the reference time for the
/// age ("hace 4 min"). [onTap] is called on tap; `null` makes the row
/// read-only (no click cursor, no tap handling).
class CaseRow extends StatefulWidget {
  const CaseRow({
    super.key,
    required this.caseView,
    required this.now,
    this.onTap,
  });

  final CaseView caseView;
  final DateTime now;
  final VoidCallback? onTap;

  @override
  State<CaseRow> createState() => _CaseRowState();
}

class _CaseRowState extends State<CaseRow> {
  static const double _height = 60;

  bool _hover = false;

  Widget _cell(double width, String text, TextStyle style) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.caseView;
    final enabled = widget.onTap != null;
    const gap = SizedBox(width: AppSpacing.lg);

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
              _cell(
                112,
                c.shortId,
                AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
              gap,
              _cell(
                200,
                c.customer.maskedName,
                AppTextStyles.bodyStrong.copyWith(color: AppColors.textPrimary),
              ),
              gap,
              _cell(
                140,
                formatCop(c.amount),
                AppTextStyles.bodyStrong.copyWith(color: AppColors.textPrimary),
              ),
              gap,
              _cell(
                150,
                c.typeLabel,
                AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              ),
              gap,
              SizedBox(
                width: 120,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ScoreBar(score: c.score),
                ),
              ),
              gap,
              const SizedBox(width: AppSpacing.xl),
              VerdictBadge(verdict: c.verdict),
              const Spacer(),
              SizedBox(
                width: 84,
                child: Text(
                  formatAgo(c.openedAt, widget.now),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
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
