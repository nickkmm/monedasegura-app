import 'package:flutter/material.dart';

import '../data/models.dart';
import '../theme/tokens.dart';
import 'ms_avatar.dart';
import 'ms_icon.dart';

class SidebarItem {
  const SidebarItem({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final MsIconName icon;
}

/// Brand mark: 28 px accent square with the shield icon.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 28, this.iconSize = 16});

  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: MsColors.accent,
        borderRadius: BorderRadius.circular(MsRadius.sm + 2),
      ),
      child: MsIcon(MsIconName.shield, size: iconSize, color: Colors.white),
    );
  }
}

/// One navigation row: 36 px, radius 6, hover and active backgrounds.
class NavItem extends StatefulWidget {
  const NavItem({
    super.key,
    required this.item,
    required this.active,
    required this.onTap,
  });

  final SidebarItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  State<NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<NavItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final background = widget.active
        ? MsColors.navActive
        : (_hover ? MsColors.navHover : Colors.transparent);
    final color = widget.active ? MsColors.navTextActive : MsColors.navText;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: MsSpace.md),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(MsRadius.sm),
          ),
          child: Row(
            children: [
              MsIcon(widget.item.icon, color: color),
              const SizedBox(width: MsSpace.md),
              Text(
                widget.item.label,
                style: MsText.bodyStrong.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 240 px dark sidebar. [items] already holds only the entries the user has
/// permission for.
class Sidebar extends StatelessWidget {
  const Sidebar({
    super.key,
    required this.items,
    required this.selectedId,
    required this.onSelect,
    required this.user,
    required this.onLogout,
  });

  final List<SidebarItem> items;
  final String selectedId;
  final ValueChanged<String> onSelect;
  final AppUser user;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: MsColors.navBg,
      padding: const EdgeInsets.symmetric(
        horizontal: MsSpace.lg,
        vertical: MsSpace.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: MsSpace.md,
              bottom: MsSpace.xl,
            ),
            child: Row(
              children: [
                const BrandMark(),
                const SizedBox(width: MsSpace.md),
                Text(
                  'MonedaSegura',
                  style: MsText.heading.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: MsSpace.md,
              bottom: MsSpace.xs,
            ),
            child: Text(
              'Operación',
              style: MsText.label.copyWith(color: MsColors.navTextMuted),
            ),
          ),
          for (final item in items) ...[
            NavItem(
              item: item,
              active: item.id == selectedId,
              onTap: () => onSelect(item.id),
            ),
            const SizedBox(height: MsSpace.xs),
          ],
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(MsSpace.md),
            decoration: BoxDecoration(
              color: MsColors.navHover,
              borderRadius: BorderRadius.circular(MsRadius.md),
            ),
            child: Row(
              children: [
                MsAvatar(initials: user.initials, background: MsColors.accent),
                const SizedBox(width: MsSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        overflow: TextOverflow.ellipsis,
                        style: MsText.bodyStrong.copyWith(color: Colors.white),
                      ),
                      Text(
                        user.roleTitle,
                        overflow: TextOverflow.ellipsis,
                        style: MsText.caption.copyWith(
                          color: MsColors.navTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    key: const ValueKey('logout'),
                    behavior: HitTestBehavior.opaque,
                    onTap: onLogout,
                    child: const Padding(
                      padding: EdgeInsets.all(MsSpace.xs),
                      child: MsIcon(MsIconName.logout, color: MsColors.navText),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
