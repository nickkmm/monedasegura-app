import 'package:flutter/widgets.dart';

import '../../app/nav_destination.dart';
import '../../widgets/widgets.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppShell(
      active: NavDestination.rules,
      title: 'Reglas',
      subtitle: '',
      child: SizedBox.shrink(),
    );
  }
}
