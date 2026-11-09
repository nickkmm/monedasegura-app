/// A domain rule the store refused. Screens hide or disable the actions that
/// cause it, so it only surfaces on a bug.
class DomainError implements Exception {
  const DomainError(this.code, this.message);

  /// One of `forbidden`, `conflict`, `not_found` or `invalid`: the API's 403,
  /// 409, 404 and 400.
  final String code;
  final String message;

  @override
  String toString() => 'DomainError($code): $message';
}
