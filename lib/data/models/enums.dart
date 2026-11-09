// ignore_for_file: constant_identifier_names

/// API enums from `decision-api.yaml`. Constants keep the API codes verbatim.
abstract interface class _ApiCoded {
  String get code;
}

T _byCode<T extends _ApiCoded>(List<T> values, String code) {
  for (final value in values) {
    if (value.code == code) return value;
  }
  throw ArgumentError.value(code, 'code', 'Unknown $T code');
}

enum Verdict implements _ApiCoded {
  APPROVE('APPROVE'),
  REVIEW('REVIEW'),
  BLOCK('BLOCK');

  const Verdict(this.code);

  @override
  final String code;

  static Verdict fromCode(String code) => _byCode(values, code);
}

enum DecisionKind implements _ApiCoded {
  ORIGINAL('ORIGINAL'),
  REEVALUATION('REEVALUATION');

  const DecisionKind(this.code);

  @override
  final String code;

  static DecisionKind fromCode(String code) => _byCode(values, code);
}

enum TransactionType implements _ApiCoded {
  DEBIT('DEBIT'),
  CREDIT('CREDIT'),
  TRANSFER('TRANSFER'),
  BALANCE_QUERY('BALANCE_QUERY');

  const TransactionType(this.code);

  @override
  final String code;

  static TransactionType fromCode(String code) => _byCode(values, code);
}

enum TransactionSource implements _ApiCoded {
  SEED_DATASET('SEED_DATASET'),
  SIMULATOR('SIMULATOR');

  const TransactionSource(this.code);

  @override
  final String code;

  static TransactionSource fromCode(String code) => _byCode(values, code);
}

enum Scenario implements _ApiCoded {
  NORMAL('NORMAL'),
  DATASET_FRAUD('DATASET_FRAUD'),
  CARD_FRAUD('CARD_FRAUD'),
  ORIGINATION('ORIGINATION'),
  ATO('ATO');

  const Scenario(this.code);

  @override
  final String code;

  static Scenario fromCode(String code) => _byCode(values, code);
}

enum SessionEventType implements _ApiCoded {
  LOGIN_OK('LOGIN_OK'),
  LOGIN_FAILED('LOGIN_FAILED'),
  PASSWORD_CHANGED('PASSWORD_CHANGED'),
  DEVICE_REGISTERED('DEVICE_REGISTERED');

  const SessionEventType(this.code);

  @override
  final String code;

  static SessionEventType fromCode(String code) => _byCode(values, code);
}

enum CaseStatus implements _ApiCoded {
  OPEN('OPEN'),
  IN_REVIEW('IN_REVIEW'),
  RESOLVED('RESOLVED');

  const CaseStatus(this.code);

  @override
  final String code;

  static CaseStatus fromCode(String code) => _byCode(values, code);
}

enum CaseLabel implements _ApiCoded {
  CONFIRMED_FRAUD('CONFIRMED_FRAUD'),
  DISMISSED('DISMISSED');

  const CaseLabel(this.code);

  @override
  final String code;

  static CaseLabel fromCode(String code) => _byCode(values, code);
}

enum RuleAction implements _ApiCoded {
  REVIEW('REVIEW'),
  BLOCK('BLOCK');

  const RuleAction(this.code);

  @override
  final String code;

  static RuleAction fromCode(String code) => _byCode(values, code);
}

enum RuleStatus implements _ApiCoded {
  DRAFT('DRAFT'),
  SHADOW('SHADOW'),
  PENDING_APPROVAL('PENDING_APPROVAL'),
  ACTIVE('ACTIVE'),
  RETIRED('RETIRED');

  const RuleStatus(this.code);

  @override
  final String code;

  static RuleStatus fromCode(String code) => _byCode(values, code);
}

enum ModelStatus implements _ApiCoded {
  CANDIDATE('CANDIDATE'),
  ACTIVE('ACTIVE'),
  RETIRED('RETIRED');

  const ModelStatus(this.code);

  @override
  final String code;

  static ModelStatus fromCode(String code) => _byCode(values, code);
}

enum ModelTrigger implements _ApiCoded {
  SCHEDULED('SCHEDULED'),
  MANUAL('MANUAL');

  const ModelTrigger(this.code);

  @override
  final String code;

  static ModelTrigger fromCode(String code) => _byCode(values, code);
}

enum RoleCode implements _ApiCoded {
  ANALYST('ANALYST'),
  RISK_LEAD('RISK_LEAD'),
  DATA_SCIENTIST('DATA_SCIENTIST'),
  AUDITOR('AUDITOR'),
  ADMIN('ADMIN');

  const RoleCode(this.code);

  @override
  final String code;

  static RoleCode fromCode(String code) => _byCode(values, code);
}

enum PermissionCode implements _ApiCoded {
  CASE_READ('CASE_READ'),
  CASE_RESOLVE('CASE_RESOLVE'),
  RULE_READ('RULE_READ'),
  RULE_WRITE('RULE_WRITE'),
  RULE_APPROVE('RULE_APPROVE'),
  MODEL_READ('MODEL_READ'),
  MODEL_TRAIN('MODEL_TRAIN'),
  SIMULATOR_RUN('SIMULATOR_RUN'),
  DASHBOARD_READ('DASHBOARD_READ'),
  USER_ADMIN('USER_ADMIN');

  const PermissionCode(this.code);

  @override
  final String code;

  static PermissionCode fromCode(String code) => _byCode(values, code);
}

enum DeviceOs implements _ApiCoded {
  ANDROID('ANDROID'),
  IOS('IOS');

  const DeviceOs(this.code);

  @override
  final String code;

  static DeviceOs fromCode(String code) => _byCode(values, code);
}

/// The RBAC catalog of `model.md` §4.
const Map<RoleCode, Set<PermissionCode>> rolePermissions = {
  RoleCode.ANALYST: {
    PermissionCode.CASE_READ,
    PermissionCode.CASE_RESOLVE,
    PermissionCode.RULE_READ,
    PermissionCode.MODEL_READ,
    PermissionCode.DASHBOARD_READ,
  },
  RoleCode.RISK_LEAD: {
    PermissionCode.CASE_READ,
    PermissionCode.CASE_RESOLVE,
    PermissionCode.RULE_READ,
    PermissionCode.MODEL_READ,
    PermissionCode.DASHBOARD_READ,
    PermissionCode.RULE_WRITE,
    PermissionCode.RULE_APPROVE,
  },
  RoleCode.DATA_SCIENTIST: {
    PermissionCode.MODEL_READ,
    PermissionCode.MODEL_TRAIN,
    PermissionCode.RULE_READ,
    PermissionCode.CASE_READ,
    PermissionCode.DASHBOARD_READ,
  },
  RoleCode.AUDITOR: {
    PermissionCode.CASE_READ,
    PermissionCode.RULE_READ,
    PermissionCode.MODEL_READ,
    PermissionCode.DASHBOARD_READ,
  },
  RoleCode.ADMIN: {
    PermissionCode.CASE_READ,
    PermissionCode.CASE_RESOLVE,
    PermissionCode.RULE_READ,
    PermissionCode.RULE_WRITE,
    PermissionCode.RULE_APPROVE,
    PermissionCode.MODEL_READ,
    PermissionCode.MODEL_TRAIN,
    PermissionCode.SIMULATOR_RUN,
    PermissionCode.DASHBOARD_READ,
    PermissionCode.USER_ADMIN,
  },
};
