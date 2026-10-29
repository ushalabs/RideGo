import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../models/location_model.dart';
import '../models/route_model.dart';

class RouteRepository {
  final SupabaseClient? _supabase;

  static const List<LocationModel> allSamarLeyteLocations = [
    LocationModel(
      id: 'loc-1',
      name: 'Catbalogan City',
      province: 'Samar',
      terminalName: 'Grand Central Terminal',
    ),
    LocationModel(
      id: 'loc-2',
      name: 'Jiabong',
      province: 'Samar',
      terminalName: 'Highway Terminal',
    ),
    LocationModel(
      id: 'loc-3',
      name: 'Motiong',
      province: 'Samar',
      terminalName: 'Poblacion Stop',
    ),
    LocationModel(
      id: 'loc-4',
      name: 'Paranas (Wright)',
      province: 'Samar',
      terminalName: 'Wright Junction',
    ),
    LocationModel(
      id: 'loc-5',
      name: 'San Jorge',
      province: 'Samar',
      terminalName: 'Highway Crossing',
    ),
    LocationModel(
      id: 'loc-6',
      name: 'Gandara',
      province: 'Samar',
      terminalName: 'Public Market Terminal',
    ),
    LocationModel(
      id: 'loc-7',
      name: 'Pagsanghan',
      province: 'Samar',
      terminalName: 'Junction',
    ),
    LocationModel(
      id: 'loc-8',
      name: 'Tarangnan',
      province: 'Samar',
      terminalName: 'Diversion Stop',
    ),
    LocationModel(
      id: 'loc-9',
      name: 'Santa Margarita',
      province: 'Samar',
      terminalName: 'Municipal Stop',
    ),
    LocationModel(
      id: 'loc-10',
      name: 'Calbayog City',
      province: 'Samar',
      terminalName: 'Central Bus Terminal',
    ),
    LocationModel(
      id: 'loc-11',
      name: 'Villareal',
      province: 'Samar',
      terminalName: 'Junction',
    ),
    LocationModel(
      id: 'loc-12',
      name: 'Pinabacdao',
      province: 'Samar',
      terminalName: 'Highway Stop',
    ),
    LocationModel(
      id: 'loc-13',
      name: 'Calbiga',
      province: 'Samar',
      terminalName: 'Town Center Station',
    ),
    LocationModel(
      id: 'loc-14',
      name: 'Basey',
      province: 'Samar',
      terminalName: 'Municipal Bus Terminal',
    ),
    LocationModel(
      id: 'loc-15',
      name: 'Marabut',
      province: 'Samar',
      terminalName: 'Coastal Stop',
    ),
    LocationModel(
      id: 'loc-16',
      name: 'Santa Rita',
      province: 'Samar',
      terminalName: 'Santa Rita Crossing',
    ),
    LocationModel(
      id: 'loc-17',
      name: 'San Juanico Bridge',
      province: 'Samar/Leyte',
      terminalName: 'San Juanico Landmark Stop',
    ),
    LocationModel(
      id: 'loc-18',
      name: 'Tacloban City',
      province: 'Leyte',
      terminalName: 'New Bus Terminal, Abucay',
    ),
  ];

