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

/// Table header: a 40 px band with the column labels, laid out with the
/// same padding and gap as the rows below it.
///
/// [cells] are the columns, left to right.
class TableHeaderRow extends StatelessWidget {
  const TableHeaderRow({super.key, required this.cells});

  final List<TableHeaderCell> cells;

  static const double _height = 40;

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
      height: _height,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      color: AppColors.bgSubtle,
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
