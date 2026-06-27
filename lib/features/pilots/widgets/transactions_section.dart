import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../models/pilots_model.dart';
import '_pilot_ui.dart';

class TransactionsSection extends StatelessWidget {
  const TransactionsSection({required this.transactions, super.key});

  final List<PilotTransactionData> transactions;

  @override
  Widget build(BuildContext context) {
    return PilotSectionCard(
      title: 'Transactions',
      subtitle: 'Read only',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 920.w,
          child: Column(
            children: [
              const _RowShell(
                isHeader: true,
                children: [
                  _Cell('Transaction ID', flex: 2, isHeader: true),
                  _Cell('Booking ID', flex: 2, isHeader: true),
                  _Cell('Transaction Type', flex: 2, isHeader: true),
                  _Cell('Status', flex: 2, isHeader: true),
                  _Cell('Pilot Charges', flex: 2, isHeader: true),
                  _Cell('Admin Charges', flex: 2, isHeader: true),
                  _Cell('Transaction Date', flex: 2, isHeader: true),
                ],
              ),
              for (final transaction in transactions)
                _RowShell(
                  children: [
                    _Cell(transaction.transactionId, flex: 2),
                    _Cell(transaction.bookingId, flex: 2),
                    _Cell(transaction.transactionType, flex: 2),
                    _Cell(transaction.status, flex: 2),
                    _Cell(transaction.pilotCharges, flex: 2),
                    _Cell(transaction.adminCharges, flex: 2),
                    _Cell(transaction.transactionDate, flex: 2),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RowShell extends StatelessWidget {
  const _RowShell({required this.children, this.isHeader = false});

  final List<Widget> children;
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
      child: Row(children: children),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.text, {required this.flex, this.isHeader = false});

  final String text;
  final int flex;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: PilotTableText(text, isHeader: isHeader),
    );
  }
}
