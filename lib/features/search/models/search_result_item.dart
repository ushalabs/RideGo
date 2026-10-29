class SearchResultItem {
  final String scheduleId;
  final String vehicleId;
  final String vehicleName;
  final String category;
  final String? imageUrl;
  final String operatorName;
  final String routeName;
  final DateTime departureTime;
  final int availableCapacity;
  final int totalCapacity;
  final double fare;

  const SearchResultItem({
    required this.scheduleId,
    required this.vehicleId,
    required this.vehicleName,
    required this.category,
    this.imageUrl,
    required this.operatorName,
    required this.routeName,
    required this.departureTime,
    required this.availableCapacity,
    required this.totalCapacity,
    required this.fare,
  });

  factory SearchResultItem.fromJson(Map<String, dynamic> json) {
    return SearchResultItem(
      scheduleId: json['schedule_id'] as String,
      vehicleId: json['vehicle_id'] as String,
      vehicleName: json['vehicle_name'] as String,
      category: json['vehicle_category'] as String? ?? 'Van',
      imageUrl: json['image_url'] as String?,
      operatorName: json['operator_name'] as String? ?? 'Operator',
      routeName: json['route_name'] as String? ?? 'Samar - Leyte',
      departureTime: DateTime.parse(json['departure_time'] as String),
      availableCapacity: json['available_capacity'] as int? ?? 14,
      totalCapacity: json['total_capacity'] as int? ?? 14,
      fare: (json['calculated_fare'] as num?)?.toDouble() ?? 150.0,
    );
  }
}
