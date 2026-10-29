import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../models/vehicle_model.dart';

class VehicleRepository {
  final SupabaseClient? _supabase;

  // In-memory vehicles storage for testing & local development
  final List<VehicleModel> _localVehicles = [
    VehicleModel(
      id: 'v-local-1',
      operatorId: 'mock-op-1',
      name: 'Toyota HiAce GL Grandia',
      category: VehicleType.van,
      plateNumber: 'NDX-4821',
      passengerCapacity: 14,
      description:
          'Air-conditioned express commuter van for Samar-Leyte routes.',
      imageUrl: null,
      status: 'active',
      createdAt: DateTime.now(),
    ),
    VehicleModel(
      id: 'v-local-2',
      operatorId: 'mock-op-1',
      name: 'Hino Grand Express Bus',
      category: VehicleType.bus,
      plateNumber: 'EVC-7729',
      passengerCapacity: 45,
      description: 'Long-haul luxury coach serving Catbalogan and Tacloban.',
      imageUrl: null,
      status: 'active',
      createdAt: DateTime.now(),
    ),
  ];

  VehicleRepository({SupabaseClient? supabaseClient})
    : _supabase =
          supabaseClient ??
          (AppConfig.isConfigured ? Supabase.instance.client : null);

  bool get isConnected => _supabase != null && AppConfig.isConfigured;

  Future<List<VehicleModel>> getVehiclesByOperator(String operatorId) async {
    if (!isConnected) {
      return _localVehicles
          .where((v) => v.operatorId == operatorId || operatorId == 'mock-op-1')
          .toList();
    }

    try {
      final res = await _supabase!
          .from('vehicles')
          .select()
          .eq('operator_id', operatorId)
          .order('created_at', ascending: false);
      return (res as List).map((j) => VehicleModel.fromJson(j)).toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching operator vehicles: $e');
      return _localVehicles;
    }
  }

  Future<VehicleModel> addVehicle({
    required String operatorId,
    required String name,
    required VehicleType category,
    required String plateNumber,
    required int capacity,
    String description = '',
    String? imageUrl,
  }) async {
    final newVehicle = VehicleModel(
      id: 'v-${DateTime.now().millisecondsSinceEpoch}',
      operatorId: operatorId,
      name: name,
      category: category,
      plateNumber: plateNumber,
      passengerCapacity: capacity,
      description: description,
      imageUrl: imageUrl,
      status: 'active',
      createdAt: DateTime.now(),
    );

    if (!isConnected) {
      _localVehicles.insert(0, newVehicle);
      return newVehicle;
    }

    final res = await _supabase!
        .from('vehicles')
        .insert({
          'operator_id': operatorId,
          'name': name,
          'category': category.name,
          'plate_number': plateNumber,
          'passenger_capacity': capacity,
          'description': description,
          'image_url': imageUrl,
          'status': 'active',
        })
        .select()
        .single();

    return VehicleModel.fromJson(res);
  }

  Future<String?> uploadVehicleImage({
    required String vehicleId,
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    if (!isConnected) {
      return 'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?w=600';
    }

    try {
      final path = 'vehicles/$vehicleId/$fileName';
      await _supabase!.storage
          .from('vehicle-images')
          .uploadBinary(path, imageBytes);
      final publicUrl = _supabase.storage
          .from('vehicle-images')
          .getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      if (kDebugMode) print('Error uploading vehicle image: $e');
      return null;
    }
  }

  Future<void> updateVehicleStatus(String vehicleId, String status) async {
    if (!isConnected) {
      final idx = _localVehicles.indexWhere((v) => v.id == vehicleId);
      if (idx != -1) {
        final existing = _localVehicles[idx];
        _localVehicles[idx] = VehicleModel(
          id: existing.id,
          operatorId: existing.operatorId,
          name: existing.name,
          category: existing.category,
          plateNumber: existing.plateNumber,
          passengerCapacity: existing.passengerCapacity,
          description: existing.description,
          imageUrl: existing.imageUrl,
          status: status,
          createdAt: existing.createdAt,
        );
      }
      return;
    }

    await _supabase!
        .from('vehicles')
        .update({'status': status})
        .eq('id', vehicleId);
  }
}
