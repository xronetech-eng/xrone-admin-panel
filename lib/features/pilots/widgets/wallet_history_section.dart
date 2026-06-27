import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../models/pilots_model.dart';
import '_pilot_ui.dart';

class WalletHistorySection extends StatelessWidget {
  const WalletHistorySection({required this.walletHistory, super.key});

  final List<PilotWalletHistoryData> walletHistory;

  @override
  Widget build(BuildContext context) {
    return PilotSectionCard(
      title: 'Wallet History',
      subtitle: 'Read only',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 860.w,
          child: Column(
            children: [
              const _RowShell(
                isHeader: true,
                children: [
                  _Cell('Amount', flex: 2, isHeader: true),
                  _Cell('Type', flex: 2, isHeader: true),
                  _Cell('Description', flex: 3, isHeader: true),
                  _Cell('Balance After Transaction', flex: 3, isHeader: true),
                  _Cell('Created Date', flex: 2, isHeader: true),
                ],
              ),
              for (final item in walletHistory)
                _RowShell(
                  children: [
                    _Cell(item.amount, flex: 2),
                    _Cell(item.type, flex: 2),
                    _Cell(item.description, flex: 3),
                    _Cell(item.balanceAfterTransaction, flex: 3),
                    _Cell(item.createdDate, flex: 2),
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
