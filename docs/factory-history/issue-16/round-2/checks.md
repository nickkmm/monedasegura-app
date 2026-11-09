GATE: PASS
COMMIT: f03e1f60a5983485bbedb98c14becf2c00adc75a

## Summary
- checks.sh passed in 49s
- Protected paths: none changed
- Commit f03e1f6

## Protected paths
None changed.

## checks.sh
Exit 0 in 49s. Last 80 lines of checks.log:

```
00:10 +205: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/app_store_rules_test.dart: lifecycle submitting in SHADOW without a backtest gives conflict
00:10 +206: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/models_test.dart: AppUser initials use the first two words
00:10 +207: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/models_test.dart: AppUser initials use the first two words
00:10 +208: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/app_store_rules_test.dart: runBacktest gives the formula numbers on SCORE_REVIEW v5
00:10 +209: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/app_store_rules_test.dart: runBacktest gives the formula numbers on SCORE_REVIEW v5
00:10 +210: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/models_test.dart: AppUser ref carries the id and the name
00:10 +211: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/app_store_rules_test.dart: runBacktest running it twice gives equal counts
00:10 +212: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/models_test.dart: AppUser app_user.dart has no credential field
00:10 +213: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/models_test.dart: AppUser app_user.dart has no credential field
00:10 +214: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/app_store_rules_test.dart: runBacktest refuses an ACTIVE version
00:10 +215: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/models_test.dart: enums Verdict round-trips its codes and rejects unknown ones
00:10 +216: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/app_store_rules_test.dart: reject returns the version to DRAFT with the reason
00:10 +217: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/app_store_rules_test.dart: reject returns the version to DRAFT with the reason
00:10 +218: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/app_store_rules_test.dart: reject refuses an empty reason and one of 1001 characters
00:10 +219: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/app_store_rules_test.dart: reject refuses an empty reason and one of 1001 characters
00:10 +220: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/models_test.dart: enums TransactionSource round-trips its codes and rejects unknown ones
00:10 +221: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/app_store_rules_test.dart: reject a rejected draft cannot be deleted but can be resubmitted
00:10 +222: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/models_test.dart: enums Scenario round-trips its codes and rejects unknown ones
00:10 +223: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/app_store_rules_test.dart: permissions Camilo Torres gets forbidden, even with an unknown id
00:10 +224: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/app_store_rules_test.dart: permissions Camilo Torres gets forbidden, even with an unknown id
00:10 +225: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/models_test.dart: enums CaseStatus round-trips its codes and rejects unknown ones
00:10 +226: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/app_store_rules_test.dart: permissions signed out gets forbidden, even with an unknown id
00:10 +227: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/models_test.dart: enums CaseLabel round-trips its codes and rejects unknown ones
00:10 +228: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/app_store_rules_test.dart: permissions an unknown rule id on updateDraft gives not_found
00:10 +229: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/models_test.dart: enums RuleAction round-trips its codes and rejects unknown ones
00:10 +230: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/app_store_rules_test.dart: notifications a successful operation notifies once, a failed one never
00:10 +231: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/app_store_rules_test.dart: notifications a successful operation notifies once, a failed one never
00:10 +232: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/app_store_rules_test.dart: notifications a successful operation notifies once, a failed one never
00:10 +233: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/models_test.dart: enums ModelTrigger round-trips its codes and rejects unknown ones
00:10 +234: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/app_store_rules_test.dart: approvers and thresholds approversFor returns the other users who can approve
00:10 +235: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/models_test.dart: enums RoleCode round-trips its codes and rejects unknown ones
00:10 +236: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/app_store_rules_test.dart: approvers and thresholds scoreThresholds reads the active score rules
00:10 +237: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/app_store_rules_test.dart: approvers and thresholds scoreThresholds reads the active score rules
00:10 +238: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/models_test.dart: enums DeviceOs round-trips its codes and rejects unknown ones
00:10 +239: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/app_store_rules_test.dart: evaluate records every version and counts a verdict change
00:10 +240: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/models_test.dart: enums ConditionOp round-trips its codes and rejects unknown ones
00:10 +241: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/app_store_rules_test.dart: evaluate a shadow match at the active verdict changes nothing
00:10 +242: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/models_test.dart: enums ConditionOp codes and symbols
00:10 +243: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/app_store_rules_test.dart: evaluate a high score blocks
00:10 +244: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/models_test.dart: model getters BacktestCounts matches and precision
00:10 +245: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/app_store_rules_test.dart: evaluate rules on score do not match a null score
00:10 +246: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/models_test.dart: model getters BacktestCounts precision is 0 with no matches
00:10 +247: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/app_store_rules_test.dart: evaluate does not notify
00:10 +248: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/models_test.dart: model getters RuleView latest, active and version
00:10 +249: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/app_store_rules_test.dart: runs and origination customers startRun returns the next number
00:10 +250: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/app_store_rules_test.dart: runs and origination customers startRun returns the next number
00:10 +251: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/models_test.dart: model getters RuleVersion copyWith clears fields only when asked
00:10 +252: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/models_test.dart: model getters RuleVersion copyWith clears fields only when asked
00:10 +253: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/app_store_rules_test.dart: runs and origination customers a simulated origination customer can be used right away
00:10 +254: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/models_test.dart: model getters CaseView shortId and typeLabel
00:10 +255: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/app_store_rules_test.dart: simulateOne 20 ATO events open 7 cases and update the metrics
00:10 +256: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/models_test.dart: model getters CaseView copyWith replaces one part
00:10 +257: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/app_store_rules_test.dart: simulateOne re-running gives the same verdicts and new unique ids
00:10 +258: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/app_store_rules_test.dart: simulateOne re-running gives the same verdicts and new unique ids
00:10 +259: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/models_test.dart: feature catalog category lists the 14 category codes
00:10 +260: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/app_store_rules_test.dart: simulateOne checks the permission, then the customer, then the scenario
00:10 +261: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/app_store_rules_test.dart: simulateOne 20 events count on the shadow rule
00:10 +262: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/app_store_rules_test.dart: simulateOne builds the decision and the records as specified
00:10 +263: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/app_store_rules_test.dart: profiles NORMAL
00:10 +264: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/app_store_rules_test.dart: profiles CARD_FRAUD
00:10 +265: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/app_store_rules_test.dart: profiles ATO
00:10 +266: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/app_store_rules_test.dart: profiles ORIGINATION
00:10 +267: /home/mrjj/ms/monedasegura-app/.worktrees/004-build-the-case-row/test/data/app_store_rules_test.dart: profiles derives the time and customer features
00:10 +268: All tests passed!
Resolving dependencies...
Downloading packages...
  material_color_utilities 0.13.0 (0.13.1 available)
  meta 1.18.3 (1.19.0 available)
  test_api 0.7.12 (0.7.15 available)
  vector_math 2.4.0 (2.4.4 available)
Got dependencies!
4 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
Compiling lib/main.dart for the Web...                          
Expected to find fonts for (MaterialIcons, packages/cupertino_icons/CupertinoIcons), but found (MaterialIcons). This usually means you are referring to font families in an IconData class but not including them in the assets section of your pubspec.yaml, are missing the package that would include them, or are missing "uses-material-design: true".
Font asset "MaterialIcons-Regular.otf" was tree-shaken, reducing it from 1645184 to 7736 bytes (99.5% reduction). Tree-shaking can be disabled by providing the --no-tree-shake-icons flag when building your app.
Compiling lib/main.dart for the Web...                             29.7s
✓ Built build/web
Wasm dry run succeeded. Consider building and testing your application with the `--wasm` flag. See docs for more info: https://docs.flutter.dev/platform-integration/web/wasm
Use --no-wasm-dry-run to disable these warnings.
```
