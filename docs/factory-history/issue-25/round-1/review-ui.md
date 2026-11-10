VERDICT: PASS

## Summary
- Issue #25 adds editable DRAFT rows, "Agregar condición", "Guardar borrador", "Descartar borrador" with a confirm dialog, and the "Nueva regla" form on `/rules/new`.
- The new code uses only `AppColors`, `AppSpacing`, `AppTextStyles`, `AppIcons` and existing gallery widgets; a scan of the added lines found no hard-coded colours, sizes or one-off styles.
- The incomplete-condition state reuses the `AppTextField` error red (`AppColors.statusBlock`) on the `ConditionRow` value box and the red caption, both matching the existing error style.
- The app shell has a 1280 px minimum width and scrolls horizontally below it, so the phone-width check doesn't apply to this desktop console. Nothing overflows within the shell.
- I did not run the app in a browser: AGENTS.md says Flutter web draws on a canvas and that UI is checked with widget tests and code reading. I ran `flutter test test/screens/rule_drafts_test.dart test/widgets/condition_row_test.dart`, which passed (21 tests).

## Findings
None.

## Notes
- `lib/screens/rules/rule_editor_page.dart` (`_ApprovalCard`): "Iniciar shadow" is disabled while there are unsaved changes, but nothing on screen says why. The "Guardar borrador" button is the obvious next step, so this is probably fine; a short caption would make it clearer.
- `lib/screens/rules/rule_editor_page.dart` (`_ConditionCard`): the "Completa todas las condiciones antes de guardar." caption sits above "Agregar condición", inside the condition card. On `/rules/new` it is far from "Crear borrador", which is in the right column. The spec allows this placement, so it is only a note.
- `lib/screens/rules/rule_editor_page.dart` (`_CreateCard`): the card has no title, as spec requirement 8 asks. It reads fine beside the "Datos de la regla" card, which starts at the same top edge.
- `lib/screens/rules/rule_editor_page.dart` (`_RuleDataCard`): "Descripción" is optional, but no field marks which fields are required. The spec doesn't ask for a marker, so this is only a note.
- The discard dialog, the new-rule fields and the condition rows follow the `_RejectDialog` and existing `ConditionRow` look. Spacing uses `AppSpacing` throughout.
