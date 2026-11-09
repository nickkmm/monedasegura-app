import 'package:flutter/material.dart';

import '../app/nav_destination.dart';
import '../data/labels.dart';
import '../data/models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'app_avatar.dart';
import 'nav_item.dart';

/// Console sidebar (Figma `4:216`): the brand, one [NavItem] per entry of
/// [destinations] and the card of [user].
///
/// It shows [destinations] as given and does no permission filtering.
/// [active] is the highlighted destination. [onNavigate] reports the tapped
/// destination and [onLogout] the logout control.
class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.active,
    required this.user,
    required this.destinations,
    required this.onNavigate,
    required this.onLogout,
  });

  static const double _width = 240;

  final NavDestination active;
  final AppUser user;
  final List<NavDestination> destinations;
  final ValueChanged<NavDestination> onNavigate;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _width,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      color: AppColors.navBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.xs,
        children: [
          const _Brand(),
          Text(
            'Operación',
            style: AppTextStyles.label.copyWith(color: AppColors.navTextMuted),
          ),
          for (final destination in destinations)
            NavItem(
              icon: destination.icon,
              label: destination.label,
              active: destination == active,
              onTap: () => onNavigate(destination),
            ),
          const Spacer(),
          _UserCard(user: user, onLogout: onLogout),
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  static const double _markSize = 28;
  static const double _markIconSize = 16;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.md,
        bottom: AppSpacing.xl,
      ),
      child: Row(
        spacing: AppSpacing.sm,
        children: [
          Container(
            width: _markSize,
            height: _markSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(
              AppIcons.shield,
              size: _markIconSize,
              color: AppColors.textInverse,
            ),
          ),
          Expanded(
            child: Text(
              'MonedaSegura',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.heading.copyWith(
                color: AppColors.textInverse,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user, required this.onLogout});

  final AppUser user;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.navHover,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        spacing: AppSpacing.sm,
        children: [
          AppAvatar(initials: user.initials, background: AppColors.accent),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyStrong.copyWith(
                    color: AppColors.textInverse,
                  ),
                ),
                Text(
                  user.roles.first.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.navText,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(AppIcons.logout),
            iconSize: AppIcons.size,
            color: AppColors.navText,
            tooltip: 'Cerrar sesión',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(
              width: AppIcons.size,
              height: AppIcons.size,
            ),
            style: const ButtonStyle(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: onLogout,
          ),
        ],
      ),
    );
  }
}
