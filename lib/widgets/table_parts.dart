import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Gives [child] at least [minWidth]; scrolls horizontally when the window is
/// narrower (tables use fixed column widths from the design).
class MinWidthScroll extends StatelessWidget {
  const MinWidthScroll({
    super.key,
    required this.minWidth,
    required this.child,
  });

  final double minWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= minWidth) return child;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: minWidth, child: child),
        );
      },
    );
  }
}

/// A table row with a bottom border and a hover background.
class HoverRow extends StatefulWidget {
  const HoverRow({
    super.key,
    required this.height,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: MsSpace.xl),
    this.showBorder = true,
  });

  final double height;
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final bool showBorder;

  @override
  State<HoverRow> createState() => _HoverRowState();
}

class _HoverRowState extends State<HoverRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          height: widget.height,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: _hover && widget.onTap != null
                ? MsColors.bgHover
                : MsColors.bgSurface,
            border: widget.showBorder
                ? const Border(
                    bottom: BorderSide(color: MsColors.borderDefault),
                  )
                : null,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Header strip of a table: 40 px, subtle background, Label-style cells.
class TableHeader extends StatelessWidget {
  const TableHeader({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: MsSpace.xl),
      color: MsColors.bgSubtle,
      child: Row(children: children),
    );
  }
}

/// Fixed-width header cell. [right] aligns the text to the right.
class HeaderCell extends StatelessWidget {
  const HeaderCell(this.label, {super.key, this.width, this.right = false});

  final String label;
  final double? width;
  final bool right;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: right ? TextAlign.right : TextAlign.left,
      style: MsText.label,
    );
    return width == null ? text : SizedBox(width: width, child: text);
  }
}

/// Rounded chip used for filters ("Veredicto: todos").
class FilterChipButton extends StatelessWidget {
  const FilterChipButton({super.key, required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: MsSpace.md),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: MsColors.bgSurface,
            border: Border.all(color: MsColors.borderDefault),
            borderRadius: BorderRadius.circular(MsRadius.full),
          ),
          child: Text(label, style: MsText.caption),
        ),
      ),
    );
  }
}
