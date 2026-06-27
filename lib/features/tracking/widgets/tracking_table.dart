import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../models/tracking_model.dart';

class TrackingTable extends StatelessWidget {
  const TrackingTable({
    required this.type,
    required this.rows,
    required this.selectedIndex,
    required this.onView,
    super.key,
  });

  final TrackingTabType type;
  final List<TrackingRowData> rows;
  final int selectedIndex;
  final ValueChanged<int> onView;

  static const maxVisibleRows = 10;
  static const rowHeight = 68.0;

  @override
  Widget build(BuildContext context) {
    final visibleRowCount = math.min(maxVisibleRows, rows.length);

    return _TrackingCard(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 980.w,
          child: Column(
            children: [
              _RowShell(isHeader: true, children: _headers(type)),
              if (rows.isEmpty)
                SizedBox(
                  height: rowHeight.h,
                  child: _RowShell(
                    children: [
                      Expanded(
                        child: Text(
                          'No active tracking found',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  height: (rowHeight * visibleRowCount).h,
                  child: ListView.builder(
                    primary: false,
                    cacheExtent: 0,
                    itemExtent: rowHeight.h,
                    itemCount: rows.length,
                    itemBuilder: (context, index) {
                      return _TrackingRow(
                        type: type,
                        row: rows[index],
                        isSelected: index == selectedIndex,
                        onView: () => onView(index),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrackingRow extends StatelessWidget {
  const _TrackingRow({
    required this.type,
    required this.row,
    required this.isSelected,
    required this.onView,
  });

  final TrackingTabType type;
  final TrackingRowData row;
  final bool isSelected;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    return _RowShell(
      isSelected: isSelected,
      children: _cells(type, row, onView),
    );
  }
}

List<Widget> _headers(TrackingTabType type) {
  return switch (type) {
    TrackingTabType.bookings => const [
      _Cell('Booking ID', flex: 2, isHeader: true),
      _Cell('User Name', flex: 2, isHeader: true),
      _Cell('Pilot Name', flex: 2, isHeader: true),
      _Cell('Pickup Location', flex: 3, isHeader: true),
      _Cell('Drop Location', flex: 3, isHeader: true),
      _Cell('Booking Status', flex: 2, isHeader: true),
      _Cell('Created Date', flex: 2, isHeader: true),
      _Cell('View', flex: 1, isHeader: true),
    ],
    TrackingTabType.pilots => const [
      _Cell('Pilot Name', flex: 3, isHeader: true),
      _Cell('Assigned Orders', flex: 2, isHeader: true),
      _Cell('Active Deliveries', flex: 2, isHeader: true),
      _Cell('Current Status', flex: 2, isHeader: true),
      _Cell('Last Activity', flex: 2, isHeader: true),
      _Cell('View', flex: 1, isHeader: true),
    ],
    TrackingTabType.store => const [
      _Cell('Order Number', flex: 2, isHeader: true),
      _Cell('Customer', flex: 2, isHeader: true),
      _Cell('Total Amount', flex: 2, isHeader: true),
      _Cell('Payment Status', flex: 2, isHeader: true),
      _Cell('Order Status', flex: 2, isHeader: true),
      _Cell('Created Date', flex: 2, isHeader: true),
      _Cell('View', flex: 1, isHeader: true),
    ],
  };
}

List<Widget> _cells(
  TrackingTabType type,
  TrackingRowData row,
  VoidCallback onView,
) {
  return switch (type) {
    TrackingTabType.bookings => [
      _Cell(row.id, flex: 2),
      _Cell(row.primaryName, flex: 2),
      _Cell(row.secondaryName, flex: 2),
      _Cell(row.firstDetail, flex: 3),
      _Cell(row.secondDetail, flex: 3),
      _StatusCell(row.status),
      _Cell(row.createdDate, flex: 2),
      Expanded(flex: 1, child: _ViewButtonCell(onPressed: onView)),
    ],
    TrackingTabType.pilots => [
      _Cell(row.primaryName, flex: 3),
      _Cell(row.assignedOrders.toString(), flex: 2),
      _Cell(row.activeDeliveries.toString(), flex: 2),
      _StatusCell(row.status),
      _Cell(row.createdDate, flex: 2),
      Expanded(flex: 1, child: _ViewButtonCell(onPressed: onView)),
    ],
    TrackingTabType.store => [
      _Cell(row.id, flex: 2),
      _Cell(row.primaryName, flex: 2),
      _Cell(row.amount, flex: 2),
      _StatusCell(row.paymentStatus),
      _StatusCell(row.status),
      _Cell(row.createdDate, flex: 2),
      Expanded(flex: 1, child: _ViewButtonCell(onPressed: onView)),
    ],
  };
}

class _ViewButtonCell extends StatelessWidget {
  const _ViewButtonCell({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: TextButton(onPressed: onPressed, child: const Text('View')),
      ),
    );
  }
}

class _TrackingCard extends StatelessWidget {
  const _TrackingCard({required this.child});

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
      child: child,
    );
  }
}

class _RowShell extends StatelessWidget {
  const _RowShell({
    required this.children,
    this.isHeader = false,
    this.isSelected = false,
  });

  final List<Widget> children;
  final bool isHeader;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: isHeader ? 56.h : TrackingTable.rowHeight.h,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: isHeader
            ? AppColors.surface
            : isSelected
            ? AppColors.primaryBlueLight
            : AppColors.background,
        borderRadius: isHeader ? BorderRadius.circular(14.r) : null,
        border: isHeader
            ? null
            : const Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children,
      ),
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
      'Accepted' || 'Confirmed' => AppColors.primaryBlue,
      'In Progress' || 'Processing' || 'Shipped' => const Color(0xFF0891B2),
      'Completed' || 'Delivered' => const Color(0xFF16A34A),
      'Cancelled' => const Color(0xFFDC2626),
      'Pending' => const Color(0xFFF59E0B),
      _ => const Color(0xFF7C3AED),
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
