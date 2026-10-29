class RouteStopModel {
  final String id;
  final String routeVariantId;
  final String locationId;
  final String locationName;
  final int stopOrder;
  final bool allowPickup;
  final bool allowDropoff;
  final int estimatedMinutesFromOrigin;

  const RouteStopModel({
    required this.id,
    required this.routeVariantId,
    required this.locationId,
    required this.locationName,
    required this.stopOrder,
    this.allowPickup = true,
    this.allowDropoff = true,
    this.estimatedMinutesFromOrigin = 0,
  });

  factory RouteStopModel.fromJson(Map<String, dynamic> json) {
    return RouteStopModel(
      id: json['id'] as String,
      routeVariantId: json['route_variant_id'] as String,
      locationId: json['location_id'] as String,
      locationName: json['location_name'] as String? ?? '',
      stopOrder: json['stop_order'] as int,
      allowPickup: json['allow_pickup'] as bool? ?? true,
      allowDropoff: json['allow_dropoff'] as bool? ?? true,
      estimatedMinutesFromOrigin:
          json['estimated_minutes_from_origin'] as int? ?? 0,
    );
  }
}

class RouteVariantModel {
  final String id;
  final String corridorId;
  final String name;
  final String originId;
  final String originName;
  final String destinationId;
  final String destinationName;
  final int estimatedMinutes;
  final List<RouteStopModel> stops;

  const RouteVariantModel({
    required this.id,
    required this.corridorId,
    required this.name,
    required this.originId,
    required this.originName,
    required this.destinationId,
    required this.destinationName,
    this.estimatedMinutes = 120,
    this.stops = const [],
  });

  bool isValidStopCombination(String pickupLocation, String dropoffLocation) {
    int? pickupIndex;
    int? dropoffIndex;

    for (int i = 0; i < stops.length; i++) {
      if (stops[i].locationName.toLowerCase() == pickupLocation.toLowerCase()) {
        pickupIndex = stops[i].stopOrder;
      }
      if (stops[i].locationName.toLowerCase() ==
          dropoffLocation.toLowerCase()) {
        dropoffIndex = stops[i].stopOrder;
      }
    }

    if (pickupIndex == null || dropoffIndex == null) return false;
    return pickupIndex < dropoffIndex; // Must travel in forward direction
  }
}
