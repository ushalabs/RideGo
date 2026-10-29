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
    this.imageUrl,
    this.status = 'active',
    required this.createdAt,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] as String,
      operatorId: json['operator_id'] as String,
      name: json['name'] as String,
      category: VehicleType.fromString(json['category'] as String?),
      plateNumber: json['plate_number'] as String,
      passengerCapacity: json['passenger_capacity'] as int? ?? 14,
      description: json['description'] as String? ?? '',
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
      'image_url': imageUrl,
      'status': status,
    };
  }
}