  static final List<RouteVariantModel> defaultRouteVariants = [
    // Southbound: Catbalogan to Tacloban Express / Main Route
    RouteVariantModel(
      id: 'rv-sb-main',
      corridorId: 'cor-sb',
      name: 'Catbalogan to Tacloban Express',
      originId: 'loc-1',
      originName: 'Catbalogan City',
      destinationId: 'loc-18',
      destinationName: 'Tacloban City',
      estimatedMinutes: 120,
      stops: const [
        RouteStopModel(
          id: 's-1',
          routeVariantId: 'rv-sb-main',
          locationId: 'loc-1',
          locationName: 'Catbalogan City',
          stopOrder: 1,
        ),
        RouteStopModel(
          id: 's-2',
          routeVariantId: 'rv-sb-main',
          locationId: 'loc-2',
          locationName: 'Jiabong',
          stopOrder: 2,
        ),
        RouteStopModel(
          id: 's-3',
          routeVariantId: 'rv-sb-main',
          locationId: 'loc-3',
          locationName: 'Motiong',
          stopOrder: 3,
        ),
        RouteStopModel(
          id: 's-4',
          routeVariantId: 'rv-sb-main',
          locationId: 'loc-4',
          locationName: 'Paranas (Wright)',
          stopOrder: 4,
        ),
        RouteStopModel(
          id: 's-5',
          routeVariantId: 'rv-sb-main',
          locationId: 'loc-12',
          locationName: 'Pinabacdao',
          stopOrder: 5,
        ),
        RouteStopModel(
          id: 's-6',
          routeVariantId: 'rv-sb-main',
          locationId: 'loc-13',
          locationName: 'Calbiga',
          stopOrder: 6,
        ),
        RouteStopModel(
          id: 's-7',
          routeVariantId: 'rv-sb-main',
          locationId: 'loc-11',
          locationName: 'Villareal',
          stopOrder: 7,
        ),
        RouteStopModel(
          id: 's-8',
          routeVariantId: 'rv-sb-main',
          locationId: 'loc-16',
          locationName: 'Santa Rita',
          stopOrder: 8,
        ),
        RouteStopModel(
          id: 's-9',
          routeVariantId: 'rv-sb-main',
          locationId: 'loc-17',
          locationName: 'San Juanico Bridge',
          stopOrder: 9,
        ),
        RouteStopModel(
          id: 's-10',
          routeVariantId: 'rv-sb-main',
          locationId: 'loc-18',
          locationName: 'Tacloban City',
          stopOrder: 10,
        ),
      ],
    ),
    // Southbound: Catbalogan to Tacloban via Basey & Marabut Coastal Branch
    RouteVariantModel(
      id: 'rv-sb-coastal',
      corridorId: 'cor-sb',
      name: 'Catbalogan to Tacloban via Basey-Marabut',
      originId: 'loc-1',
      originName: 'Catbalogan City',
      destinationId: 'loc-18',
      destinationName: 'Tacloban City',
      estimatedMinutes: 150,
      stops: const [
        RouteStopModel(
          id: 'sc-1',
          routeVariantId: 'rv-sb-coastal',
          locationId: 'loc-1',
          locationName: 'Catbalogan City',
          stopOrder: 1,
        ),
        RouteStopModel(
          id: 'sc-2',
          routeVariantId: 'rv-sb-coastal',
          locationId: 'loc-13',
          locationName: 'Calbiga',
          stopOrder: 2,
        ),
        RouteStopModel(
          id: 'sc-3',
          routeVariantId: 'rv-sb-coastal',
          locationId: 'loc-14',
          locationName: 'Basey',
          stopOrder: 3,
        ),
        RouteStopModel(
          id: 'sc-4',
          routeVariantId: 'rv-sb-coastal',
          locationId: 'loc-15',
          locationName: 'Marabut',
          stopOrder: 4,
        ),
        RouteStopModel(
          id: 'sc-5',
          routeVariantId: 'rv-sb-coastal',
          locationId: 'loc-17',
          locationName: 'San Juanico Bridge',
          stopOrder: 5,
        ),
        RouteStopModel(
          id: 'sc-6',
          routeVariantId: 'rv-sb-coastal',
          locationId: 'loc-18',
          locationName: 'Tacloban City',
          stopOrder: 6,
        ),
      ],
    ),
    // Northbound: Catbalogan to Calbayog
    RouteVariantModel(
      id: 'rv-nb-main',
      corridorId: 'cor-nb',
      name: 'Catbalogan to Calbayog Highway Line',
      originId: 'loc-1',
      originName: 'Catbalogan City',
      destinationId: 'loc-10',
      destinationName: 'Calbayog City',
      estimatedMinutes: 90,
      stops: const [
        RouteStopModel(
          id: 'sn-1',
          routeVariantId: 'rv-nb-main',
          locationId: 'loc-1',
          locationName: 'Catbalogan City',
          stopOrder: 1,
        ),
        RouteStopModel(
          id: 'sn-2',
          routeVariantId: 'rv-nb-main',
          locationId: 'loc-2',
          locationName: 'Jiabong',
          stopOrder: 2,
        ),
        RouteStopModel(
          id: 'sn-3',
          routeVariantId: 'rv-nb-main',
          locationId: 'loc-3',
          locationName: 'Motiong',
          stopOrder: 3,
        ),
        RouteStopModel(
          id: 'sn-4',
          routeVariantId: 'rv-nb-main',
          locationId: 'loc-5',
          locationName: 'San Jorge',
          stopOrder: 4,
        ),
        RouteStopModel(
          id: 'sn-5',
          routeVariantId: 'rv-nb-main',
          locationId: 'loc-6',
          locationName: 'Gandara',
          stopOrder: 5,
        ),
        RouteStopModel(
          id: 'sn-6',
          routeVariantId: 'rv-nb-main',
          locationId: 'loc-7',
          locationName: 'Pagsanghan',
          stopOrder: 6,
        ),
        RouteStopModel(
          id: 'sn-7',
          routeVariantId: 'rv-nb-main',
          locationId: 'loc-8',
          locationName: 'Tarangnan',
          stopOrder: 7,
        ),
        RouteStopModel(
          id: 'sn-8',
          routeVariantId: 'rv-nb-main',
          locationId: 'loc-9',
          locationName: 'Santa Margarita',
          stopOrder: 8,
        ),
        RouteStopModel(
          id: 'sn-9',
          routeVariantId: 'rv-nb-main',
          locationId: 'loc-10',
          locationName: 'Calbayog City',
          stopOrder: 9,
        ),
      ],
    ),
  ];

  RouteRepository({SupabaseClient? supabaseClient})
    : _supabase =
          supabaseClient ??
          (AppConfig.isConfigured ? Supabase.instance.client : null);

  bool get isConnected => _supabase != null && AppConfig.isConfigured;

  Future<List<LocationModel>> getLocations() async {
    if (!isConnected) {
      return allSamarLeyteLocations;
    }

    try {
      final res = await _supabase!.from('locations').select().order('name');
      return (res as List).map((j) => LocationModel.fromJson(j)).toList();
    } catch (_) {
      return allSamarLeyteLocations;
    }
  }

  Future<List<RouteVariantModel>> getRouteVariants() async {
    if (!isConnected) {
      return defaultRouteVariants;
    }

    try {
      final res = await _supabase!.from('route_variants').select();
      if ((res as List).isNotEmpty) {
        return res
            .map(
              (j) => RouteVariantModel(
                id: j['id'],
                corridorId: j['corridor_id'],
                name: j['name'],
                originId: j['origin_id'],
                originName: 'Origin',
                destinationId: j['destination_id'],
                destinationName: 'Destination',
                estimatedMinutes: j['estimated_minutes'] ?? 120,
              ),
            )
            .toList();
      }
    } catch (_) {}
    return defaultRouteVariants;
  }
}
