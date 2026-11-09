import 'models.dart';

/// Spanish display text for API codes, plus es_CO number formatting.

String verdictLabel(Verdict verdict) {
  switch (verdict) {
    case Verdict.approve:
      return 'Aprobada';
    case Verdict.review:
      return 'En revisión';
    case Verdict.block:
      return 'Bloqueada';
  }
}

String ruleStatusLabel(RuleStatus status) {
  switch (status) {
    case RuleStatus.draft:
      return 'Borrador';
    case RuleStatus.shadow:
      return 'Shadow';
    case RuleStatus.pendingApproval:
      return 'Pendiente';
    case RuleStatus.active:
      return 'Activa';
    case RuleStatus.retired:
      return 'Retirada';
  }
}

String ruleActionLabel(RuleAction action) {
  switch (action) {
    case RuleAction.review:
      return 'Revisar';
    case RuleAction.block:
      return 'Bloquear';
  }
}

String modelStatusLabel(ModelStatus status) {
  switch (status) {
    case ModelStatus.active:
      return 'Activo';
    case ModelStatus.candidate:
      return 'Candidato';
    case ModelStatus.retired:
      return 'Retirado';
  }
}

/// `3250000` -> `$ 3.250.000`.
String formatCop(int amount) => '\$ ${_groupThousands(amount)}';

/// `0.67` -> `0,67`; null -> an em dash.
String formatScore(double? score) =>
    score == null ? '—' : score.toStringAsFixed(2).replaceAll('.', ',');

/// Decimal comma for any number, e.g. `4.1` -> `4,1`.
String formatDecimal(double value, [int digits = 2]) =>
    value.toStringAsFixed(digits).replaceAll('.', ',');

/// Thousands separated by dots, e.g. `12480` -> `12.480`.
String formatCount(int value) => _groupThousands(value);

String _groupThousands(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return value < 0 ? '-$buffer' : buffer.toString();
}

/// `Andrés P.` -> `AP`.
String initialsOf(String name) => name
    .split(' ')
    .where((part) => part.isNotEmpty)
    .take(2)
    .map((part) => part[0].toUpperCase())
    .join();

/// Human description of a rule, e.g. `Monto ≥ $ 2.000.000 y Tipo = Transferencia`.
String describeCondition(RuleCondition condition) =>
    '${condition.feature} ${condition.operator} ${condition.value}';
