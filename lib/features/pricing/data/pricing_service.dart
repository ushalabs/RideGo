import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../models/fare_quote_model.dart';

class PricingService {
  final SupabaseClient? _supabase;

  PricingService({SupabaseClient? supabaseClient})
    : _supabase =
          supabaseClient ??
          (AppConfig.isConfigured ? Supabase.instance.client : null);

  bool get isConnected => _supabase != null && AppConfig.isConfigured;

  Future<FareQuoteModel> calculateAuthoritativeFare({
    required String originLocation,
    required String destinationLocation,
    required String category,
    int passengers = 1,
    bool isPrivate = false,
  }) async {
    // 1. Validate direction: Origin and destination cannot be identical
    if (originLocation.trim().toLowerCase() ==
        destinationLocation.trim().toLowerCase()) {
      return FareQuoteModel.error(
        'Pickup and Drop-off locations cannot be identical.',
      );
    }

    if (passengers < 1) {
      return FareQuoteModel.error('Passenger count must be at least 1.');
    }

    // 2. If connected to Supabase, call PostgreSQL RPC
    if (isConnected) {
      try {
        final res = await _supabase!.rpc(
          'calculate_authoritative_fare',
          params: {
            'p_origin_name': originLocation,
            'p_destination_name': destinationLocation,
            'p_category': category.toLowerCase(),
            'p_passengers': passengers,
            'p_is_private': isPrivate,
          },
        );

        if (res != null) {
          return FareQuoteModel.fromJson(Map<String, dynamic>.from(res));
        }
      } catch (e) {
        if (kDebugMode) print('RPC calculate_authoritative_fare error: $e');
      }
    }

    // 3. Authoritative Fallback / Offline Fare Rules
    double baseFare = 150.0;
    final catLower = category.toLowerCase();

    if (catLower == 'bus') {
      baseFare = 200.0;
    } else if (catLower == 'motor' || catLower == 'motorcycle') {
      baseFare = 80.0;
    } else if (catLower == 'car') {
      baseFare = 350.0;
    } else {
      // Van
      if (originLocation.contains('Calbayog') ||
          destinationLocation.contains('Calbayog')) {
        baseFare = 140.0;
      } else {
        baseFare = 150.0;
      }
    }

    const double segmentCharge = 0.0;
    const double terminalFee = 10.0;

    final double totalFare = isPrivate
        ? (baseFare + segmentCharge + terminalFee)
        : (((baseFare + segmentCharge) * passengers) + terminalFee);

    return FareQuoteModel(
      isValid: true,
      baseFare: baseFare,
      segmentCharge: segmentCharge,
      terminalFee: terminalFee,
      passengers: passengers,
      isPrivate: isPrivate,
      totalFare: totalFare,
      currency: 'PHP',
    );
  }
}
