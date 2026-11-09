import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Console top bar (Figma `4:284`): [title] over [subtitle], the search pill
/// and the bell. The pill and the bell have no behavior yet.
class TopBar extends StatelessWidget {
  const TopBar({super.key, required this.title, required this.subtitle});

  static const double _height = 72;
  static const double _searchWidth = 280;
  static const double _controlHeight = 38;

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _height,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      color: AppColors.bgCanvas,
      child: Row(
        spacing: AppSpacing.lg,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.xxs,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.title,
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: _searchWidth,
            height: _controlHeight,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              border: Border.all(color: AppColors.borderDefault),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Row(
              spacing: AppSpacing.sm,
              children: [
                const Icon(
                  AppIcons.search,
                  size: AppIcons.size,
                  color: AppColors.textTertiary,
                ),
                Expanded(
                  child: TextField(
                    style: AppTextStyles.body,
                    cursorColor: AppColors.accent,
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: 'Buscar transacción, cliente…',
                      hintStyle: AppTextStyles.body.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: _controlHeight,
            height: _controlHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              border: Border.all(color: AppColors.borderDefault),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              AppIcons.bell,
              size: AppIcons.size,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
