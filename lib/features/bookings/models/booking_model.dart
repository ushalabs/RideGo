enum BookingStatus {
  pending,
  confirmed,
  cancelled,
  completed;

  static BookingStatus fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'completed':
        return BookingStatus.completed;
      case 'pending':
      default:
        return BookingStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.completed:
        return 'Completed';
    }
  }
}

class BookingModel {
  final String id;
  final String reference;
  final String idempotencyKey;
  final String customerId;
  final String scheduleId;
  final String vehicleId;
  final String vehicleName;
  final String operatorId;
  final String operatorName;
  final String pickupLocation;
  final String dropoffLocation;
  final DateTime travelDate;
  final DateTime departureTime;
  final int passengerCount;
  final double baseFare;
  final double terminalFee;
  final double totalFare;
  final BookingStatus status;
  final String paymentStatus;
  final DateTime? paymentConfirmedAt;
  final DateTime createdAt;

  const BookingModel({
    required this.id,
    required this.reference,
    required this.idempotencyKey,
    required this.customerId,
    required this.scheduleId,
    required this.vehicleId,
    required this.vehicleName,
    required this.operatorId,
    required this.operatorName,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.travelDate,
    required this.departureTime,
    required this.passengerCount,
    required this.baseFare,
    this.terminalFee = 10.0,
    required this.totalFare,
    required this.status,
    this.paymentStatus = 'Cash at Terminal',
    this.paymentConfirmedAt,
    required this.createdAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as String,
      reference: json['booking_reference'] as String,
      idempotencyKey:
          json['idempotency_key'] as String? ?? json['id'] as String,
      customerId: json['customer_id'] as String,
      scheduleId: json['schedule_id'] as String,
      vehicleId: json['vehicle_id'] as String? ?? 'v-001',
      vehicleName: json['vehicle_name'] as String? ?? 'Van / Bus',
      operatorId: json['operator_id'] as String? ?? 'op-001',
      operatorName: json['operator_name'] as String? ?? 'Van-Vans Samar',
      pickupLocation: json['pickup_location'] as String,
      dropoffLocation: json['dropoff_location'] as String,
      travelDate: DateTime.parse(json['travel_date'] as String),
      departureTime: DateTime.parse(json['departure_time'] as String),
      passengerCount: json['passenger_count'] as int? ?? 1,
      baseFare: (json['base_fare'] as num?)?.toDouble() ?? 150.0,
      terminalFee: (json['terminal_fee'] as num?)?.toDouble() ?? 10.0,
      totalFare: (json['total_fare'] as num?)?.toDouble() ?? 160.0,
      status: BookingStatus.fromString(json['status'] as String?),
      paymentStatus: json['payment_status'] as String? ?? 'Cash at Terminal',
      paymentConfirmedAt: json['payment_confirmed_at'] != null
          ? DateTime.parse(json['payment_confirmed_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  bool get canCancel =>
      status == BookingStatus.pending || status == BookingStatus.confirmed;
}
