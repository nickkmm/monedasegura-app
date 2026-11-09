import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// One column of a [TableHeaderRow].
///
/// [label] is the Spanish column title. [width] fixes the column width;
/// [flex] makes it take the remaining space; otherwise it takes the
/// label's own width. [align] aligns the label inside the column.
class TableHeaderCell {
  const TableHeaderCell({
    this.label = '',
    this.width,
    this.flex = false,
    this.align = TextAlign.left,
  });

  final String label;
  final double? width;
  final bool flex;
  final TextAlign align;
}

/// Table header: a band with the column labels, laid out with the same
/// padding and gap as the rows below it.
///
/// [cells] are the columns, left to right. [height] is the band height (40
/// by default), [horizontalPadding] the space before the first and after the
/// last column (24 by default) and [radius] its corner radius (0, square, by
/// default).
class TableHeaderRow extends StatelessWidget {
  const TableHeaderRow({
    super.key,
    required this.cells,
    this.height = 40,
    this.horizontalPadding = AppSpacing.xl,
    this.radius = 0,
  });

  final List<TableHeaderCell> cells;
  final double height;
  final double horizontalPadding;
  final double radius;

  Widget _cell(TableHeaderCell cell) {
    final text = Text(
      cell.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: cell.align,
      style: AppTextStyles.label.copyWith(color: AppColors.textTertiary),
    );
    if (cell.width != null) return SizedBox(width: cell.width, child: text);
    if (cell.flex) return Expanded(child: text);
    return text;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      decoration: BoxDecoration(
        color: AppColors.bgSubtle,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Row(
        children: [
          for (var i = 0; i < cells.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.lg),
            _cell(cells[i]),
          ],
        ],
      ),
    );
  }
}
