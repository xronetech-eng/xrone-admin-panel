import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xroneadminpanel/core/constants/app_spacing.dart';
import 'package:xroneadminpanel/features/users/models/users_model.dart';
import 'package:xroneadminpanel/features/users/widgets/booking_history_section.dart';
import 'package:xroneadminpanel/features/users/widgets/live_tracking_section.dart';
import 'package:xroneadminpanel/features/users/widgets/offers_used_section.dart';
import 'package:xroneadminpanel/features/users/widgets/payment_history_section.dart';
import 'package:xroneadminpanel/features/users/widgets/saved_locations_section.dart';
import 'package:xroneadminpanel/features/users/widgets/user_details_panel.dart';
import 'package:xroneadminpanel/features/users/widgets/users_overview_cards.dart';
import 'package:xroneadminpanel/features/users/widgets/users_table.dart';

void main() {
  for (final width in const [1280.0, 1024.0, 768.0]) {
    testWidgets('Users screen widgets do not flex-overflow at ${width}px', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final errors = <FlutterErrorDetails>[];
      final previousOnError = FlutterError.onError;
      FlutterError.onError = errors.add;

      try {
        await tester.pumpWidget(_UsersOverflowHarness(width: width));
        await tester.pump();
      } finally {
        FlutterError.onError = previousOnError;
      }

      final overflowErrors = errors.where((details) {
        return details.exceptionAsString().contains('RenderFlex overflowed');
      }).toList();

      expect(
        overflowErrors,
        isEmpty,
        reason: overflowErrors
            .map((error) => error.exceptionAsString())
            .join('\n'),
      );
    });
  }
}

class _UsersOverflowHarness extends StatelessWidget {
  const _UsersOverflowHarness({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(1920, 1080),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: SizedBox(
              width: width,
              height: 1800,
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: _UsersOverflowContent(width: width),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _UsersOverflowContent extends StatelessWidget {
  const _UsersOverflowContent({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    final users = [_longUser, _fallbackUser];
    final activity = Column(
      children: [
        SavedLocationsSection(locations: _longUser.savedLocations),
        SizedBox(height: AppSpacing.lg),
        BookingHistorySection(bookings: _longUser.bookingHistory),
        SizedBox(height: AppSpacing.lg),
        PaymentHistorySection(payments: _longUser.paymentHistory),
        SizedBox(height: AppSpacing.lg),
        OffersUsedSection(offers: _longUser.offersUsed),
        SizedBox(height: AppSpacing.lg),
        LiveTrackingSection(tracking: _longUser.liveTracking),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UsersOverviewCards(users: users),
        SizedBox(height: AppSpacing.xl),
        UsersTable(users: users, selectedIndex: 0, onUserSelected: (_) {}),
        SizedBox(height: AppSpacing.xl),
        if (width >= 1200)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 390.w,
                child: UserDetailsPanel(user: _longUser),
              ),
              SizedBox(width: AppSpacing.lg),
              Expanded(child: activity),
            ],
          )
        else
          Column(
            children: [
              UserDetailsPanel(user: _longUser),
              SizedBox(height: AppSpacing.lg),
              activity,
            ],
          ),
      ],
    );
  }
}

const _longText =
    'A very long production value that should stay inside its cell without '
    'triggering any horizontal RenderFlex overflow warnings';

const _longBookingId = 'booking-12345678-1234-1234-1234-123456789012';

const _longUser = UserAdminViewData(
  id: 'user-12345678-1234-1234-1234-123456789012',
  profileLabel: 'NA',
  name: 'Name not available',
  phone: 'No phone',
  email: 'averyverylongemailaddress.for.production.testing@example-company.com',
  gender: 'Not specified',
  city: 'Not specified',
  bookingsCount: 123456,
  latestBookingDate: '02 Jun 2026',
  latestBookingStatus: 'completed',
  status: UserStatus.active,
  emergencyPhone: 'No phone',
  createdDate: '02 Jun 2026',
  savedLocations: [
    UserSavedLocationData(
      title: _longText,
      address: _longText,
      city: _longText,
      state: _longText,
      pincode: '560001',
      latitude: '12.971598700000000',
      longitude: '77.594566000000000',
    ),
  ],
  bookingHistory: [
    UserBookingHistoryData(
      bookingId: _longBookingId,
      service: _longText,
      pilot: 'pilot-12345678-1234-1234-1234-123456789012',
      bookingDate: '02 Jun 2026',
      status: BookingStatus.completed,
      amount: 'Rs. 123456789.99',
      discount: 'Rs. 12345.67',
      couponCode: 'SUMMER-PRODUCTION-COUPON-CODE-2026',
      finalAmount: 'Rs. 123444444.32',
      cancellationReason: _longText,
    ),
  ],
  paymentHistory: [
    UserPaymentHistoryData(
      transactionId: 'txn-12345678-1234-1234-1234-123456789012',
      bookingId: _longBookingId,
      paymentType: 'international-card-payment-with-long-label',
      status: 'settled-successfully-with-provider-reference',
      totalPaid: 'Rs. 123456789.99',
      pilotCharges: 'Rs. 12345.67',
      adminCharges: 'Rs. 98765.43',
      transactionDate: '02 Jun 2026',
    ),
  ],
  offersUsed: [
    UserOfferUsedData(
      offerTitle: _longText,
      couponCode: 'SUMMER-PRODUCTION-COUPON-CODE-2026',
      discountAmount: 'Rs. 12345.67',
      usageDate: '02 Jun 2026',
    ),
  ],
  liveTracking: UserLiveTrackingData(
    currentBooking: _longBookingId,
    pilotName: 'A pilot name that is intentionally long for layout testing',
    currentStatus: 'active-with-very-long-status-label',
    latitude: '12.971598700000000',
    longitude: '77.594566000000000',
    trackingStatus: 'tracking-status-with-long-value',
  ),
);

const _fallbackUser = UserAdminViewData(
  id: 'user-87654321-4321-4321-4321-210987654321',
  profileLabel: 'NA',
  name: 'Name not available',
  phone: 'No phone',
  email: 'No email',
  gender: 'Not specified',
  city: 'Not specified',
  bookingsCount: 0,
  latestBookingDate: '-',
  latestBookingStatus: '-',
  status: UserStatus.active,
  emergencyPhone: 'No phone',
  createdDate: '-',
  savedLocations: [],
  bookingHistory: [],
  paymentHistory: [],
  offersUsed: [],
  liveTracking: UserLiveTrackingData.empty,
);
