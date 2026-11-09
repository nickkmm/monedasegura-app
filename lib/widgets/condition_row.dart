import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../data/models.dart';
import '../theme/tokens.dart';
import 'ms_icon.dart';

/// One clause of a rule's condition: feature, operator, value and a remove
/// button. [onChanged] and [onRemove] are null when the version is read-only.
class ConditionRow extends StatefulWidget {
  const ConditionRow({
    super.key,
    required this.condition,
    this.onChanged,
    this.onRemove,
  });

  final RuleCondition condition;
  final ValueChanged<RuleCondition>? onChanged;
  final VoidCallback? onRemove;

  @override
  State<ConditionRow> createState() => _ConditionRowState();
}

class _ConditionRowState extends State<ConditionRow> {
  late final TextEditingController _value = TextEditingController(
    text: widget.condition.value,
  );

  @override
  void didUpdateWidget(ConditionRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A row above was removed and this slot now shows another condition.
    if (_value.text != widget.condition.value) {
      _value.text = widget.condition.value;
    }
  }

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  Widget _box({required Widget child, double? width}) {
    return Container(
      width: width,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: MsSpace.md),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: MsColors.bgSurface,
        border: Border.all(color: MsColors.borderDefault),
        borderRadius: BorderRadius.circular(MsRadius.md),
      ),
      child: child,
    );
  }

  Widget _dropdown(
    String value,
    List<String> options,
    TextStyle style,
    ValueChanged<String>? onChanged,
  ) {
    final items = options.contains(value) ? options : [value, ...options];
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        isDense: true,
        icon: const SizedBox.shrink(),
        style: style,
        onChanged: onChanged == null ? null : (v) => onChanged(v!),
        items: [
          for (final item in items)
            DropdownMenuItem(
              value: item,
              child: Text(item, style: style),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editable = widget.onChanged != null;
    final c = widget.condition;
    return Row(
      children: [
        _box(
          width: 220,
          child: _dropdown(
            c.feature,
            featureNames,
            MsText.body.copyWith(color: MsColors.accent),
            editable ? (v) => widget.onChanged!(c.copyWith(feature: v)) : null,
          ),
        ),
        const SizedBox(width: MsSpace.sm),
        _box(
          width: 90,
          child: _dropdown(
            c.operator,
            ruleOperators,
            MsText.body,
            editable ? (v) => widget.onChanged!(c.copyWith(operator: v)) : null,
          ),
        ),
        const SizedBox(width: MsSpace.sm),
        Expanded(
          child: _box(
            child: TextField(
              controller: _value,
              enabled: editable,
              style: MsText.body,
              cursorColor: MsColors.accent,
              decoration: const InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
              ),
              onChanged: editable
                  ? (v) => widget.onChanged!(c.copyWith(value: v))
                  : null,
            ),
          ),
        ),
        const SizedBox(width: MsSpace.sm),
        SizedBox(
          width: 20,
          child: widget.onRemove == null
              ? null
              : MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: widget.onRemove,
                    child: const MsIcon(
                      MsIconName.x,
                      color: MsColors.textTertiary,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
