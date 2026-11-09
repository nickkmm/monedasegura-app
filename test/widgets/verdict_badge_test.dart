import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monedasegura_app/data/models/models.dart';
import 'package:monedasegura_app/theme/app_colors.dart';
import 'package:monedasegura_app/widgets/widgets.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('shows each verdict label in its color', (tester) async {
    await setDesktopView(tester);
    final cases = {
      const VerdictBadge(verdict: Verdict.APPROVE): (
        'Aprobada',
        AppColors.statusApprove,
      ),
      const VerdictBadge(verdict: Verdict.REVIEW): (
        'En revisión',
        AppColors.statusReview,
      ),
      const VerdictBadge(verdict: Verdict.BLOCK): (
        'Bloqueada',
        AppColors.statusBlock,
      ),
      const VerdictBadge.degraded(): ('Degradada', AppColors.textSecondary),
    };
    for (final MapEntry(key: badge, value: (label, color)) in cases.entries) {
      await tester.pumpWidget(harness(badge));
      expect(find.text(label), findsOneWidget);
      expect(tester.widget<Text>(find.text(label)).style?.color, color);
    }
  });
}
