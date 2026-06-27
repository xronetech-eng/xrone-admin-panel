import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../models/payments_model.dart';
import 'pilot_transactions_table.dart';
import 'store_transactions_table.dart';
import 'user_transactions_table.dart';

class PaymentsTabs extends StatelessWidget {
  const PaymentsTabs({required this.data, super.key});

  final PaymentAdminData data;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: AppColors.textDark.withValues(alpha: 0.05),
              blurRadius: 24.r,
              offset: Offset(0, 12.h),
            ),
          ],
        ),
        child: Column(
          children: [
            const TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: 'User Transactions'),
                Tab(text: 'Pilot Transactions'),
                Tab(text: 'Store Transactions'),
              ],
            ),
            SizedBox(height: AppSpacing.lg),
            Expanded(
              child: TabBarView(
                children: [
                  UserTransactionsTable(rows: data.userTransactions),
                  PilotTransactionsTable(rows: data.pilotTransactions),
                  StoreTransactionsTable(rows: data.storePayments),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
