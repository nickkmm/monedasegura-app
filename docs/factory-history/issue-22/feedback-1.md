# Feedback 1

From @Gomaxd11 after the job escalated.

The user's words: "Sigue tus recomendaciones". The recommendations they accepted, for this PR:

1. Contract differences (recall fields and the "últimos 30 días" heading): keep them for the prototype. Do not change the tile or heading. Do not change monedasegura-infra.
2. Approver: keep Valentina Ríos as the approver shown to Laura. Change the timeline text 'Esperando a otro líder de riesgo' in lib/screens/rules/rule_editor_page.dart, because she is an ADMIN, not a risk lead. New text: 'Esperando a otra persona con permiso para aprobar'. Update its test.
3. Criterion 7: accepted as tested, on ATO_PASSWORD_RESET. No change.
4. Criterion 4: now that #21 is on develop, bring the branch up to date with origin/develop, make the test assert the /rules list, and remove the out-of-date comment and the PR body's "Still to do".
