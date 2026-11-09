import 'enums.dart';

class UserRef {
  const UserRef({required this.id, required this.fullName});

  final String id;
  final String fullName;
}

class AppUser {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.active,
    required this.roles,
  });

  final String id;
  final String fullName;
  final String email;
  final bool active;
  final List<RoleCode> roles;

  Set<PermissionCode> get permissions => {
    for (final role in roles) ...?rolePermissions[role],
  };

  bool can(PermissionCode permission) => permissions.contains(permission);

  String get initials => fullName
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .take(2)
      .map((word) => word[0].toUpperCase())
      .join();

  UserRef get ref => UserRef(id: id, fullName: fullName);
}
