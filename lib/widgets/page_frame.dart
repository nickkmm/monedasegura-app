import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'top_bar.dart';

/// Standard console page: top bar plus a scrollable content area with the
/// 32 px side padding of the design.
class PageFrame extends StatelessWidget {
  const PageFrame({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.searchController,
    this.onSearchChanged,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TopBar(
          title: title,
          subtitle: subtitle,
          searchController: searchController,
          onSearchChanged: onSearchChanged,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              MsSpace.xxl,
              0,
              MsSpace.xxl,
              MsSpace.xxl,
            ),
            child: child,
          ),
        ),
      ],
    );
  }
}
