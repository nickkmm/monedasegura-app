import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Gallery input (Figma "Input" `3:113`): a caption [label] above a 44 px
/// field.
///
/// [controller] holds the text; without one the field owns its own.
/// [hintText] shows while the field is empty. [obscureText], [enabled],
/// [keyboardType] and [readOnly] pass through to the inner [TextField].
/// [onChanged], [onSubmitted] and [onTap] report typing, submit and tap;
/// `null` means the event is not reported. [errorText] turns the border red
/// and shows the message below the field.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.hintText,
    this.obscureText = false,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.errorText,
    this.onTap,
    this.readOnly = false,
  });

  final String label;
  final TextEditingController? controller;
  final String? hintText;
  final bool obscureText;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final String? errorText;
  final VoidCallback? onTap;
  final bool readOnly;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  static const double _height = 44;

  final FocusNode _focusNode = FocusNode();
  TextEditingController? _ownController;

  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() => setState(() {});

  @override
  void dispose() {
    _focusNode.dispose();
    _ownController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final error = widget.errorText;
    final focused = _focusNode.hasFocus && error == null;
    final border = error != null
        ? Border.all(color: AppColors.statusBlock)
        : focused
        ? Border.all(color: AppColors.borderFocus, width: 1.5)
        : Border.all(color: AppColors.borderDefault);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          height: _height,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: border,
            boxShadow: focused ? AppShadows.focusRing : null,
          ),
          child: TextField(
            focusNode: _focusNode,
            controller: _controller,
            obscureText: widget.obscureText,
            enabled: widget.enabled,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            keyboardType: widget.keyboardType,
            onTap: widget.onTap,
            readOnly: widget.readOnly,
            style: AppTextStyles.body,
            cursorColor: AppColors.accent,
            decoration: InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              hintText: widget.hintText,
              hintStyle: AppTextStyles.body.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            error,
            style: AppTextStyles.caption.copyWith(color: AppColors.statusBlock),
          ),
        ],
      ],
    );
  }
}
