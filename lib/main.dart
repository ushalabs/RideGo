import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (AppConfig.isConfigured) {
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
      );
      if (kDebugMode) {
        print('Supabase initialized successfully.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Supabase initialization deferred: $e');
      }
    }
  } else {
    if (kDebugMode) {
      print('Running RideGo in local preview mode with verified demo data.');
    }
  }

  runApp(const ProviderScope(child: RideGoApp()));
}
