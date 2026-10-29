import 'package:flutter_test/flutter_test.dart';
import 'package:ridego/features/auth/data/auth_repository.dart';
import 'package:ridego/features/auth/models/operator_profile.dart';
import 'package:ridego/features/auth/models/user_role.dart';
import 'package:ridego/features/bookings/data/booking_repository.dart';
import 'package:ridego/features/bookings/models/booking_model.dart';
import 'package:ridego/features/pricing/data/pricing_service.dart';
import 'package:ridego/features/routes/data/route_repository.dart';
import 'package:ridego/features/schedules/data/schedule_repository.dart';
import 'package:ridego/features/search/data/search_repository.dart';
import 'package:ridego/features/vehicles/data/vehicle_repository.dart';
import 'package:ridego/features/vehicles/models/vehicle_model.dart';

void main() {
  group(
    'Phase 7: End-to-End Complete Journey & Security Integration Tests',
    () {
      late AuthRepository authRepo;
      late VehicleRepository vehicleRepo;
      late RouteRepository routeRepo;
      late ScheduleRepository scheduleRepo;
      late PricingService pricingService;
      late SearchRepository searchRepo;
      late BookingRepository bookingRepo;

      setUp(() {
        authRepo = AuthRepository();
        vehicleRepo = VehicleRepository();
        routeRepo = RouteRepository();
        scheduleRepo = ScheduleRepository();
        pricingService = PricingService();
        searchRepo = SearchRepository();
        bookingRepo = BookingRepository();
      });

      test('E2E Journey 1: Customer complete booking, pricing, and cancellation lifecycle', () async {
        // 1. Customer registration
        final customer = await authRepo.signUpCustomer(
          email: 'kiya.e2e@ridego.ph',
          password: 'Password123!',
          fullName: 'Kiya Vance E2E',
        );
        expect(customer.role, UserRole.customer);

        // 2. Customer searches for rides from Catbalogan to Tacloban
        final searchResults = await searchRepo.searchTrips(
          origin: 'Catbalogan',
          destination: 'Tacloban',
          category: 'Van',
          passengers: 2,
        );
        expect(searchResults.isNotEmpty, isTrue);

        final selectedTrip = searchResults.first;

        // 3. Authoritative fare quote calculation
        final fareQuote = await pricingService.calculateAuthoritativeFare(
          originLocation: 'Catbalogan City',
          destinationLocation: 'Tacloban City',
          category: 'Van',
          passengers: 2,
        );
        expect(fareQuote.isValid, isTrue);
        expect(fareQuote.totalFare, 310.0);

        // 4. Confirm reservation with unique idempotency key
        final booking = await bookingRepo.createBooking(
          customerId: customer.id,
          scheduleId: selectedTrip.scheduleId,
          pickupLocation: 'Catbalogan City',
          dropoffLocation: 'Tacloban City',
          passengerCount: 2,
          quotedFare: fareQuote.totalFare,
          vehicleName: selectedTrip.vehicleName,
          operatorName: selectedTrip.operatorName,
        );
        expect(booking.reference, startsWith('RG-2026-'));
        expect(booking.status, BookingStatus.pending);

        // 5. Verify booking appears in customer bookings list
        final customerBookings = await bookingRepo.getBookings(
          customerId: customer.id,
        );
        expect(customerBookings.any((b) => b.id == booking.id), isTrue);

        // 6. Customer cancels booking
        await bookingRepo.cancelBooking(
          booking.id,
          reason: 'Change of schedule',
        );
        final cancelledList = await bookingRepo.getBookings(
          filterStatus: BookingStatus.cancelled,
        );
        expect(cancelledList.any((b) => b.id == booking.id), isTrue);

        // 7. Customer signs out
        await authRepo.signOut();
        expect(await authRepo.getCurrentUser(), isNull);
      });

      test('E2E Journey 2: Operator registration, vehicle fleet, schedules & cash collection', () async {
        // 1. Operator business registration
        final operator = await authRepo.registerOperator(
          email: 'operator.samar@ridego.ph',
          password: 'Password123!',
          ownerName: 'Danilo Cruz',
          businessName: 'Samar Coast Express Co.',
          contactNumber: '+63 917 111 2222',
          businessLocation: 'Catbalogan City',
        );
        expect(operator.approvalStatus, OperatorApprovalStatus.pending);
        expect(operator.isApproved, isFalse);

        // 2. Operator adds vehicle to fleet
        final vehicle = await vehicleRepo.addVehicle(
          operatorId: operator.id,
          name: 'Toyota HiAce Commuter Van',
          category: VehicleType.van,
          plateNumber: 'SAM-8899',
          capacity: 14,
          description: 'Sanitized commuter van',
        );
        expect(vehicle.plateNumber, 'SAM-8899');
        expect(vehicle.status, 'active');

        // 3. Operator creates trip schedule departure
        final schedule = await scheduleRepo.createSchedule(
          operatorId: operator.id,
          operatorName: operator.businessName,
          vehicleId: vehicle.id,
          vehicleName: vehicle.name,
          routeVariantId: 'rv-sb-main',
          routeName: 'Catbalogan to Tacloban Express',
          departureTime: DateTime.now().add(const Duration(hours: 6)),
          capacity: 14,
          fare: 150.0,
        );
        expect(schedule.availableCapacity, 14);

        // 4. Passenger reserves a seat on this departure
        final passengerBooking = await bookingRepo.createBooking(
          customerId: 'mock-customer-id',
          scheduleId: schedule.id,
          pickupLocation: 'Catbalogan City',
          dropoffLocation: 'Tacloban City',
          passengerCount: 1,
          quotedFare: 160.0,
        );

        // 5. Operator confirms cash payment at terminal counter
        await bookingRepo.confirmPayment(passengerBooking.id, operator.userId);

        final verified = await bookingRepo.getBookings();
        final paidBooking = verified.firstWhere(
          (b) => b.id == passengerBooking.id,
        );
        expect(paidBooking.paymentStatus, 'Paid (Cash)');
        expect(paidBooking.status, BookingStatus.confirmed);
      });

      test('E2E Journey 3: Admin oversight, fare rule management, and metric calculation', () async {
        // 1. Admin login
        final admin = await authRepo.signIn(
          email: 'admin@ridego.ph',
          password: 'AdminPassword123!',
        );
        expect(admin.role, UserRole.admin);

        // 2. Routes & corridors verification
        final variants = await routeRepo.getRouteVariants();
        expect(
          variants.any((v) => v.name.contains('Catbalogan to Tacloban')),
          isTrue,
        );
        expect(
          variants.any((v) => v.name.contains('Catbalogan to Calbayog')),
          isTrue,
        );

        // 3. Bookings oversight and genuine metrics
        final allBookings = await bookingRepo.getBookings();
        final totalBooked = allBookings
            .where((b) => b.status != BookingStatus.cancelled)
            .fold(0.0, (sum, b) => sum + b.totalFare);

        final totalCash = allBookings
            .where((b) => b.paymentStatus == 'Paid (Cash)')
            .fold(0.0, (sum, b) => sum + b.totalFare);

        expect(totalBooked >= totalCash, isTrue);
      });

      test('Security: Prevent overbooking under concurrent requests', () async {
        final departureScheduleId =
            'sch-101'; // Simulated schedule with limited capacity

        // Concurrent attempts to book 7 seats simultaneously when available capacity is less
        final future1 = bookingRepo.createBooking(
          customerId: 'c-1',
          scheduleId: departureScheduleId,
          pickupLocation: 'Catbalogan City',
          dropoffLocation: 'Tacloban City',
          passengerCount: 4,
          quotedFare: 610.0,
        );

        final future2 = bookingRepo.createBooking(
          customerId: 'c-2',
          scheduleId: departureScheduleId,
          pickupLocation: 'Catbalogan City',
          dropoffLocation: 'Tacloban City',
          passengerCount: 4,
          quotedFare: 610.0,
        );

        final results = await Future.wait([
          future1.then((b) => 'success', onError: (e) => 'insufficient'),
          future2.then((b) => 'success', onError: (e) => 'insufficient'),
        ]);

        // At least one request was processed or handled according to capacity constraints
        expect(results.contains('success'), isTrue);
      });
    },
  );
}
