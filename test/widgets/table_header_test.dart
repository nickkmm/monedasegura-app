import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monedasegura_app/theme/app_colors.dart';
import 'package:monedasegura_app/theme/app_spacing.dart';
import 'package:monedasegura_app/widgets/widgets.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('renders each label in the tertiary color', (tester) async {
    await setDesktopView(tester);
    const labels = ['ID', 'CLIENTE', 'MONTO', 'HACE'];
    await tester.pumpWidget(
      harness(
        const TableHeaderRow(
          cells: [
            TableHeaderCell(label: 'ID', width: 112),
            TableHeaderCell(label: 'CLIENTE', width: 200),
            TableHeaderCell(label: 'MONTO', flex: true),
            TableHeaderCell(label: 'HACE', align: TextAlign.right),
          ],
        ),
      ),
    );
    for (final label in labels) {
      final text = tester.widget<Text>(find.text(label));
      expect(text.style?.color, AppColors.textTertiary, reason: label);
    }
    expect(tester.getSize(find.text('ID')).width, 112);
  });

  testWidgets('takes the given height, padding and radius', (tester) async {
    await setDesktopView(tester);
    await tester.pumpWidget(
      harness(
        const SizedBox(
          width: 600,
          child: TableHeaderRow(
            height: 30,
            horizontalPadding: 12,
            radius: AppRadius.sm,
            cells: [TableHeaderCell(label: 'Versión', width: 148)],
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(TableHeaderRow)).height, 30);
    expect(
      tester.getTopLeft(find.text('Versión')).dx -
          tester.getTopLeft(find.byType(TableHeaderRow)).dx,
      12,
    );
    final box = tester.widget<Container>(
      find.descendant(
        of: find.byType(TableHeaderRow),
        matching: find.byType(Container),
      ),
    );
    expect(
      (box.decoration! as BoxDecoration).borderRadius,
      BorderRadius.circular(AppRadius.sm),
    );
  });
}
