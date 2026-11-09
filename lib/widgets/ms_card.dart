import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// White surface with a default border and 14 px radius, the container of
/// every panel in the console.
class MsCard extends StatelessWidget {
  const MsCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(MsSpace.xl),
    this.clip = false,
    this.shadow = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Clips children to the rounded corners (tables that fill the card).
  final bool clip;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(
        color: MsColors.bgSurface,
        border: Border.all(color: MsColors.borderDefault),
        borderRadius: BorderRadius.circular(MsRadius.lg),
        boxShadow: shadow ? MsShadow.sm : null,
      ),
      child: child,
    );
  }
}
