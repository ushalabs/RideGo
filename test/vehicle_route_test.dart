import 'package:flutter_test/flutter_test.dart';
import 'package:ridego/features/routes/data/route_repository.dart';
import 'package:ridego/features/schedules/data/schedule_repository.dart';
import 'package:ridego/features/vehicles/data/vehicle_repository.dart';
import 'package:ridego/features/vehicles/models/vehicle_model.dart';

void main() {
  group('Phase 3: Vehicle & Route Management Tests', () {
    late VehicleRepository vehicleRepository;
    late RouteRepository routeRepository;
    late ScheduleRepository scheduleRepository;

    setUp(() {
      vehicleRepository = VehicleRepository();
      routeRepository = RouteRepository();
      scheduleRepository = ScheduleRepository();
    });

    test('Add vehicle with plate number and capacity', () async {
      final vehicle = await vehicleRepository.addVehicle(
        operatorId: 'mock-op-1',
        name: 'Toyota Commuter Deluxe',
        category: VehicleType.van,
        plateNumber: 'ABC-1234',
        capacity: 14,
        description: 'New model van with air conditioning',
      );

      expect(vehicle.name, 'Toyota Commuter Deluxe');
      expect(vehicle.category, VehicleType.van);
      expect(vehicle.plateNumber, 'ABC-1234');
      expect(vehicle.passengerCapacity, 14);
      expect(vehicle.status, 'active');
    });

    test(
      'Southbound and Northbound service corridors contain required locations',
      () async {
        final locations = await routeRepository.getLocations();
        final locationNames = locations.map((l) => l.name).toSet();

        // Verify Southbound coverage
        expect(locationNames.contains('Catbalogan City'), isTrue);
        expect(locationNames.contains('Paranas (Wright)'), isTrue);
        expect(locationNames.contains('Motiong'), isTrue);
        expect(locationNames.contains('Jiabong'), isTrue);
        expect(locationNames.contains('Villareal'), isTrue);
        expect(locationNames.contains('Calbiga'), isTrue);
        expect(locationNames.contains('Basey'), isTrue);
        expect(locationNames.contains('Marabut'), isTrue);
        expect(locationNames.contains('Santa Rita'), isTrue);
        expect(locationNames.contains('San Juanico Bridge'), isTrue);
        expect(locationNames.contains('Tacloban City'), isTrue);

        // Verify Northbound coverage
        expect(locationNames.contains('San Jorge'), isTrue);
        expect(locationNames.contains('Gandara'), isTrue);
        expect(locationNames.contains('Pagsanghan'), isTrue);
        expect(locationNames.contains('Tarangnan'), isTrue);
        expect(locationNames.contains('Santa Margarita'), isTrue);
        expect(locationNames.contains('Calbayog City'), isTrue);
      },
    );

    test('Route variant validates forward stop order and rejects impossible booking combinations', () async {
      final variants = await routeRepository.getRouteVariants();
      final southboundExpress = variants.firstWhere(
        (v) => v.id == 'rv-sb-main',
      );

      // Valid: Catbalogan -> Tacloban
      expect(
        southboundExpress.isValidStopCombination(
          'Catbalogan City',
          'Tacloban City',
        ),
        isTrue,
      );

      // Valid: Jiabong -> Calbiga
      expect(
        southboundExpress.isValidStopCombination('Jiabong', 'Calbiga'),
        isTrue,
      );

      // Invalid: Tacloban -> Catbalogan (backward on southbound variant)
      expect(
        southboundExpress.isValidStopCombination(
          'Tacloban City',
          'Catbalogan City',
        ),
        isFalse,
      );

      // Invalid: Same stop
      expect(
        southboundExpress.isValidStopCombination(
          'Catbalogan City',
          'Catbalogan City',
        ),
        isFalse,
      );
    });

    test('Schedule conflict prevention rejects overlapping exclusive vehicle assignments', () async {
      final departure = DateTime.now().add(const Duration(hours: 10));

      // First schedule assignment
      await scheduleRepository.createSchedule(
        operatorId: 'mock-op-1',
        operatorName: 'Van-Vans Samar',
        vehicleId: 'test-vehicle-conflict-1',
        vehicleName: 'Toyota HiAce',
        routeVariantId: 'rv-sb-main',
        routeName: 'Catbalogan to Tacloban Express',
        departureTime: departure,
        capacity: 14,
        fare: 150.0,
      );

      // Attempting to schedule the same vehicle within 30 minutes of existing departure
      expect(
        () => scheduleRepository.createSchedule(
          operatorId: 'mock-op-1',
          operatorName: 'Van-Vans Samar',
          vehicleId: 'test-vehicle-conflict-1',
          vehicleName: 'Toyota HiAce',
          routeVariantId: 'rv-sb-main',
          routeName: 'Catbalogan to Tacloban Express',
          departureTime: departure.add(const Duration(minutes: 30)),
          capacity: 14,
          fare: 150.0,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
