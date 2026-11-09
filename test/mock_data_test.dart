import 'package:flutter_test/flutter_test.dart';
import 'package:monedasegura_app/data/mock_data.dart';
import 'package:monedasegura_app/data/models.dart';

void main() {
  test('there is one demo user per role with its permissions', () {
    expect(demoUsers.length, 6);
    final admin = demoUsers.firstWhere((u) => u.name == 'Valentina Ríos');
    final analyst = demoUsers.firstWhere((u) => u.name == 'Camilo Torres');
    expect(admin.can(Permission.simulatorRun), isTrue);
    expect(analyst.can(Permission.simulatorRun), isFalse);
  });

  test('initial data is consistent', () {
    expect(initialCases(), isNotEmpty);
    final rules = initialRules();
    final night = rules.firstWhere((r) => r.code == 'NIGHT_TRANSFER');
    expect(night.versions.length, 2);
    expect(hourlyDecisions.length, 24);
    expect(initialModels().any((m) => m.status == ModelStatus.active), isTrue);
  });
}
