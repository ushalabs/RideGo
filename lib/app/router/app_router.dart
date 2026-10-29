import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/admin_dashboard_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/bookings/presentation/booking_flow_screen.dart';
import '../../features/bookings/presentation/my_bookings_screen.dart';
import '../../features/customer/presentation/category_screen.dart';
import '../../features/customer/presentation/customer_home_screen.dart';
import '../../features/customer/presentation/customer_shell.dart';
import '../../features/customer/presentation/vehicle_details_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/operator/presentation/operator_dashboard_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => CustomerShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const CustomerHomeScreen(),
        ),
        GoRoute(
          path: '/bookings',
          builder: (context, state) => const MyBookingsScreen(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/category/:type',
      builder: (context, state) {
        final category = state.pathParameters['type'] ?? 'Van';
        return CategoryScreen(categoryName: category);
      },
    ),
    GoRoute(
      path: '/vehicle/:id',
      builder: (context, state) {
        final vehicleId = state.pathParameters['id'] ?? '';
        return VehicleDetailsScreen(vehicleId: vehicleId);
      },
    ),
    GoRoute(
      path: '/booking/new',
      builder: (context, state) {
        final uri = state.uri;
        final vehicleId = uri.queryParameters['vehicleId'];
        final operatorName = uri.queryParameters['operator'];
        final fareStr = uri.queryParameters['fare'];
        final route = uri.queryParameters['route'];
        final fare = fareStr != null ? double.tryParse(fareStr) : null;

        return BookingFlowScreen(
          vehicleId: vehicleId,
          operatorName: operatorName,
          initialFare: fare,
          initialRoute: route,
        );
      },
    ),
    GoRoute(
      path: '/operator/dashboard',
      builder: (context, state) => const OperatorDashboardScreen(),
    ),
    GoRoute(
      path: '/admin/dashboard',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
  ],
);
