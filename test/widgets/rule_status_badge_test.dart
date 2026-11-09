import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monedasegura_app/data/models/models.dart';
import 'package:monedasegura_app/theme/app_colors.dart';
import 'package:monedasegura_app/widgets/widgets.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('shows each rule status label in its color', (tester) async {
    await setDesktopView(tester);
    final cases = {
      RuleStatus.DRAFT: ('Borrador', AppColors.textSecondary),
      RuleStatus.SHADOW: ('Shadow', AppColors.accent),
      RuleStatus.PENDING_APPROVAL: ('Pendiente', AppColors.statusReview),
      RuleStatus.ACTIVE: ('Activa', AppColors.statusApprove),
      RuleStatus.RETIRED: ('Retirada', AppColors.textTertiary),
    };
    for (final MapEntry(key: status, value: (label, color)) in cases.entries) {
      await tester.pumpWidget(harness(RuleStatusBadge(status: status)));
      expect(find.text(label), findsOneWidget);
      expect(tester.widget<Text>(find.text(label)).style?.color, color);
    }
  });
}
