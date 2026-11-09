import 'package:flutter/material.dart';

/// Icons of the Figma gallery (20 px stroke set).
///
/// The Figma SVG exports could not be downloaded when this prototype was
/// built, so each name maps to the closest outlined Material icon. Replacing
/// the mapping here (or the body of [MsIcon]) swaps the whole app to the
/// original SVGs without touching any screen.
enum MsIconName {
  shield,
  inbox,
  dashboard,
  sliders,
  cpu,
  play,
  search,
  chevron,
  check,
  x,
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
}

const Map<MsIconName, IconData> _icons = {
  MsIconName.shield: Icons.shield_outlined,
  MsIconName.inbox: Icons.inbox_outlined,
  MsIconName.dashboard: Icons.dashboard_outlined,
  MsIconName.sliders: Icons.tune,
  MsIconName.cpu: Icons.memory,
  MsIconName.play: Icons.play_arrow_outlined,
  MsIconName.search: Icons.search,
  MsIconName.chevron: Icons.chevron_right,
  MsIconName.check: Icons.check,
  MsIconName.x: Icons.close,
  MsIconName.back: Icons.arrow_back,
  MsIconName.bell: Icons.notifications_none,
  MsIconName.filter: Icons.filter_list,
  MsIconName.clock: Icons.schedule,
  MsIconName.logout: Icons.logout,
  MsIconName.users: Icons.group_outlined,
  MsIconName.plus: Icons.add,
  MsIconName.zap: Icons.bolt,
  MsIconName.phone: Icons.smartphone,
  MsIconName.pin: Icons.place_outlined,
};

class MsIcon extends StatelessWidget {
  const MsIcon(this.name, {super.key, this.size = 20, this.color});

  final MsIconName name;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Icon(_icons[name], size: size, color: color);
  }
}
