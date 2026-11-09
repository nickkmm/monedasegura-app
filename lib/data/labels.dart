import 'models/enums.dart';

const degradedLabel = 'Degradada';

extension VerdictLabel on Verdict {
  String get label => switch (this) {
    Verdict.APPROVE => 'Aprobada',
    Verdict.REVIEW => 'En revisión',
    Verdict.BLOCK => 'Bloqueada',
  };
}

extension RuleStatusLabel on RuleStatus {
  String get label => switch (this) {
    RuleStatus.DRAFT => 'Borrador',
    RuleStatus.SHADOW => 'Shadow',
    RuleStatus.PENDING_APPROVAL => 'Pendiente',
    RuleStatus.ACTIVE => 'Activa',
    RuleStatus.RETIRED => 'Retirada',
  };
}

extension RuleActionLabel on RuleAction {
  String get label => switch (this) {
    RuleAction.REVIEW => 'Revisar',
    RuleAction.BLOCK => 'Bloquear',
  };
}

extension CaseLabelLabel on CaseLabel {
  String get label => switch (this) {
    CaseLabel.CONFIRMED_FRAUD => 'Fraude confirmado',
    CaseLabel.DISMISSED => 'Legítima',
  };

  String get hint => switch (this) {
    CaseLabel.CONFIRMED_FRAUD => 'No la hizo el cliente',
    CaseLabel.DISMISSED => 'La hizo el cliente',
  };
}

extension ModelStatusLabel on ModelStatus {
  String get label => switch (this) {
    ModelStatus.ACTIVE => 'Activo',
    ModelStatus.CANDIDATE => 'Candidato',
    ModelStatus.RETIRED => 'Retirado',
  };
}

extension ModelTriggerLabel on ModelTrigger {
  String get label => switch (this) {
    ModelTrigger.SCHEDULED => 'Automático',
    ModelTrigger.MANUAL => 'Manual',
  };
}

extension TransactionTypeLabel on TransactionType {
  String get label => switch (this) {
    TransactionType.DEBIT => 'Compra',
    TransactionType.CREDIT => 'Abono',
    TransactionType.TRANSFER => 'Transferencia',
    TransactionType.BALANCE_QUERY => 'Consulta de saldo',
  };
}

extension RoleCodeLabel on RoleCode {
  String get label => switch (this) {
    RoleCode.ADMIN => 'Administradora',
    RoleCode.RISK_LEAD => 'Líder de riesgo',
    RoleCode.ANALYST => 'Analista',
    RoleCode.DATA_SCIENTIST => 'Científica de datos',
    RoleCode.AUDITOR => 'Auditor',
  };
}

extension ScenarioLabel on Scenario {
  String get label => switch (this) {
    Scenario.NORMAL => 'Normal',
    Scenario.CARD_FRAUD => 'Fraude con tarjeta',
    Scenario.ATO => 'Toma de cuenta',
    Scenario.ORIGINATION => 'Originación',
    Scenario.DATASET_FRAUD => 'Fraude del dataset',
  };

  String get hint => switch (this) {
    Scenario.NORMAL => 'Hábitos normales',
    Scenario.CARD_FRAUD => 'Compras de noche',
    Scenario.ATO => 'Clave y equipo nuevos',
    Scenario.ORIGINATION => 'Cliente recién creado',
    Scenario.DATASET_FRAUD => '',
  };

  String get description => switch (this) {
    Scenario.NORMAL =>
      'Compras habituales del cliente, en su ciudad y en horario normal.',
    Scenario.CARD_FRAUD =>
      'Varias compras en línea de monto alto, de noche y en pocos minutos.',
    Scenario.ATO =>
      'Inicios fallidos, cambio de clave y un dispositivo nuevo; después, '
          'compras grandes desde otra ciudad.',
    Scenario.ORIGINATION =>
      'Un cliente recién creado que mueve dinero desde el primer día.',
    Scenario.DATASET_FRAUD => '',
  };
}

extension DeviceOsLabel on DeviceOs {
  String get label => switch (this) {
    DeviceOs.ANDROID => 'Android',
    DeviceOs.IOS => 'iOS',
  };
}

const _categoryLabels = {
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

String categoryLabel(String code) => _categoryLabels[code] ?? 'Sin categoría';

const _featureLabels = {
  'amount_vs_avg_30d': 'Monto vs. promedio 30 días',
  'is_new_device': 'Dispositivo nuevo',
  'tx_count_1h': 'Transacciones última hora',
  'implied_speed_kmh': 'Velocidad entre ubicaciones',
  'is_night': 'Horario nocturno',
  'failed_logins_1h': 'Inicios de sesión fallidos',
};

String featureLabel(String name) => _featureLabels[name] ?? name;
