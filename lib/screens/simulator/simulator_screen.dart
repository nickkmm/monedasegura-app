import 'package:flutter/widgets.dart';

import '../../app/nav_destination.dart';
import '../../widgets/widgets.dart';

class SimulatorScreen extends StatelessWidget {
  const SimulatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppShell(
      active: NavDestination.simulator,
      title: 'Simulador',
      subtitle: '',
      child: SizedBox.shrink(),
    );
  }
}
