import 'package:flutter/widgets.dart';

import '../../app/nav_destination.dart';
import '../../widgets/widgets.dart';

class ModelsScreen extends StatelessWidget {
  const ModelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppShell(
      active: NavDestination.models,
      title: 'Modelos',
      subtitle: '',
      child: SizedBox.shrink(),
    );
  }
}
