import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'ms_icon.dart';

/// One bell notification: its text and where it takes the user.
class NotificationItem {
  const NotificationItem({required this.message, required this.onOpen});

  final String message;
  final VoidCallback onOpen;
}

/// Notifications shown by the bell of every [TopBar]; the console provides
/// them.
class NotificationsScope extends InheritedWidget {
  const NotificationsScope({
    super.key,
    required this.items,
    required super.child,
  });

  final List<NotificationItem> items;

  static List<NotificationItem> of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<NotificationsScope>();
    return scope?.items ?? const [];
  }

  @override
  bool updateShouldNotify(NotificationsScope oldWidget) => true;
}

/// 72 px bar on the canvas: titles, a 280 px search pill and a bell.
class TopBar extends StatelessWidget {
  const TopBar({
    super.key,
    required this.title,
    required this.subtitle,
    this.searchController,
    this.onSearchChanged,
  });

  final String title;
  final String subtitle;

  /// When null the pill is a static placeholder.
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: MsSpace.xxl),
      color: MsColors.bgCanvas,
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: MsText.title,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: MsSpace.xxs),
                Text(
                  subtitle,
                  style: MsText.caption,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: MsSpace.lg),
          Container(
            key: const ValueKey('top-bar-search'),
            width: 280,
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: MsSpace.md),
            decoration: BoxDecoration(
              color: MsColors.bgSurface,
              border: Border.all(color: MsColors.borderDefault),
              borderRadius: BorderRadius.circular(MsRadius.full),
            ),
            child: Row(
              children: [
                const MsIcon(MsIconName.search, color: MsColors.textTertiary),
                const SizedBox(width: MsSpace.sm),
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onChanged: onSearchChanged,
                    style: MsText.body,
                    cursorColor: MsColors.accent,
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: 'Buscar transacción, cliente…',
                      hintStyle: MsText.body.copyWith(
                        color: MsColors.textTertiary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: MsSpace.lg),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              key: const ValueKey('top-bar-bell'),
              behavior: HitTestBehavior.opaque,
              onTap: () => _showNotifications(context),
              child: SizedBox(
                width: 42,
                height: 42,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      bottom: 0,
                      child: Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: MsColors.bgSurface,
                          border: Border.all(color: MsColors.borderDefault),
                          shape: BoxShape.circle,
                        ),
                        child: const MsIcon(
                          MsIconName.bell,
                          color: MsColors.textSecondary,
                        ),
                      ),
                    ),
                    if (NotificationsScope.of(context).isNotEmpty)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          key: const ValueKey('top-bar-bell-badge'),
                          width: 18,
                          height: 18,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: MsColors.block,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: MsColors.bgCanvas,
                              width: 2,
                            ),
                          ),
                          child: const Text(
                            '!',
                            style: TextStyle(
                              fontFamily: MsText.family,
                              fontSize: 11,
                              height: 1,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    final items = NotificationsScope.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Notificaciones'),
        content: SizedBox(
          width: 380,
          child: items.isEmpty
              ? const Text('No tienes notificaciones nuevas.')
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final item in items)
                      InkWell(
                        borderRadius: BorderRadius.circular(MsRadius.sm),
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          item.onOpen();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: MsSpace.sm,
                            horizontal: MsSpace.xs,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: MsColors.block,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: MsSpace.md),
                              Expanded(
                                child: Text(item.message, style: MsText.body),
                              ),
                              const MsIcon(
                                MsIconName.chevron,
                                color: MsColors.textTertiary,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
