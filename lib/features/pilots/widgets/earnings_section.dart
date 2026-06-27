import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../models/pilots_model.dart';
import '_pilot_ui.dart';

class EarningsSection extends StatelessWidget {
  const EarningsSection({required this.earnings, super.key});

  final PilotEarningsData earnings;

  @override
  Widget build(BuildContext context) {
    final items = [
      _EarningItem(
        'Current Balance',
        earnings.currentBalance,
        Icons.account_balance_wallet_outlined,
      ),
      _EarningItem(
        'Total Earnings',
        earnings.totalEarnings,
        Icons.trending_up_outlined,
      ),
      _EarningItem('Total Trips', earnings.totalTrips, Icons.route_outlined),
      _EarningItem('Last Updated', earnings.lastUpdated, Icons.update_outlined),
    ];

    return PilotSectionCard(
      title: 'Earnings',
      subtitle: 'Read only',
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        children: [for (final item in items) _EarningTile(item: item)],
      ),
    );
  }
}

class _EarningItem {
  const _EarningItem(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;
}

class _EarningTile extends StatelessWidget {
  const _EarningTile({required this.item});

  final _EarningItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190.w,
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Icon(item.icon, color: AppColors.primaryBlue, size: 22.r),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.label, style: AppTextStyles.bodySmall),
                SizedBox(height: 5.h),
                Text(
                  item.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w800,
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
