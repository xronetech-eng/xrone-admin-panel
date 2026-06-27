import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../models/users_model.dart';

class PaymentHistorySection extends StatelessWidget {
  const PaymentHistorySection({required this.payments, super.key});

  final List<UserPaymentHistoryData> payments;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Payment History',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tableWidth = math.max(1360.0, constraints.maxWidth);

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                children: [
                  const _PaymentRow(
                    transactionId: 'Transaction ID',
                    bookingId: 'Booking ID',
                    paymentType: 'Payment Type',
                    status: 'Status',
                    totalPaid: 'Total Paid',
                    pilotCharges: 'Pilot Charges',
                    adminCharges: 'Admin Charges',
                    transactionDate: 'Transaction Date',
                    isHeader: true,
                  ),
                  if (payments.isEmpty)
                    _EmptyTableRow(message: 'No payments found.')
                  else
                    for (final payment in payments)
                      _PaymentRow(
                        transactionId: payment.transactionId,
                        bookingId: payment.bookingId,
                        paymentType: payment.paymentType,
                        status: payment.status,
                        totalPaid: payment.totalPaid,
                        pilotCharges: payment.pilotCharges,
                        adminCharges: payment.adminCharges,
                        transactionDate: payment.transactionDate,
                      ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyTableRow extends StatelessWidget {
  const _EmptyTableRow({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: 58.h),
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10.h),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          message,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
        ),
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
    required this.transactionId,
    required this.bookingId,
    required this.paymentType,
    required this.status,
    required this.totalPaid,
    required this.pilotCharges,
    required this.adminCharges,
    required this.transactionDate,
    this.isHeader = false,
  });

  final String transactionId;
  final String bookingId;
  final String paymentType;
  final String status;
  final String totalPaid;
  final String pilotCharges;
  final String adminCharges;
  final String transactionDate;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: 58.h),
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10.h),
      decoration: BoxDecoration(
        color: isHeader ? AppColors.surface : AppColors.background,
        border: const Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          _Cell(transactionId, flex: 3, isHeader: isHeader),
          _Cell(bookingId, flex: 3, isHeader: isHeader),
          _Cell(paymentType, flex: 2, isHeader: isHeader),
          _Cell(status, flex: 2, isHeader: isHeader),
          _Cell(totalPaid, flex: 2, isHeader: isHeader),
          _Cell(pilotCharges, flex: 2, isHeader: isHeader),
          _Cell(adminCharges, flex: 2, isHeader: isHeader),
          _Cell(transactionDate, flex: 3, isHeader: isHeader),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.text, {required this.flex, required this.isHeader});

  final String text;
  final int flex;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.bodyMedium.copyWith(
          color: isHeader ? AppColors.textMuted : AppColors.textDark,
          fontWeight: isHeader ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.headingMedium),
          SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}
