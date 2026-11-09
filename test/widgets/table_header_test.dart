import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monedasegura_app/theme/app_colors.dart';
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
}
