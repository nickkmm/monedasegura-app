import 'package:flutter/widgets.dart';

import '../../app/nav_destination.dart';
import '../../widgets/widgets.dart';

class RuleEditorScreen extends StatelessWidget {
  const RuleEditorScreen({super.key, this.ruleId});

  /// The rule to edit, or `null` for a new rule.
  final String? ruleId;

  @override
  Widget build(BuildContext context) {
    return const AppShell(
      active: NavDestination.rules,
      title: 'Regla',
      subtitle: '',
      child: SizedBox.shrink(),
    );
  }
}
