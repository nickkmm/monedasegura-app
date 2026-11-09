import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monedasegura_app/data/models/models.dart';
import 'package:monedasegura_app/theme/app_colors.dart';
import 'package:monedasegura_app/widgets/widgets.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('StatusPill.model shows each model status', (tester) async {
    await setDesktopView(tester);
    final cases = {
      ModelStatus.ACTIVE: ('Activo', AppColors.statusApprove),
      ModelStatus.CANDIDATE: ('Candidato', AppColors.accent),
      ModelStatus.RETIRED: ('Retirado', AppColors.textSecondary),
    };
    for (final MapEntry(key: status, value: (label, color)) in cases.entries) {
      await tester.pumpWidget(harness(StatusPill.model(status)));
      expect(find.text(label), findsOneWidget);
      expect(tester.widget<Text>(find.text(label)).style?.color, color);
    }
  });

  testWidgets('StatusPill shows the given label and tone', (tester) async {
    await setDesktopView(tester);
    await tester.pumpWidget(
      harness(const StatusPill(tone: StatusTone.danger, label: 'Fallido')),
    );
    expect(
      tester.widget<Text>(find.text('Fallido')).style?.color,
      AppColors.statusBlock,
    );
  });
}
