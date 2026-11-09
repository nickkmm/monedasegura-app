import 'package:flutter/widgets.dart';

import '../../app/nav_destination.dart';
import '../../widgets/widgets.dart';

class CaseQueueScreen extends StatelessWidget {
  const CaseQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppShell(
      active: NavDestination.cases,
      title: 'Cola de casos',
      subtitle: '',
      child: SizedBox.shrink(),
    );
  }
}
