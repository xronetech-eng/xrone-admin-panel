import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../constants/app_spacing.dart';
import '../constants/navigation_items.dart';

class SidebarFoundation extends StatelessWidget {
  const SidebarFoundation({
    required this.selectedRouteListenable,
    required this.onRouteSelected,
    this.isCollapsed = false,
    super.key,
  });

  final ValueListenable<String> selectedRouteListenable;
  final ValueChanged<String> onRouteSelected;
  final bool isCollapsed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isCollapsed ? 88.w : 280.w,
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(right: BorderSide(color: AppColors.borderLight)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: isCollapsed
                  ? Center(
                      child: Icon(
                        Icons.admin_panel_settings_outlined,
                        color: AppColors.primaryBlue,
                        size: 28.r,
                      ),
                    )
                  : Center(
                      child: Text(
                        'Xrone Admin Panel',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.headingMedium.copyWith(
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
            ),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.symmetric(
                  horizontal: isCollapsed ? AppSpacing.sm : AppSpacing.md,
                ),
                itemCount: NavigationItems.values.length,
                separatorBuilder: (context, index) =>
                    SizedBox(height: AppSpacing.xs),
                itemBuilder: (context, index) {
                  final item = NavigationItems.values[index];

                  return _SidebarItem(
                    label: item.label,
                    route: item.route,
                    icon: item.icon,
                    selectedRouteListenable: selectedRouteListenable,
                    isCollapsed: isCollapsed,
                    onRouteSelected: onRouteSelected,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.label,
    required this.route,
    required this.icon,
    required this.selectedRouteListenable,
    required this.isCollapsed,
    required this.onRouteSelected,
  });

  final String label;
  final String route;
  final IconData icon;
  final ValueListenable<String> selectedRouteListenable;
  final bool isCollapsed;
  final ValueChanged<String> onRouteSelected;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: selectedRouteListenable,
      builder: (context, selectedRoute, child) {
        return _SidebarItemContent(
          label: label,
          route: route,
          icon: icon,
          isSelected: route == selectedRoute,
          isCollapsed: isCollapsed,
          onRouteSelected: onRouteSelected,
        );
      },
    );
  }
}

class _SidebarItemContent extends StatelessWidget {
  const _SidebarItemContent({
    required this.label,
    required this.route,
    required this.icon,
    required this.isSelected,
    required this.isCollapsed,
    required this.onRouteSelected,
  });

  final String label;
  final String route;
  final IconData icon;
  final bool isSelected;
  final bool isCollapsed;
  final ValueChanged<String> onRouteSelected;

  @override
  Widget build(BuildContext context) {
    final iconSize = isCollapsed ? 24.r : 26.r;
    final menuTextSize = isCollapsed ? 16.sp : 17.sp;
    final horizontalPadding = isCollapsed ? AppSpacing.md : AppSpacing.lg;
    final iconTextSpacing = AppSpacing.lg;
    final backgroundColor = isSelected
        ? const Color(0xFFDDEBFF)
        : Colors.transparent;
    final foregroundColor = isSelected
        ? AppColors.primaryBlue
        : AppColors.textMuted;

    final item = Material(
      color: backgroundColor,
      animationDuration: Duration.zero,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        splashFactory: NoSplash.splashFactory,
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        focusColor: Colors.transparent,
        onTap: isSelected ? null : () => onRouteSelected(route),
        child: SizedBox(
          height: 48.h,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Row(
              mainAxisAlignment: isCollapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Icon(icon, size: iconSize, color: foregroundColor),
                if (!isCollapsed) ...[
                  SizedBox(width: iconTextSpacing),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: foregroundColor,
                        fontSize: menuTextSize,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (isCollapsed) {
      return Tooltip(message: label, child: item);
    }

    return item;
  }
}
