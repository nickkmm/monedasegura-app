import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../app/nav_destination.dart';
import '../app/routes.dart';
import '../data/models/models.dart';
import '../theme/app_spacing.dart';
import 'app_sidebar.dart';
import 'top_bar.dart';

/// The console frame: the sidebar, the top bar and the scrolling [child].
///
/// The one shared widget that reads the store, for the session only.
/// [active] is the highlighted destination; [title] and [subtitle] go to the
/// top bar. Below 1280 wide it lays out at 1280 and scrolls horizontally.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.active,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  static const double _minWidth = 1280;

  final NavDestination active;
  final String title;
  final String subtitle;
  final Widget child;

  void _logout(BuildContext context) {
    AppScope.read(context).signOut();
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }

  Widget _frame(BuildContext context, AppUser user) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSidebar(
          active: active,
          user: user,
          destinations: [
            for (final destination in NavDestination.values)
              if (user.can(destination.permission)) destination,
          ],
          onNavigate: (destination) =>
              Navigator.of(context).pushReplacementNamed(destination.route),
          onLogout: () => _logout(context),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TopBar(title: title, subtitle: subtitle),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxl,
                    0,
                    AppSpacing.xxl,
                    AppSpacing.xxl,
                  ),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Empty once signOut() notifies, until the logout navigation replaces it.
    final user = AppScope.of(context).currentUser;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final frame = _frame(context, user);
          if (constraints.maxWidth >= _minWidth) return frame;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: _minWidth,
              height: constraints.maxHeight,
              child: frame,
            ),
          );
        },
      ),
    );
  }
}
