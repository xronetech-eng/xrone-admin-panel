import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/navigation/navigation_logger.dart';
import '../models/payments_model.dart';

class PilotTransactionsTable extends StatefulWidget {
  const PilotTransactionsTable({required this.rows, super.key});

  final List<PaymentTransaction> rows;

  @override
  State<PilotTransactionsTable> createState() => _PilotTransactionsTableState();
}

class _PilotTransactionsTableState extends State<PilotTransactionsTable> {
  String _query = '';
  String _status = PaymentStatusLabels.all;

  @override
  Widget build(BuildContext context) {
    final filteredRows = widget.rows.where((row) {
      final query = _query.toLowerCase();
      final matchesSearch = query.isEmpty || row.searchableText.contains(query);
      final matchesStatus = PaymentStatusLabels.matchesFilter(
        row.paymentStatus,
        _status,
      );
      return matchesSearch && matchesStatus;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PaymentsFilterBar(
          searchHint: 'Search pilot transactions',
          status: _status,
          statuses: _statusesFor(widget.rows.map((row) => row.paymentStatus)),
          onSearchChanged: (value) => setState(() => _query = value),
          onStatusChanged: (value) => setState(() => _status = value),
        ),
        SizedBox(height: AppSpacing.lg),
        Expanded(
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 1360.w,
                child: Column(
                  children: [
                    const _RowShell(
                      isHeader: true,
                      children: [
                        _Cell('Transaction ID', flex: 2, isHeader: true),
                        _Cell('Source Type', flex: 2, isHeader: true),
                        _Cell('User Name', flex: 2, isHeader: true),
                        _Cell('Pilot Name', flex: 2, isHeader: true),
                        _Cell('Amount', flex: 2, isHeader: true),
                        _Cell('Payment Method', flex: 2, isHeader: true),
                        _Cell('Payment Status', flex: 2, isHeader: true),
                        _Cell('Date', flex: 2, isHeader: true),
                        _Cell('Reference ID', flex: 2, isHeader: true),
                        _Cell('View', flex: 1, isHeader: true),
                      ],
                    ),
                    if (filteredRows.isEmpty)
                      Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: Text(
                          'No transactions found',
                          style: AppTextStyles.bodyMedium,
                        ),
                      )
                    else
                      for (final row in filteredRows)
                        _RowShell(
                          children: [
                            _Cell(row.transactionId, flex: 2),
                            _Cell(row.sourceType, flex: 2),
                            _Cell(row.userName, flex: 2),
                            _Cell(row.pilotName, flex: 2),
                            _Cell(row.amount, flex: 2),
                            _Cell(row.paymentMethod, flex: 2),
                            _StatusCell(row.paymentStatus),
                            _Cell(row.date, flex: 2),
                            _Cell(row.referenceId, flex: 2),
                            _ViewCell(
                              onPressed: () => _showDetails(context, row),
                            ),
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

  void _showDetails(BuildContext context, PaymentTransaction row) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(row.transactionId),
        content: Text(
          'Source: ${row.sourceType}\n'
          'User: ${row.userName}\n'
          'Pilot: ${row.pilotName}\n'
          'Amount: ${row.amount}\n'
          'Status: ${row.paymentStatus}\n'
          'Reference ID: ${row.referenceId}',
        ),
        actions: [
          TextButton(
            onPressed: () {
              NavigationLogger.source(
                'PilotTransactionsTable.dialog',
                action: 'pop',
                from: row.transactionId,
              );
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _PaymentsFilterBar extends StatelessWidget {
  const _PaymentsFilterBar({
    required this.searchHint,
    required this.status,
    required this.statuses,
    required this.onSearchChanged,
    required this.onStatusChanged,
  });

  final String searchHint;
  final String status;
  final List<String> statuses;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        SizedBox(
          width: 320.w,
          child: TextField(
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: searchHint,
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
              value: status,
              icon: const Icon(Icons.filter_list_rounded),
              items: [
                for (final item in statuses)
                  DropdownMenuItem(value: item, child: Text(item)),
              ],
              onChanged: (value) {
                if (value != null) onStatusChanged(value);
              },
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

class _ViewCell extends StatelessWidget {
  const _ViewCell({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Align(
        alignment: Alignment.centerLeft,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: TextButton(onPressed: onPressed, child: const Text('View')),
        ),
      ),
    );
  }
}
