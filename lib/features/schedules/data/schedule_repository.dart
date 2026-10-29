import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../models/schedule_model.dart';

class ScheduleRepository {
  final SupabaseClient? _supabase;

  final List<ScheduleModel> _localSchedules = [
    ScheduleModel(
      id: 'sch-101',
      operatorId: 'mock-op-1',
      operatorName: 'Van-Vans Samar',
      vehicleId: 'v-local-1',
      vehicleName: 'Toyota HiAce GL Grandia',
      routeVariantId: 'rv-sb-main',
      routeName: 'Catbalogan to Tacloban Express',
      departureTime: DateTime.now().add(const Duration(hours: 3)),
      expectedArrivalTime: DateTime.now().add(const Duration(hours: 5)),
      availableCapacity: 8,
      totalCapacity: 14,
      fare: 150.0,
      status: 'scheduled',
    ),
    ScheduleModel(
      id: 'sch-102',
      operatorId: 'mock-op-1',
      operatorName: 'Van-Vans Samar',
      vehicleId: 'v-local-1',
      routeVariantId: 'rv-sb-main',
      vehicleName: 'Toyota HiAce GL Grandia',
      routeName: 'Catbalogan to Tacloban Express',
      departureTime: DateTime.now().add(const Duration(hours: 7)),
      expectedArrivalTime: DateTime.now().add(const Duration(hours: 9)),
      availableCapacity: 14,
      totalCapacity: 14,
      fare: 150.0,
      status: 'scheduled',
    ),
    ScheduleModel(
      id: 'sch-103',
      operatorId: 'mock-op-2',
      operatorName: 'GrandTours Leyte',
      vehicleId: 'v-local-3',
      vehicleName: 'Nissan NV350 Urvan',
      routeVariantId: 'rv-nb-main',
      routeName: 'Catbalogan to Calbayog Highway Line',
      departureTime: DateTime.now().add(const Duration(hours: 4)),
      expectedArrivalTime: DateTime.now().add(
        const Duration(hours: 5, minutes: 30),
      ),
      availableCapacity: 11,
      totalCapacity: 15,
      fare: 140.0,
      status: 'scheduled',
    ),
  ];

  ScheduleRepository({SupabaseClient? supabaseClient})
    : _supabase =
          supabaseClient ??
          (AppConfig.isConfigured ? Supabase.instance.client : null);

  bool get isConnected => _supabase != null && AppConfig.isConfigured;

  Future<List<ScheduleModel>> getSchedules({
    String? routeVariantId,
    DateTime? date,
  }) async {
    if (!isConnected) {
      return _localSchedules;
    }

    try {
      var query = _supabase!.from('schedules').select();
      if (routeVariantId != null) {
        query = query.eq('route_variant_id', routeVariantId);
      }
      final res = await query.order('departure_time');
      return (res as List).map((j) => ScheduleModel.fromJson(j)).toList();
    } catch (_) {
      return _localSchedules;
    }
  }

  Future<ScheduleModel> createSchedule({
    required String operatorId,
    required String operatorName,
    required String vehicleId,
    required String vehicleName,
    required String routeVariantId,
    required String routeName,
    required DateTime departureTime,
    DateTime? expectedArrivalTime,
    required int capacity,
    required double fare,
  }) async {
    // Conflict check: Ensure vehicle is not already scheduled within 2 hours of this departure
    final hasConflict = _localSchedules.any(
      (s) =>
          s.vehicleId == vehicleId &&
          s.status != 'cancelled' &&
          s.departureTime.difference(departureTime).abs().inMinutes < 120,
    );

    if (hasConflict) {
      throw Exception(
        'Vehicle is already assigned to another departure schedule within this operating window.',
      );
    }

    final newSchedule = ScheduleModel(
      id: 'sch-${DateTime.now().millisecondsSinceEpoch}',
      operatorId: operatorId,
      operatorName: operatorName,
      vehicleId: vehicleId,
      vehicleName: vehicleName,
      routeVariantId: routeVariantId,
      routeName: routeName,
      departureTime: departureTime,
      expectedArrivalTime:
          expectedArrivalTime ?? departureTime.add(const Duration(hours: 2)),
      availableCapacity: capacity,
      totalCapacity: capacity,
      fare: fare,
      status: 'scheduled',
    );

    if (!isConnected) {
      _localSchedules.add(newSchedule);
      return newSchedule;
    }

    final res = await _supabase!
        .from('schedules')
        .insert({
          'operator_id': operatorId,
          'vehicle_id': vehicleId,
          'route_variant_id': routeVariantId,
          'departure_time': departureTime.toIso8601String(),
          'expected_arrival_time': expectedArrivalTime?.toIso8601String(),
          'available_capacity': capacity,
          'total_capacity': capacity,
          'status': 'scheduled',
        })
        .select()
        .single();

    return ScheduleModel.fromJson(res);
  }
}
