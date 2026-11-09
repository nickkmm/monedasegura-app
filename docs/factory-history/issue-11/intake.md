DECISION: ACCEPT
RISK: medium
SURFACES: security
RESCOPED: no

## Summary
- Accepted as written: a pure Dart data layer with models, labels, formatters, `MockSeed` and tests.
- The enums, the role permissions and the feature catalog match `model.md`, `decision-api.yaml` and `features.md`, so no docs change is needed first.
- It is large but mostly declarative and adds only new files, so it fits one pull request.
- The issue contradicts itself in three places. None of them blocks the work, and the readings to follow are under Scope.
- @nickkmm, please check the `#09F35B` reading: as specified, no active rule can produce its REVIEW verdict.

## Scope
Build everything in issue #11 with the values it gives: the enums and `rolePermissions`, the immutable models, the Spanish labels, the Colombian-style formatters without `intl`, `MockSeed.build(now)`, and the tests in acceptance criteria 1 to 4.

Three readings settle the contradictions in the issue:

1. **`formatPercent`.** It takes a ratio and multiplies it by 100. The acceptance criterion `formatPercent(37/12480, digits: 2) == '0,30 %'` is correct. The body's example with `0.0296` is a typo, because that input gives `2,96 %`.
2. **Case `#09F35B`.** Keep the row as listed: 2.180.000, degraded, null score, REVIEW. The rules still can't produce that verdict, because score rules don't match when degraded (`model.md` §5) and the other active REVIEW rules need at least 3.000.000 or 5.000.000. Its rule hits stay truthful, with none of those rules matched, and a code comment marks the row as a known exception. Any test of rule and verdict consistency must exempt this one case by name.
3. **NIGHT_TRANSFER v2.** Use the values in its own paragraph: created 3 d ago, shadow since 5 d ago, submitted today 08:10. The more specific paragraph wins over the table's "today". The row's "Actualizada" value therefore reads 3 d rather than today, and the shadow start stays earlier than the creation date, as written.

Points the issue leaves open, for the spec writer to follow:

- **Case `#B204E7`:** use exactly the four rule hits listed, even though `model.md` §5 stores a row for every evaluated rule.
- **Model metrics:** the shorthand triples read prAuc/recall/precision, the order given for v5. Under that order, v4 fails RECALL_NOT_WORSE as the issue says (0,70 against a 0,72 minimum).
- **Approvers:** every ACTIVE version has an approver who isn't its creator (`model.md` §6). The issue only names one, so the others must be chosen to respect this.
- **`DATASET_FRAUD`:** the issue gives it a label only, so its `hint` and `description` need a defined empty value.
- **Times anchored to "today":** values such as 02:00, 08:10 and 09:30 are in the past for the 09:45 test clock. Times meant to read as past must stay that way for an earlier `now`, or the seed must document that limit.
- **`hourly`:** use the values as given. They don't add up to the `verdicts` totals, and no test should require that.

Left out, as the issue says: the store and mutations, widgets, JSON, HTTP and persistence. The password check also belongs to the store task, so this one only adds the `demoPassword` constant.

## Why
The enums in `decision-api.yaml` (`components/schemas`) and the RBAC table in `model.md` §4 match the issue, and `features.md` lists the expected 19 features, with `score` allowed in rule conditions. The repo has only `lib/main.dart` and `lib/login_screen.dart`, so nothing existing gets touched, and `pubspec.yaml` needs no new dependency.

Risk is medium because every later prototype screen builds on this layer and it defines the permission map. Surfaces is `security` for the same map and for the demo password constant, which is a prototype value and not a real credential.

The issue also adds fields the API doesn't have, such as `Device` in `CaseView` and the fields marked prototype-only. These stay in memory, so no contract change is needed now, but they will need one when the app connects to the real API.

## Questions
