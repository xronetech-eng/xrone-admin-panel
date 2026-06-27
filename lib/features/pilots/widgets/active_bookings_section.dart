import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../models/pilots_model.dart';
import '_pilot_ui.dart';

class ActiveBookingsSection extends StatelessWidget {
  const ActiveBookingsSection({required this.bookings, super.key});

  final List<PilotActiveBookingData> bookings;

  @override
  Widget build(BuildContext context) {
    return PilotSectionCard(
      title: 'Active Bookings',
      subtitle: 'Read only',
      child: bookings.isEmpty
          ? const PilotEmptyState(message: 'No active bookings.')
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 1040.w,
                child: Column(
                  children: [
                    const _HeaderRow(),
                    for (final booking in bookings) _BookingRow(booking),
                  ],
                ),
              ),
            ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    return _TableShell(
      isHeader: true,
      children: const [
        _Cell('Booking ID', flex: 2, isHeader: true),
        _Cell('User', flex: 2, isHeader: true),
        _Cell('Phone', flex: 2, isHeader: true),
        _Cell('Service', flex: 2, isHeader: true),
        _Cell('Status', flex: 2, isHeader: true),
        _Cell('Booking Date', flex: 2, isHeader: true),
        _Cell('Location', flex: 3, isHeader: true),
        _Cell('Area', flex: 2, isHeader: true),
        _Cell('Price', flex: 2, isHeader: true),
      ],
    );
  }
}

class _BookingRow extends StatelessWidget {
  const _BookingRow(this.booking);

  final PilotActiveBookingData booking;

  @override
  Widget build(BuildContext context) {
    return _TableShell(
      children: [
        _Cell(booking.bookingId, flex: 2),
        _Cell(booking.user, flex: 2),
        _Cell(booking.customerPhone, flex: 2),
        _Cell(booking.service, flex: 2),
        Expanded(
          flex: 2,
          child: PilotStatusPill(
            label: booking.status.label,
            color: booking.status.color,
          ),
        ),
        _Cell(booking.bookingDate, flex: 2),
        _Cell(booking.location, flex: 3),
        _Cell(booking.area, flex: 2),
        _Cell(booking.price, flex: 2),
      ],
    );
  }
}

class _TableShell extends StatelessWidget {
  const _TableShell({required this.children, this.isHeader = false});

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
