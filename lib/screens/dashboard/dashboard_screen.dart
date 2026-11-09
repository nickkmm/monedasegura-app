import 'package:flutter/widgets.dart';

import '../../app/nav_destination.dart';
import '../../widgets/widgets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppShell(
      active: NavDestination.dashboard,
      title: 'Dashboard',
      subtitle: '',
      child: SizedBox.shrink(),
    );
  }
}
