enum VehicleType {
  van,
  bus,
  car,
  motorcycle;

  static VehicleType fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'bus':
        return VehicleType.bus;
      case 'car':
        return VehicleType.car;
      case 'motorcycle':
      case 'motor':
        return VehicleType.motorcycle;
      case 'van':
      default:
        return VehicleType.van;
    }
  }

  String get displayName {
    switch (this) {
      case VehicleType.van:
        return 'Van';
      case VehicleType.bus:
        return 'Bus';
      case VehicleType.car:
        return 'Car';
      case VehicleType.motorcycle:
        return 'Motorcycle';
    }
  }
}

class VehicleModel {
  final String id;
  final String operatorId;
  final String name;
  final VehicleType category;
  final String plateNumber;
  final int passengerCapacity;
  final String description;
  final String baseLocation;
  final double basePrice;
  final String? imageUrl;
  final String status;
  final DateTime createdAt;

  const VehicleModel({
    required this.id,
    required this.operatorId,
    required this.name,
    required this.category,
    required this.plateNumber,
    required this.passengerCapacity,
    this.description = '',
    this.baseLocation = 'Catbalogan Central Terminal',
    this.basePrice = 150.0,
    this.imageUrl,
    this.status = 'active',
    required this.createdAt,
  });

  VehicleModel copyWith({
    String? name,
    VehicleType? category,
    String? plateNumber,
    int? passengerCapacity,
    String? description,
    String? baseLocation,
    double? basePrice,
    String? status,
  }) {
    return VehicleModel(
      id: id,
      operatorId: operatorId,
      name: name ?? this.name,
      category: category ?? this.category,
      plateNumber: plateNumber ?? this.plateNumber,
      passengerCapacity: passengerCapacity ?? this.passengerCapacity,
      description: description ?? this.description,
      baseLocation: baseLocation ?? this.baseLocation,
      basePrice: basePrice ?? this.basePrice,
      imageUrl: imageUrl,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] as String,
      operatorId: json['operator_id'] as String,
      name: json['name'] as String,
      category: VehicleType.fromString(json['category'] as String?),
      plateNumber: json['plate_number'] as String,
      passengerCapacity: json['passenger_capacity'] as int? ?? 14,
      description: json['description'] as String? ?? '',
      baseLocation:
          json['base_location'] as String? ?? 'Catbalogan Central Terminal',
      basePrice: (json['base_price'] as num?)?.toDouble() ?? 150.0,
      imageUrl: json['image_url'] as String?,
      status: json['status'] as String? ?? 'active',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'operator_id': operatorId,
      'name': name,
      'category': category.name,
      'plate_number': plateNumber,
      'passenger_capacity': passengerCapacity,
      'description': description,
      'base_location': baseLocation,
      'base_price': basePrice,
      'image_url': imageUrl,
      'status': status,
    };
  }
}
