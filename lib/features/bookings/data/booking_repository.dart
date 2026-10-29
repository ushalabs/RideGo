import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/config/app_config.dart';
import '../models/booking_model.dart';

class BookingRepository {
  final SupabaseClient? _supabase;
  RealtimeChannel? _bookingSubscription;

  // In-memory persistent database for testing & preview
  final List<BookingModel> _localBookings = [
    BookingModel(
      id: 'b-local-1',
      reference: 'RG-2026-8472',
      idempotencyKey: 'idem-8472',
      customerId: 'mock-user-customer',
      scheduleId: 'sch-101',
      vehicleId: 'v-local-1',
      vehicleName: 'Toyota HiAce GL Grandia',
      operatorId: 'mock-op-1',
      operatorName: 'Van-Vans Samar',
      pickupLocation: 'Catbalogan City',
      dropoffLocation: 'Tacloban City',
      travelDate: DateTime.now().add(const Duration(days: 1)),
      departureTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
      passengerCount: 2,
      baseFare: 150.0,
      terminalFee: 10.0,
      totalFare: 310.0,
      status: BookingStatus.confirmed,
      paymentStatus: 'Cash at Terminal',
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    BookingModel(
      id: 'b-local-2',
      reference: 'RG-2026-7241',
      idempotencyKey: 'idem-7241',
      customerId: 'mock-user-customer',
      scheduleId: 'sch-102',
      vehicleId: 'v-local-2',
      vehicleName: 'Hino Grand Express Bus',
      operatorId: 'mock-op-1',
      operatorName: 'City Tours Express',
      pickupLocation: 'Catbalogan City',
      dropoffLocation: 'Tacloban City',
      travelDate: DateTime.now().subtract(const Duration(days: 4)),
      departureTime: DateTime.now().subtract(const Duration(days: 4, hours: 3)),
      passengerCount: 1,
      baseFare: 200.0,
      terminalFee: 10.0,
      totalFare: 210.0,
      status: BookingStatus.completed,
      paymentStatus: 'Paid (Cash)',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    BookingModel(
      id: 'b-local-3',
      reference: 'RG-2026-6812',
      idempotencyKey: 'idem-6812',
      customerId: 'mock-user-customer',
      scheduleId: 'sch-103',
      vehicleId: 'v-local-3',
      vehicleName: 'Toyota Commuter Van',
      operatorId: 'mock-op-2',
      operatorName: 'Duptours Samar',
      pickupLocation: 'Catbalogan City',
      dropoffLocation: 'Calbayog City',
      travelDate: DateTime.now().subtract(const Duration(days: 8)),
      departureTime: DateTime.now().subtract(const Duration(days: 8, hours: 1)),
      passengerCount: 1,
      baseFare: 140.0,
      terminalFee: 10.0,
      totalFare: 150.0,
      status: BookingStatus.cancelled,
      paymentStatus: 'Cancelled',
      createdAt: DateTime.now().subtract(const Duration(days: 9)),
    ),
  ];

  // Track simulated available capacities on departures
  final Map<String, int> _departureCapacities = {
    'sch-101': 8,
    'sch-102': 14,
    'sch-103': 11,
  };

  BookingRepository({SupabaseClient? supabaseClient})
    : _supabase =
          supabaseClient ??
          (AppConfig.isConfigured ? Supabase.instance.client : null);

  bool get isConnected => _supabase != null && AppConfig.isConfigured;

  Future<List<BookingModel>> getBookings({
    String? customerId,
    String? operatorId,
    BookingStatus? filterStatus,
  }) async {
    if (!isConnected) {
      return _localBookings.where((b) {
        final matchesStatus = filterStatus == null || b.status == filterStatus;
        return matchesStatus;
      }).toList();
    }

    try {
      var query = _supabase!.from('bookings').select();
      if (customerId != null) query = query.eq('customer_id', customerId);
      if (operatorId != null) query = query.eq('operator_id', operatorId);
      if (filterStatus != null) query = query.eq('status', filterStatus.name);

      final res = await query.order('created_at', ascending: false);
      return (res as List).map((j) => BookingModel.fromJson(j)).toList();
    } catch (e) {
      if (kDebugMode) print('Supabase getBookings fallback: $e');
      return _localBookings;
    }
  }

  Future<BookingModel> createBooking({
    required String customerId,
    required String scheduleId,
    required String pickupLocation,
    required String dropoffLocation,
    required int passengerCount,
    required double quotedFare,
    String? idempotencyKey,
    String vehicleName = 'Toyota HiAce GL Grandia',
    String operatorName = 'Van-Vans Samar',
  }) async {
    final key = idempotencyKey ?? const Uuid().v4();

    // 1. Check idempotency: If key already used, return existing booking
    final existing = _localBookings
        .where((b) => b.idempotencyKey == key)
        .toList();
    if (existing.isNotEmpty) {
      return existing.first;
    }

    // 2. Transactional capacity check
    final currentCap = _departureCapacities[scheduleId] ?? 14;
    if (currentCap < passengerCount) {
      throw Exception(
        'Insufficient seat capacity. Only $currentCap seat(s) remain.',
      );
    }

    if (isConnected) {
      try {
        final res = await _supabase!.rpc(
          'create_booking_atomic',
          params: {
            'p_idempotency_key': key,
            'p_customer_id': customerId,
            'p_schedule_id': scheduleId,
            'p_pickup_location': pickupLocation,
            'p_dropoff_location': dropoffLocation,
            'p_passenger_count': passengerCount,
            'p_quoted_fare': quotedFare,
          },
        );

        if (res != null && res['success'] == true) {
          final ref = res['booking_reference'] as String;
          final newBooking = BookingModel(
            id: res['booking_id'] as String? ?? const Uuid().v4(),
            reference: ref,
            idempotencyKey: key,
            customerId: customerId,
            scheduleId: scheduleId,
            vehicleId: 'v-001',
            vehicleName: vehicleName,
            operatorId: 'op-001',
            operatorName: operatorName,
            pickupLocation: pickupLocation,
            dropoffLocation: dropoffLocation,
            travelDate: DateTime.now().add(const Duration(days: 1)),
            departureTime: DateTime.now().add(
              const Duration(days: 1, hours: 2),
            ),
            passengerCount: passengerCount,
            baseFare: quotedFare - 10.0,
            terminalFee: 10.0,
            totalFare: quotedFare,
            status: BookingStatus.pending,
            createdAt: DateTime.now(),
          );
          _localBookings.insert(0, newBooking);
          return newBooking;
        } else {
          throw Exception(res?['error'] ?? 'Booking reservation failed.');
        }
      } catch (e) {
        if (kDebugMode) print('RPC create_booking_atomic error: $e');
        if (e.toString().contains('Insufficient')) rethrow;
      }
    }

    // Deduct simulated capacity atomically
    _departureCapacities[scheduleId] = currentCap - passengerCount;

    final bookingRef =
        'RG-2026-${(1000 + DateTime.now().millisecond * 7).toString().padLeft(4, '0')}';
    final newBooking = BookingModel(
      id: const Uuid().v4(),
      reference: bookingRef,
      idempotencyKey: key,
      customerId: customerId,
      scheduleId: scheduleId,
      vehicleId: 'v-001',
      vehicleName: vehicleName,
      operatorId: 'op-001',
      operatorName: operatorName,
      pickupLocation: pickupLocation,
      dropoffLocation: dropoffLocation,
      travelDate: DateTime.now().add(const Duration(days: 1)),
      departureTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
      passengerCount: passengerCount,
      baseFare: quotedFare - 10.0,
      terminalFee: 10.0,
      totalFare: quotedFare,
      status: BookingStatus.pending,
      createdAt: DateTime.now(),
    );

    _localBookings.insert(0, newBooking);
    return newBooking;
  }

  Future<void> cancelBooking(String bookingId, {String? reason}) async {
    final idx = _localBookings.indexWhere((b) => b.id == bookingId);
    if (idx != -1) {
      final existing = _localBookings[idx];
      if (existing.status == BookingStatus.completed) {
        throw Exception('Completed bookings cannot be cancelled.');
      }

      // Restore seats
      final curCap = _departureCapacities[existing.scheduleId] ?? 14;
      _departureCapacities[existing.scheduleId] =
          curCap + existing.passengerCount;

      _localBookings[idx] = BookingModel(
        id: existing.id,
        reference: existing.reference,
        idempotencyKey: existing.idempotencyKey,
        customerId: existing.customerId,
        scheduleId: existing.scheduleId,
        vehicleId: existing.vehicleId,
        vehicleName: existing.vehicleName,
        operatorId: existing.operatorId,
        operatorName: existing.operatorName,
        pickupLocation: existing.pickupLocation,
        dropoffLocation: existing.dropoffLocation,
        travelDate: existing.travelDate,
        departureTime: existing.departureTime,
        passengerCount: existing.passengerCount,
        baseFare: existing.baseFare,
        terminalFee: existing.terminalFee,
        totalFare: existing.totalFare,
        status: BookingStatus.cancelled,
        paymentStatus: 'Cancelled',
        createdAt: existing.createdAt,
      );
    }

    if (isConnected) {
      try {
        await _supabase!.rpc(
          'cancel_booking_atomic',
          params: {
            'p_booking_id': bookingId,
            'p_actor_id': _supabase.auth.currentUser?.id,
            'p_reason': reason ?? 'Customer requested cancellation',
          },
        );
      } catch (e) {
        if (kDebugMode) print('RPC cancel_booking_atomic: $e');
      }
    }
  }

  Future<void> confirmPayment(String bookingId, String staffUserId) async {
    final idx = _localBookings.indexWhere((b) => b.id == bookingId);
    if (idx != -1) {
      final existing = _localBookings[idx];
      _localBookings[idx] = BookingModel(
        id: existing.id,
        reference: existing.reference,
        idempotencyKey: existing.idempotencyKey,
        customerId: existing.customerId,
        scheduleId: existing.scheduleId,
        vehicleId: existing.vehicleId,
        vehicleName: existing.vehicleName,
        operatorId: existing.operatorId,
        operatorName: existing.operatorName,
        pickupLocation: existing.pickupLocation,
        dropoffLocation: existing.dropoffLocation,
        travelDate: existing.travelDate,
        departureTime: existing.departureTime,
        passengerCount: existing.passengerCount,
        baseFare: existing.baseFare,
        terminalFee: existing.terminalFee,
        totalFare: existing.totalFare,
        status: BookingStatus.confirmed,
        paymentStatus: 'Paid (Cash)',
        paymentConfirmedAt: DateTime.now(),
        createdAt: existing.createdAt,
      );
    }

    if (isConnected) {
      try {
        await _supabase!.rpc(
          'confirm_cash_payment_atomic',
          params: {'p_booking_id': bookingId, 'p_staff_user_id': staffUserId},
        );
      } catch (e) {
        if (kDebugMode) print('RPC confirm_cash_payment_atomic: $e');
      }
    }
  }

  void subscribeToRealtimeBookings(VoidCallback onUpdate) {
    if (!isConnected) return;

    try {
      _bookingSubscription = _supabase!
          .channel('public:bookings')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'bookings',
            callback: (payload) {
              onUpdate();
            },
          )
          .subscribe();
    } catch (e) {
      if (kDebugMode) print('Realtime subscription fallback: $e');
    }
  }

  void unsubscribeRealtime() {
    _bookingSubscription?.unsubscribe();
  }
}
