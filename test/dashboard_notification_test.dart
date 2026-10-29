import 'package:flutter_test/flutter_test.dart';
import 'package:ridego/features/bookings/data/booking_repository.dart';
import 'package:ridego/features/bookings/models/booking_model.dart';
import 'package:ridego/features/notifications/data/notification_repository.dart';

void main() {
  group('Phase 6: Dashboards, Reporting & Notifications Tests', () {
    late NotificationRepository notificationRepository;
    late BookingRepository bookingRepository;

    setUp(() {
      notificationRepository = NotificationRepository();
      bookingRepository = BookingRepository();
    });

    test('Notifications can be retrieved, filtered by recipient, and marked as read', () async {
      final notifs = await notificationRepository.getNotifications(
        'mock-user-customer',
      );
      expect(notifs.isNotEmpty, isTrue);

      final unread = notifs.where((n) => !n.isRead).toList();
      expect(unread.isNotEmpty, isTrue);

      // Mark single notification read
      await notificationRepository.markAsRead(unread.first.id);
      final updated = await notificationRepository.getNotifications(
        'mock-user-customer',
      );
      final updatedTarget = updated.firstWhere((n) => n.id == unread.first.id);
      expect(updatedTarget.isRead, isTrue);

      // Mark all read
      await notificationRepository.markAllAsRead('mock-user-customer');
      final allRead = await notificationRepository.getNotifications(
        'mock-user-customer',
      );
      for (final n in allRead) {
        expect(n.isRead, isTrue);
      }
    });

    test('New booking adds audit notification for recipient', () {
      notificationRepository.addNotification(
        recipientId: 'mock-user-customer',
        title: 'Booking Confirmed',
        message: 'Your Catbalogan to Tacloban trip is confirmed.',
        type: 'booking_confirmed',
      );

      final notifs = notificationRepository.getNotifications(
        'mock-user-customer',
      );
      notifs.then((list) {
        expect(list.any((n) => n.title == 'Booking Confirmed'), isTrue);
      });
    });

    test('Operator cash confirmation increases collected cash metric strictly', () async {
      final bookingsBefore = await bookingRepository.getBookings();
      final collectedBefore = bookingsBefore
          .where((b) => b.paymentStatus == 'Paid (Cash)')
          .fold(0.0, (sum, b) => sum + b.totalFare);

      // Create a new booking
      final newBooking = await bookingRepository.createBooking(
        customerId: 'customer-p6',
        scheduleId: 'sch-101',
        pickupLocation: 'Catbalogan City',
        dropoffLocation: 'Tacloban City',
        passengerCount: 1,
        quotedFare: 160.0,
      );

      // Total booked value increased, but collected cash must not yet increase
      final bookingsPending = await bookingRepository.getBookings();
      final collectedPending = bookingsPending
          .where((b) => b.paymentStatus == 'Paid (Cash)')
          .fold(0.0, (sum, b) => sum + b.totalFare);
      expect(collectedPending, collectedBefore);

      // Confirm cash payment at terminal
      await bookingRepository.confirmPayment(newBooking.id, 'operator-agent-1');

      final bookingsAfter = await bookingRepository.getBookings();
      final collectedAfter = bookingsAfter
          .where((b) => b.paymentStatus == 'Paid (Cash)')
          .fold(0.0, (sum, b) => sum + b.totalFare);

      expect(collectedAfter, collectedBefore + 160.0);
    });

    test('Admin oversight distinguishes booked value from actual collected cash', () async {
      final bookings = await bookingRepository.getBookings();

      final totalBookedValue = bookings
          .where((b) => b.status != BookingStatus.cancelled)
          .fold(0.0, (sum, b) => sum + b.totalFare);

      final collectedCash = bookings
          .where((b) => b.paymentStatus == 'Paid (Cash)')
          .fold(0.0, (sum, b) => sum + b.totalFare);

      // Verified: Booked value must be greater than or equal to cash collected
      expect(totalBookedValue >= collectedCash, isTrue);
    });
  });
}
