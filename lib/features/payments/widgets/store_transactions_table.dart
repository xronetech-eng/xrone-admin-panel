import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../models/payments_model.dart';

class StoreTransactionsTable extends StatefulWidget {
  const StoreTransactionsTable({required this.rows, super.key});

  final List<StorePaymentTransaction> rows;

  @override
  State<StoreTransactionsTable> createState() => _StoreTransactionsTableState();
}

class _StoreTransactionsTableState extends State<StoreTransactionsTable> {
  String _query = '';
  String _status = PaymentStatusLabels.all;

  @override
  Widget build(BuildContext context) {
    final rows = widget.rows.where((row) {
      final localQuery = _query.toLowerCase();
      final matchesLocalSearch =
          localQuery.isEmpty || row.searchableText.contains(localQuery);
      final matchesLocalStatus = PaymentStatusLabels.matchesFilter(
        row.paymentStatus,
        _status,
      );
      return matchesLocalSearch && matchesLocalStatus;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            SizedBox(
              width: 320.w,
              child: TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: 'Search store payments',
                  border: _border(),
                  enabledBorder: _border(),
                  focusedBorder: _border(color: AppColors.primaryBlue),
                ),
              ),
            ),
            Container(
              height: 54.h,
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.borderLight),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _status,
                  icon: const Icon(Icons.filter_list_rounded),
                  items: [
                    for (final item in _statusesFor(
                      widget.rows.map((row) => row.paymentStatus),
                    ))
                      DropdownMenuItem(value: item, child: Text(item)),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _status = value);
                  },
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.lg),
        Expanded(
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 980.w,
                child: Column(
                  children: [
                    const _RowShell(
                      isHeader: true,
                      children: [
                        _Cell('Order Number', flex: 2, isHeader: true),
                        _Cell('Amount', flex: 2, isHeader: true),
                        _Cell('Payment Method', flex: 2, isHeader: true),
                        _Cell('Payment Status', flex: 2, isHeader: true),
                        _Cell('Created Date', flex: 2, isHeader: true),
                      ],
                    ),
                    if (rows.isEmpty)
                      Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: Text(
                          'No store payments found',
                          style: AppTextStyles.bodyMedium,
                        ),
                      )
                    else
                      for (final row in rows)
                        _RowShell(
                          children: [
                            _Cell(row.orderNumber, flex: 2),
                            _Cell(row.amount, flex: 2),
                            _Cell(row.paymentMethod, flex: 2),
                            _StatusCell(row.paymentStatus),
                            _Cell(row.createdDate, flex: 2),
                          ],
                        ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _border({Color color = AppColors.borderLight}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14.r),
      borderSide: BorderSide(color: color),
    );
  }

  List<String> _statusesFor(Iterable<String> rowStatuses) {
    final statuses = [
      PaymentStatusLabels.all,
      PaymentStatusLabels.successful,
      PaymentStatusLabels.pending,
      PaymentStatusLabels.failed,
    ];
    if (rowStatuses.any((status) => status.toLowerCase() == 'refunded')) {
      statuses.add('Refunded');
    }
    return statuses;
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

class _StatusCell extends StatelessWidget {
  const _StatusCell(this.status);

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      PaymentStatusLabels.successful => const Color(0xFF16A34A),
      PaymentStatusLabels.pending => const Color(0xFFF59E0B),
      PaymentStatusLabels.failed => const Color(0xFFDC2626),
      _ => AppColors.textMuted,
    };

    return Expanded(
      flex: 2,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999.r),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
