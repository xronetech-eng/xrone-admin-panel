import 'package:flutter_test/flutter_test.dart';
import 'package:xroneadminpanel/features/users/models/users_model.dart';

void main() {
  group('User details display mapping', () {
    test('hides raw UUIDs and formats epoch booking dates', () {
      const rawBookingId = '123e4567-e89b-12d3-a456-426614174000';

      final booking = UserBookingHistoryData.fromRow({
        'id': rawBookingId,
        'service_id': '123e4567-e89b-12d3-a456-426614174001',
        'pilot_id': '123e4567-e89b-12d3-a456-426614174002',
        'booking_date': 1772536620000,
        'status': 'completed',
      });

      expect(booking.bookingId, '123e4567...4000');
      expect(booking.bookingIdTooltipText, rawBookingId);
      expect(booking.lookupBookingId, rawBookingId);
      expect(booking.service, 'Service not available');
      expect(booking.pilot, 'Pilot not assigned');
      expect(booking.bookingDate, isNot(contains('1772536620000')));
      expect(
        booking.bookingDate,
        matches(RegExp(r'^\d{2} [A-Z][a-z]{2} \d{4}, \d{1,2}:\d{2} [AP]M$')),
      );
    });

    test('uses human readable booking, service, and pilot labels', () {
      final booking = UserBookingHistoryData.fromRow({
        'id': '123e4567-e89b-12d3-a456-426614174000',
        'booking_number': 'XRN-2026-001',
        'service_name': 'Wedding',
        'pilot_name': 'Rahul Sharma',
        'booking_date': '2026-06-02T10:30:00',
        'status': 'accepted',
      });

      expect(booking.bookingId, 'XRN-2026-001');
      expect(booking.service, 'Wedding');
      expect(booking.pilot, 'Rahul Sharma');
      expect(booking.bookingDate, '02 Jun 2026, 10:30 AM');
    });

    test('truncates payment booking IDs with full ID tooltip', () {
      const rawBookingId = '123e4567-e89b-12d3-a456-426614174000';

      final payment = UserPaymentHistoryData.fromRow({
        'transaction_id': 'txn_123',
        'booking_id': rawBookingId,
        'transaction_type': 'card',
        'status': 'success',
      });

      expect(payment.bookingId, '123e4567...4000');
      expect(payment.bookingIdTooltipText, rawBookingId);
    });
  });
}
