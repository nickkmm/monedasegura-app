import 'package:flutter/material.dart';

import '../data/format.dart';
import '../data/models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// One clause of a rule's condition: feature, operator and value boxes.
///
/// [condition] is the clause to show. When [editable] is `false` each box
/// shows plain text (the value formatted for reading). When it is `true`
/// the feature and operator are dropdowns, the value is a text field and a
/// remove icon follows. [featureNames] are the feature dropdown items (the
/// current feature is always included). [onFeatureChanged],
/// [onOpChanged] and [onValueChanged] report the new feature, operator and
/// raw value text; [onRemove] is called by the remove icon. A `null`
/// callback disables that control.
class ConditionRow extends StatefulWidget {
  const ConditionRow({
    super.key,
    required this.condition,
    this.editable = false,
    this.featureNames = const [],
    this.onFeatureChanged,
    this.onOpChanged,
    this.onValueChanged,
    this.onRemove,
  });

  final Condition condition;
  final bool editable;
  final List<String> featureNames;
  final ValueChanged<String>? onFeatureChanged;
  final ValueChanged<ConditionOp>? onOpChanged;
  final ValueChanged<String>? onValueChanged;
  final VoidCallback? onRemove;

  @override
  State<ConditionRow> createState() => _ConditionRowState();
}

class _ConditionRowState extends State<ConditionRow> {
  static const double _height = 40;
  static const double _featureWidth = 220;
  static const double _opWidth = 90;
  static const Set<String> _copFeatures = {'amount', 'spend_24h'};

  late final TextEditingController _value = TextEditingController(
    text: _rawValue(widget.condition.value),
  );

  @override
  void didUpdateWidget(ConditionRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    final raw = _rawValue(widget.condition.value);
    if (raw != _rawValue(oldWidget.condition.value) && raw != _value.text) {
      _value.text = raw;
    }
  }

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  /// The value as typed: `true`, `2000000`, `0.6`, `a, b`.
  static String _rawValue(Object value) => switch (value) {
    num v when v == v.truncate() => v.toInt().toString(),
    num v => v.toString(),
    List<Object?> v => v.join(', '),
    _ => value.toString(),
  };

  /// The value for reading: `Sí`, `$ 2.000.000`, `0,6`, `a, b`.
  static String _displayValue(String feature, Object value) => switch (value) {
    bool v => v ? 'Sí' : 'No',
    num v when _copFeatures.contains(feature) => formatCop(v.round()),
    // `300,00` reads `300` and `0,60` reads `0,6`.
    num v => formatDecimal(v.toDouble()).replaceFirst(RegExp(r',?0+$'), ''),
    List<Object?> v => v.join(', '),
    _ => value.toString(),
  };

  Widget _box({required Widget child, double? width}) {
    return Container(
      width: width,
      height: _height,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        border: Border.all(color: AppColors.borderDefault),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: child,
    );
  }

  Widget _dropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T) label,
    required TextStyle style,
    required ValueChanged<T>? onChanged,
  }) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        isDense: true,
        icon: const Icon(
          AppIcons.chevronDown,
          size: AppIcons.size,
          color: AppColors.textTertiary,
        ),
        style: style,
        onChanged: onChanged == null ? null : (v) => onChanged(v as T),
        items: [
          for (final item in items)
            DropdownMenuItem<T>(
              value: item,
              child: Text(label(item), style: style),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.condition;
    final featureStyle = AppTextStyles.body.copyWith(color: AppColors.accent);
    final textStyle = AppTextStyles.body.copyWith(color: AppColors.textPrimary);
    const gap = SizedBox(width: AppSpacing.sm);

    if (!widget.editable) {
      Text plain(String text, TextStyle style) => Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
      return Row(
        children: [
          _box(width: _featureWidth, child: plain(c.feature, featureStyle)),
          gap,
          _box(width: _opWidth, child: plain(c.op.symbol, textStyle)),
          gap,
          Expanded(
            child: _box(
              child: plain(_displayValue(c.feature, c.value), textStyle),
            ),
          ),
        ],
      );
    }

    final features = widget.featureNames.contains(c.feature)
        ? widget.featureNames
        : [c.feature, ...widget.featureNames];
    return Row(
      children: [
        _box(
          width: _featureWidth,
          child: _dropdown<String>(
            value: c.feature,
            items: features,
            label: (f) => f,
            style: featureStyle,
            onChanged: widget.onFeatureChanged,
          ),
        ),
        gap,
        _box(
          width: _opWidth,
          child: _dropdown<ConditionOp>(
            value: c.op,
            items: ConditionOp.values,
            label: (op) => op.symbol,
            style: textStyle,
            onChanged: widget.onOpChanged,
          ),
        ),
        gap,
        Expanded(
          child: _box(
            child: TextField(
              controller: _value,
              enabled: widget.onValueChanged != null,
              style: textStyle,
              cursorColor: AppColors.accent,
              decoration: const InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                filled: false,
              ),
              onChanged: widget.onValueChanged,
            ),
          ),
        ),
        gap,
        MouseRegion(
          cursor: widget.onRemove == null
              ? MouseCursor.defer
              : SystemMouseCursors.click,
          child: GestureDetector(
            onTap: widget.onRemove,
            child: Opacity(
              opacity: widget.onRemove == null ? 0.4 : 1,
              child: const Icon(
                AppIcons.close,
                size: AppIcons.size,
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
