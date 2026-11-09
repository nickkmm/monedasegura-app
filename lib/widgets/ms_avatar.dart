import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// 32 px circle with initials.
class MsAvatar extends StatelessWidget {
  const MsAvatar({
    super.key,
    required this.initials,
    this.background = MsColors.bgInverse,
  });

  final String initials;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Text(
        initials,
        style: MsText.badge.copyWith(color: MsColors.textInverse),
      ),
    );
  }
}
