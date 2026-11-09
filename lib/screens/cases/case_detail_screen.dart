import 'package:flutter/widgets.dart';

import '../../app/nav_destination.dart';
import '../../widgets/widgets.dart';

class CaseDetailScreen extends StatelessWidget {
  const CaseDetailScreen({super.key, required this.caseId});

  final String caseId;

  @override
  Widget build(BuildContext context) {
    return const AppShell(
      active: NavDestination.cases,
      title: 'Caso',
      subtitle: '',
      child: SizedBox.shrink(),
    );
  }
}
