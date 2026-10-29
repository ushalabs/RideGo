import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../models/search_result_item.dart';

class SearchRepository {
  final SupabaseClient? _supabase;

  final List<SearchResultItem> _mockDatabase = [
    SearchResultItem(
      scheduleId: 'sch-001',
      vehicleId: 'v-001',
      vehicleName: 'Toyota HiAce GL Grandia',
      category: 'Van',
      operatorName: 'Van-Vans Samar',
      routeName: 'Catbalogan to Tacloban Express',
      departureTime: DateTime.now().add(const Duration(hours: 2)),
      availableCapacity: 8,
      totalCapacity: 14,
      fare: 150.0,
    ),
    SearchResultItem(
      scheduleId: 'sch-002',
      vehicleId: 'v-002',
      vehicleName: 'Nissan NV350 Premium',
      category: 'Van',
      operatorName: 'GrandTours Samar',
      routeName: 'Catbalogan to Tacloban Express',
      departureTime: DateTime.now().add(const Duration(hours: 4)),
      availableCapacity: 12,
      totalCapacity: 14,
      fare: 180.0,
    ),
    SearchResultItem(
      scheduleId: 'sch-003',
      vehicleId: 'v-003',
      vehicleName: 'Hino Grand Express Bus',
      category: 'Bus',
      operatorName: 'City Tours Express',
      routeName: 'Catbalogan to Tacloban Express',
      departureTime: DateTime.now().add(const Duration(hours: 1)),
      availableCapacity: 25,
      totalCapacity: 45,
      fare: 200.0,
    ),
    SearchResultItem(
      scheduleId: 'sch-004',
      vehicleId: 'v-004',
      vehicleName: 'Toyota Commuter Van',
      category: 'Van',
      operatorName: 'Duptours Samar',
      routeName: 'Catbalogan to Calbayog Highway Line',
      departureTime: DateTime.now().add(const Duration(hours: 3)),
      availableCapacity: 5,
      totalCapacity: 14,
      fare: 140.0,
    ),
    SearchResultItem(
      scheduleId: 'sch-005',
      vehicleId: 'v-005',
      vehicleName: 'Yamaha NMAX 155',
      category: 'Motor',
      operatorName: 'Samar Express Rider',
      routeName: 'Catbalogan to Jiabong Quick Transit',
      departureTime: DateTime.now().add(const Duration(minutes: 45)),
      availableCapacity: 1,
      totalCapacity: 1,
      fare: 80.0,
    ),
    SearchResultItem(
      scheduleId: 'sch-006',
      vehicleId: 'v-006',
      vehicleName: 'Toyota Vios Sedan (Private)',
      category: 'Car',
      operatorName: 'Leyte Private Car Service',
      routeName: 'Catbalogan to Tacloban Direct',
      departureTime: DateTime.now().add(const Duration(hours: 5)),
      availableCapacity: 4,
      totalCapacity: 4,
      fare: 350.0,
    ),
  ];

  SearchRepository({SupabaseClient? supabaseClient})
    : _supabase =
          supabaseClient ??
          (AppConfig.isConfigured ? Supabase.instance.client : null);

  bool get isConnected => _supabase != null && AppConfig.isConfigured;

  Future<List<SearchResultItem>> searchTrips({
    String? origin,
    String? destination,
    String? category,
    int passengers = 1,
    bool availableOnly = true,
    String sortBy =
        'departure_asc', // 'price_asc', 'price_desc', 'departure_asc'
  }) async {
    List<SearchResultItem> results = [];

    if (isConnected) {
      try {
        final res = await _supabase!.rpc(
          'search_available_trips',
          params: {
            'p_origin_name': origin ?? 'Catbalogan City',
            'p_destination_name': destination ?? 'Tacloban City',
            'p_category': category != null && category != 'All'
                ? category.toLowerCase()
                : null,
            'p_min_capacity': availableOnly ? passengers : 0,
          },
        );

        if (res != null) {
          results = (res as List)
              .map((j) => SearchResultItem.fromJson(j))
              .toList();
        }
      } catch (e) {
        if (kDebugMode) print('Supabase trip search fallback: $e');
      }
    }

    if (results.isEmpty) {
      results = List.from(_mockDatabase);
    }

    // Apply Client filters
    results = results.where((item) {
      if (category != null && category != 'All') {
        if (!item.category.toLowerCase().contains(category.toLowerCase())) {
          return false;
        }
      }

      if (availableOnly && item.availableCapacity < passengers) {
        return false;
      }

      if (origin != null && origin.isNotEmpty) {
        if (!item.routeName.toLowerCase().contains(origin.toLowerCase()) &&
            !item.operatorName.toLowerCase().contains(origin.toLowerCase())) {
          return false;
        }
      }

      return true;
    }).toList();

    // Sorting
    if (sortBy == 'price_asc') {
      results.sort((a, b) => a.fare.compareTo(b.fare));
    } else if (sortBy == 'price_desc') {
      results.sort((a, b) => b.fare.compareTo(a.fare));
    } else {
      results.sort((a, b) => a.departureTime.compareTo(b.departureTime));
    }

    return results;
  }
}
