import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The gallery icons (Lucide, 20 px). The only file that names the icon set.
abstract final class AppIcons {
  static const double size = 20;

  static const IconData shield = LucideIcons.shield;
  static const IconData inbox = LucideIcons.inbox;
  static const IconData dashboard = LucideIcons.layoutDashboard;
  static const IconData sliders = LucideIcons.slidersVertical;
  static const IconData cpu = LucideIcons.cpu;
  static const IconData play = LucideIcons.play;
  static const IconData search = LucideIcons.search;
  static const IconData chevronRight = LucideIcons.chevronRight;
  // Dropdown indicator: not a gallery icon, so it is not in [all].
  static const IconData chevronDown = LucideIcons.chevronDown;
  static const IconData check = LucideIcons.check;
  static const IconData close = LucideIcons.x;
  static const IconData back = LucideIcons.arrowLeft;
  static const IconData bell = LucideIcons.bell;
  static const IconData filter = LucideIcons.filter;
  static const IconData clock = LucideIcons.clock;
  static const IconData logout = LucideIcons.logOut;
  static const IconData users = LucideIcons.users;
  static const IconData plus = LucideIcons.plus;
  static const IconData zap = LucideIcons.zap;
  static const IconData phone = LucideIcons.smartphone;
  static const IconData pin = LucideIcons.mapPin;

  static const List<IconData> all = [
    shield,
    inbox,
    dashboard,
    sliders,
    cpu,
    play,
    search,
    chevronRight,
    check,
    close,
    back,
    bell,
    filter,
    clock,
    logout,
    users,
    plus,
    zap,
    phone,
    pin,
  ];
}
