import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';

/// Input of the gallery: caption label above a 44 px field. Focus shows a
/// 1.5 px accent border and a 4 px soft ring.
class MsTextField extends StatefulWidget {
  const MsTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.obscure = false,
    this.onChanged,
    this.onSubmitted,
    this.errorText,
    this.height = 44,
    this.keyboardType,
    this.inputFormatters,
    this.enabled = true,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final bool obscure;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? errorText;
  final double height;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;

  @override
  State<MsTextField> createState() => _MsTextFieldState();
}

class _MsTextFieldState extends State<MsTextField> {
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focus.hasFocus;
    final hasError = widget.errorText != null;
    final borderColor = hasError
        ? MsColors.block
        : (focused ? MsColors.borderFocus : MsColors.borderDefault);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.label, style: MsText.caption),
        const SizedBox(height: MsSpace.xs),
        Container(
          height: widget.height,
          padding: const EdgeInsets.symmetric(horizontal: MsSpace.md),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: MsColors.bgSurface,
            borderRadius: BorderRadius.circular(MsRadius.md),
            border: Border.all(color: borderColor, width: focused ? 1.5 : 1),
            boxShadow: focused
                ? const [
                    BoxShadow(
                      color: Color(0x1F3045E8),
                      spreadRadius: 4,
                      blurRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: TextField(
            focusNode: _focus,
            controller: widget.controller,
            obscureText: widget.obscure,
            enabled: widget.enabled,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            keyboardType: widget.keyboardType,
            inputFormatters: widget.inputFormatters,
            style: MsText.body,
            cursorColor: MsColors.accent,
            decoration: InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              hintText: widget.hint,
              hintStyle: MsText.body.copyWith(color: MsColors.textTertiary),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: MsSpace.xs),
          Text(
            widget.errorText!,
            style: MsText.caption.copyWith(color: MsColors.block),
          ),
        ],
      ],
    );
  }
}
