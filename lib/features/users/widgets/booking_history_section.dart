import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../models/users_model.dart';

class BookingHistorySection extends StatefulWidget {
  const BookingHistorySection({required this.bookings, super.key});

  final List<UserBookingHistoryData> bookings;

  static const rowsPerPage = 10;

  @override
  State<BookingHistorySection> createState() => _BookingHistorySectionState();
}

class _BookingHistorySectionState extends State<BookingHistorySection> {
  int _page = 0;

  @override
  void didUpdateWidget(BookingHistorySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final pageCount = _pageCount;
    if (_page >= pageCount) {
      _page = math.max(0, pageCount - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageBookings = _pageBookings;
    return _SectionCard(
      title: 'Booking History',
      footer: widget.bookings.isEmpty
          ? null
          : _PaginationControls(
              currentPage: _page,
              pageCount: _pageCount,
              onPrevious: _page == 0 ? null : () => setState(() => _page--),
              onNext: _page >= _pageCount - 1
                  ? null
                  : () => setState(() => _page++),
            ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tableWidth = math.max(1240.0, constraints.maxWidth);

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                children: [
                  const _BookingRow(
                    bookingId: 'Booking ID',
                    service: 'Service',
                    pilot: 'Pilot',
                    bookingDate: 'Booking Date',
                    amount: 'Amount',
                    discount: 'Discount',
                    couponCode: 'Coupon Code',
                    finalAmount: 'Final Amount',
                    cancellationReason: 'Cancellation Reason',
                    isHeader: true,
                  ),
                  if (widget.bookings.isEmpty)
                    _EmptyTableRow(message: 'No bookings found.')
                  else
                    for (final booking in pageBookings)
                      _BookingRow(
                        bookingId: booking.bookingId,
                        service: booking.service,
                        pilot: booking.pilot,
                        bookingDate: booking.bookingDate,
                        status: booking.status,
                        amount: booking.amount,
                        discount: booking.discount,
                        couponCode: booking.couponCode,
                        finalAmount: booking.finalAmount,
                        cancellationReason: booking.cancellationReason,
                      ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  int get _pageCount {
    if (widget.bookings.isEmpty) {
      return 1;
    }
    return (widget.bookings.length / BookingHistorySection.rowsPerPage).ceil();
  }

  List<UserBookingHistoryData> get _pageBookings {
    final start = _page * BookingHistorySection.rowsPerPage;
    final end = math.min(
      start + BookingHistorySection.rowsPerPage,
      widget.bookings.length,
    );
    if (start >= end) {
      return const [];
    }
    return widget.bookings.sublist(start, end);
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

class _BookingRow extends StatelessWidget {
  const _BookingRow({
    required this.bookingId,
    required this.service,
    required this.pilot,
    required this.bookingDate,
    required this.amount,
    required this.discount,
    required this.couponCode,
    required this.finalAmount,
    required this.cancellationReason,
    this.status,
    this.isHeader = false,
  });

  final String bookingId;
  final String service;
  final String pilot;
  final String bookingDate;
  final BookingStatus? status;
  final String amount;
  final String discount;
  final String couponCode;
  final String finalAmount;
  final String cancellationReason;
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
          _Cell(bookingId, flex: 2, isHeader: isHeader),
          _Cell(service, flex: 2, isHeader: isHeader),
          _Cell(pilot, flex: 2, isHeader: isHeader),
          _Cell(bookingDate, flex: 2, isHeader: isHeader),
          Expanded(
            flex: 2,
            child: isHeader
                ? _CellText('Status', isHeader: true)
                : _StatusBadge(status: status!),
          ),
          _Cell(amount, flex: 2, isHeader: isHeader),
          _Cell(discount, flex: 2, isHeader: isHeader),
          _Cell(couponCode, flex: 2, isHeader: isHeader),
          _Cell(finalAmount, flex: 2, isHeader: isHeader),
          _Cell(cancellationReason, flex: 3, isHeader: isHeader),
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
      child: _CellText(text, isHeader: isHeader),
    );
  }
}

class _CellText extends StatelessWidget {
  const _CellText(this.text, {required this.isHeader});

  final String text;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.bodyMedium.copyWith(
        color: isHeader ? AppColors.textMuted : AppColors.textDark,
        fontWeight: isHeader ? FontWeight.w800 : FontWeight.w600,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: status.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999.r),
        ),
        child: Text(
          status.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: status.color,
            fontSize: 12.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _PaginationControls extends StatelessWidget {
  const _PaginationControls({
    required this.currentPage,
    required this.pageCount,
    required this.onPrevious,
    required this.onNext,
  });

  final int currentPage;
  final int pageCount;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.center,
        children: [
          TextButton(onPressed: onPrevious, child: const Text('Previous')),
          IconButton(
            tooltip: 'Previous page',
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Container(
            constraints: BoxConstraints(minWidth: 72.w),
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(999.r),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Text(
              '${currentPage + 1} / $pageCount',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Next page',
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
          TextButton(onPressed: onNext, child: const Text('Next')),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.footer});

  final String title;
  final Widget child;
  final Widget? footer;

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
          if (footer != null) ...[SizedBox(height: AppSpacing.lg), footer!],
        ],
      ),
    );
  }
}
