VERDICT: PASS

## Summary
- Per AGENTS.md there is no browser check for this Flutter web canvas app, so I reviewed the code against the spec and ran the widget tests.
- `test/screens/rule_drafts_test.dart` passes (14 tests).
- The draft flow has no dead ends. Save is disabled until a change is made and "Iniciar shadow" is disabled while there are unsaved changes. Incomplete conditions show a red value box and a message. Discard asks for confirmation.
- `/rules/new` validates the code and the name before calling the store, so no `DomainError` reaches the user. Errors clear when the field changes.
- Gating uses `RULE_WRITE`. Read-only statuses and Camilo (ANALYST) see the same view as before. The rejected-draft case hides "Descartar borrador".

## Findings
None.

## Notes
- The condition value box has no format hint. A user has to know that "sí" and "1.000.000" are accepted. This is out of scope.
- The incomplete-condition error is shown only after a save attempt, as the spec asks.
