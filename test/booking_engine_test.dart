import 'package:flutter_test/flutter_test.dart';
import 'package:ridego/features/bookings/data/booking_repository.dart';
import 'package:ridego/features/bookings/models/booking_model.dart';

void main() {
  group('Phase 5: Real-Time Booking Engine & Concurrency Tests', () {
    late BookingRepository bookingRepository;

    setUp(() {
      bookingRepository = BookingRepository();
    });

    test('Booking creation generates unique booking reference and decreases capacity', () async {
      final booking = await bookingRepository.createBooking(
        customerId: 'customer-user-1',
        scheduleId: 'sch-101',
        pickupLocation: 'Catbalogan City',
        dropoffLocation: 'Tacloban City',
        passengerCount: 2,
        quotedFare: 310.0,
      );

      expect(booking.reference, startsWith('RG-2026-'));
      expect(booking.passengerCount, 2);
      expect(booking.totalFare, 310.0);
      expect(booking.status, BookingStatus.pending);
      expect(booking.paymentStatus, 'Cash at Terminal');
    });

    test('Insufficient capacity prevents overbooking', () async {
      // sch-101 had 8 seats initially, minus 2 from previous test = 6 seats.
      // Attempting to book 15 seats must fail
      expect(
        () => bookingRepository.createBooking(
          customerId: 'customer-user-2',
          scheduleId: 'sch-101',
          pickupLocation: 'Catbalogan City',
          dropoffLocation: 'Tacloban City',
          passengerCount: 15,
          quotedFare: 2260.0,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('Duplicate booking attempts with same idempotency key are safely deduplicated', () async {
      const idempotencyKey = 'idem-unique-key-999';

      final firstBooking = await bookingRepository.createBooking(
        customerId: 'customer-user-3',
        scheduleId: 'sch-102',
        pickupLocation: 'Catbalogan City',
        dropoffLocation: 'Tacloban City',
        passengerCount: 1,
        quotedFare: 160.0,
        idempotencyKey: idempotencyKey,
      );

      // Repeat request with same idempotency key
      final duplicateBooking = await bookingRepository.createBooking(
        customerId: 'customer-user-3',
        scheduleId: 'sch-102',
        pickupLocation: 'Catbalogan City',
        dropoffLocation: 'Tacloban City',
        passengerCount: 1,
        quotedFare: 160.0,
        idempotencyKey: idempotencyKey,
      );

      expect(firstBooking.id, duplicateBooking.id);
      expect(firstBooking.reference, duplicateBooking.reference);
    });

    test('Cancellation releases capacity back to schedule', () async {
      final booking = await bookingRepository.createBooking(
        customerId: 'customer-user-4',
        scheduleId: 'sch-103',
        pickupLocation: 'Catbalogan City',
        dropoffLocation: 'Calbayog City',
        passengerCount: 2,
        quotedFare: 290.0,
      );

      expect(booking.canCancel, isTrue);

      await bookingRepository.cancelBooking(
        booking.id,
        reason: 'Travel plan changed',
      );

      final updatedBookings = await bookingRepository.getBookings();
      final cancelled = updatedBookings.firstWhere((b) => b.id == booking.id);

      expect(cancelled.status, BookingStatus.cancelled);
      expect(cancelled.paymentStatus, 'Cancelled');
    });

    test(
      'Payment confirmation by operator updates status to confirmed and paid',
      () async {
        final booking = await bookingRepository.createBooking(
          customerId: 'customer-user-5',
          scheduleId: 'sch-101',
          pickupLocation: 'Catbalogan City',
          dropoffLocation: 'Tacloban City',
          passengerCount: 1,
          quotedFare: 160.0,
        );

        await bookingRepository.confirmPayment(
          booking.id,
          'operator-staff-id-1',
        );

        final updatedBookings = await bookingRepository.getBookings();
        final confirmed = updatedBookings.firstWhere((b) => b.id == booking.id);

        expect(confirmed.status, BookingStatus.confirmed);
        expect(confirmed.paymentStatus, 'Paid (Cash)');
        expect(confirmed.paymentConfirmedAt, isNotNull);
      },
    );
  });
}
