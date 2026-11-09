import 'package:flutter_test/flutter_test.dart';
import 'package:monedasegura_app/data/labels.dart';
import 'package:monedasegura_app/data/models/models.dart';

void main() {
  test('Verdict', () {
    expect(Verdict.APPROVE.label, 'Aprobada');
    expect(Verdict.REVIEW.label, 'En revisión');
    expect(Verdict.BLOCK.label, 'Bloqueada');
  });

  test('degradedLabel', () {
    expect(degradedLabel, 'Degradada');
  });

  test('RuleStatus', () {
    expect(RuleStatus.DRAFT.label, 'Borrador');
    expect(RuleStatus.SHADOW.label, 'Shadow');
    expect(RuleStatus.PENDING_APPROVAL.label, 'Pendiente');
    expect(RuleStatus.ACTIVE.label, 'Activa');
    expect(RuleStatus.RETIRED.label, 'Retirada');
  });

  test('RuleAction', () {
    expect(RuleAction.REVIEW.label, 'Revisar');
    expect(RuleAction.BLOCK.label, 'Bloquear');
  });

  test('CaseLabel', () {
    expect(CaseLabel.CONFIRMED_FRAUD.label, 'Fraude confirmado');
    expect(CaseLabel.CONFIRMED_FRAUD.hint, 'No la hizo el cliente');
    expect(CaseLabel.DISMISSED.label, 'Legítima');
    expect(CaseLabel.DISMISSED.hint, 'La hizo el cliente');
  });

  test('ModelStatus', () {
    expect(ModelStatus.ACTIVE.label, 'Activo');
    expect(ModelStatus.CANDIDATE.label, 'Candidato');
    expect(ModelStatus.RETIRED.label, 'Retirado');
  });

  test('ModelTrigger', () {
    expect(ModelTrigger.SCHEDULED.label, 'Automático');
    expect(ModelTrigger.MANUAL.label, 'Manual');
  });

  test('TransactionType', () {
    expect(TransactionType.DEBIT.label, 'Compra');
    expect(TransactionType.CREDIT.label, 'Abono');
    expect(TransactionType.TRANSFER.label, 'Transferencia');
    expect(TransactionType.BALANCE_QUERY.label, 'Consulta de saldo');
  });

  test('RoleCode', () {
    expect(RoleCode.ADMIN.label, 'Administradora');
    expect(RoleCode.RISK_LEAD.label, 'Líder de riesgo');
    expect(RoleCode.ANALYST.label, 'Analista');
    expect(RoleCode.DATA_SCIENTIST.label, 'Científica de datos');
    expect(RoleCode.AUDITOR.label, 'Auditor');
  });

  test('Scenario', () {
    expect(Scenario.NORMAL.label, 'Normal');
    expect(Scenario.NORMAL.hint, 'Hábitos normales');
    expect(
      Scenario.NORMAL.description,
      'Compras habituales del cliente, en su ciudad y en horario normal.',
    );
    expect(Scenario.CARD_FRAUD.label, 'Fraude con tarjeta');
    expect(Scenario.CARD_FRAUD.hint, 'Compras de noche');
    expect(
      Scenario.CARD_FRAUD.description,
      'Varias compras en línea de monto alto, de noche y en pocos minutos.',
    );
    expect(Scenario.ATO.label, 'Toma de cuenta');
    expect(Scenario.ATO.hint, 'Clave y equipo nuevos');
    expect(
      Scenario.ATO.description,
      'Inicios fallidos, cambio de clave y un dispositivo nuevo; después, '
      'compras grandes desde otra ciudad.',
    );
    expect(Scenario.ORIGINATION.label, 'Originación');
    expect(Scenario.ORIGINATION.hint, 'Cliente recién creado');
    expect(
      Scenario.ORIGINATION.description,
      'Un cliente recién creado que mueve dinero desde el primer día.',
    );
    expect(Scenario.DATASET_FRAUD.label, 'Fraude del dataset');
    expect(Scenario.DATASET_FRAUD.hint, '');
    expect(Scenario.DATASET_FRAUD.description, '');
  });

  test('DeviceOs', () {
    expect(DeviceOs.ANDROID.label, 'Android');
    expect(DeviceOs.IOS.label, 'iOS');
  });

  test('categoryLabel', () {
    const expected = {
      'shopping_net': 'Compra en línea',
      'shopping_pos': 'Compra en tienda',
      'grocery_pos': 'Mercado',
      'grocery_net': 'Mercado en línea',
      'gas_transport': 'Gasolina y transporte',
      'food_dining': 'Restaurantes',
      'misc_net': 'Otros en línea',
      'misc_pos': 'Otros en tienda',
      'entertainment': 'Entretenimiento',
      'health_fitness': 'Salud',
      'travel': 'Viajes',
      'home': 'Hogar',
      'kids_pets': 'Niños y mascotas',
      'personal_care': 'Cuidado personal',
    };
    expected.forEach((code, label) => expect(categoryLabel(code), label));
    expect(categoryLabel('anything'), 'Sin categoría');
  });

  test('the category feature allows exactly the labeled codes', () {
    final category = featureCatalog.firstWhere((f) => f.name == 'category');
    for (final code in category.allowedValues!) {
      expect(categoryLabel(code), isNot('Sin categoría'));
    }
  });

  test('featureLabel', () {
    expect(featureLabel('amount_vs_avg_30d'), 'Monto vs. promedio 30 días');
    expect(featureLabel('is_new_device'), 'Dispositivo nuevo');
    expect(featureLabel('tx_count_1h'), 'Transacciones última hora');
    expect(featureLabel('implied_speed_kmh'), 'Velocidad entre ubicaciones');
    expect(featureLabel('is_night'), 'Horario nocturno');
    expect(featureLabel('failed_logins_1h'), 'Inicios de sesión fallidos');
    expect(featureLabel('something_else'), 'something_else');
  });
}
