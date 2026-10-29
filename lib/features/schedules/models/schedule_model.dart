class ScheduleModel {
  final String id;
  final String operatorId;
  final String operatorName;
  final String vehicleId;
  final String vehicleName;
  final String routeVariantId;
  final String routeName;
  final DateTime departureTime;
  final DateTime? expectedArrivalTime;
  final int availableCapacity;
  final int totalCapacity;
  final double fare;
  final String status;

  const ScheduleModel({
    required this.id,
    required this.operatorId,
    required this.operatorName,
    required this.vehicleId,
    required this.vehicleName,
    required this.routeVariantId,
    required this.routeName,
    required this.departureTime,
    this.expectedArrivalTime,
    required this.availableCapacity,
    required this.totalCapacity,
    required this.fare,
    this.status = 'scheduled',
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: json['id'] as String,
      operatorId: json['operator_id'] as String,
      operatorName: json['operator_name'] as String? ?? 'Operator',
      vehicleId: json['vehicle_id'] as String,
      vehicleName: json['vehicle_name'] as String? ?? 'Vehicle',
      routeVariantId: json['route_variant_id'] as String,
      routeName: json['route_name'] as String? ?? 'Samar - Leyte',
      departureTime: DateTime.parse(json['departure_time'] as String),
      expectedArrivalTime: json['expected_arrival_time'] != null
          ? DateTime.parse(json['expected_arrival_time'] as String)
          : null,
      availableCapacity: json['available_capacity'] as int? ?? 14,
      totalCapacity: json['total_capacity'] as int? ?? 14,
      fare: (json['fare'] as num?)?.toDouble() ?? 150.0,
      status: json['status'] as String? ?? 'scheduled',
    );
  }

  bool get hasCapacity => availableCapacity > 0;
}
