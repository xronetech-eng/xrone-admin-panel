import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/responsive/responsive_helper.dart';
import '../models/users_model.dart';

class UsersOverviewCards extends StatelessWidget {
  const UsersOverviewCards({required this.users, super.key});

  final List<UserAdminViewData> users;

  @override
  Widget build(BuildContext context) {
    final columns = ResponsiveHelper.value<int>(
      context,
      mobile: 1,
      tablet: 2,
      desktop: 4,
    );
    final totalBookings = users.fold<int>(
      0,
      (previous, user) => previous + user.bookingsCount,
    );
    final totalPayments = users.fold<num>(
      0,
      (previous, user) =>
          previous +
          user.paymentHistory.fold<num>(
            0,
            (total, payment) => total + _amountFromLabel(payment.totalPaid),
          ),
    );

    final cards = [
      _OverviewData(
        title: 'Total Users',
        value: _formatWholeNumber(users.length),
        icon: Icons.people_outline,
        color: AppColors.primaryBlue,
      ),
      _OverviewData(
        title: 'Active Users',
        value: _formatWholeNumber(
          users.where((user) => user.status == UserStatus.active).length,
        ),
        icon: Icons.verified_user_outlined,
        color: const Color(0xFF16A34A),
      ),
      _OverviewData(
        title: 'Total Bookings',
        value: _formatWholeNumber(totalBookings),
        icon: Icons.event_note_outlined,
        color: const Color(0xFF7C3AED),
      ),
      _OverviewData(
        title: 'Total Payments',
        value: _formatCurrency(totalPayments),
        icon: Icons.payments_outlined,
        color: const Color(0xFF0891B2),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: AppSpacing.lg,
        mainAxisSpacing: AppSpacing.lg,
        mainAxisExtent: 138.h,
      ),
      itemBuilder: (context, index) => _OverviewCard(data: cards[index]),
    );
  }
}

num _amountFromLabel(String value) {
  return num.tryParse(value.replaceAll(RegExp(r'[^0-9.-]'), '')) ?? 0;
}

String _formatCurrency(num value) {
  final parts = value.toDouble().toStringAsFixed(2).split('.');
  return 'Rs. ${_formatDigits(parts.first)}.${parts.last}';
}

String _formatWholeNumber(int value) {
  return _formatDigits(value.toString());
}

String _formatDigits(String value) {
  final sign = value.startsWith('-') ? '-' : '';
  final digits = sign.isEmpty ? value : value.substring(1);
  return '$sign${digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',')}';
}

class _OverviewData {
  const _OverviewData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.data});

  final _OverviewData data;

  @override
  Widget build(BuildContext context) {
    final icon = Container(
      width: 52.w,
      height: 52.h,
      decoration: BoxDecoration(
        color: data.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Icon(data.icon, color: data.color, size: 24.r),
    );

    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.textDark.withValues(alpha: 0.04),
            blurRadius: 20.r,
            offset: Offset(0, 10.h),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 180) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                icon,
                SizedBox(height: 8.h),
                _OverviewText(data: data),
              ],
            );
          }

          return Row(
            children: [
              icon,
              SizedBox(width: AppSpacing.md),
              Expanded(child: _OverviewText(data: data)),
            ],
          );
        },
      ),
    );
  }
}

class _OverviewText extends StatelessWidget {
  const _OverviewText({required this.data});

  final _OverviewData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
        ),
        SizedBox(height: 8.h),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            data.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.headingMedium.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
