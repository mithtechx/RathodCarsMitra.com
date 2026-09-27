import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/search/presentation/search_screen.dart';
import '../features/search/presentation/cab_list_screen.dart';
import '../features/search/presentation/custom_route_screen.dart';
import '../features/search/presentation/select_seats_screen.dart';
import '../features/search/presentation/cab_search_screen.dart';
import '../features/search/presentation/passenger_payment_screen.dart';
import '../features/bookings/presentation/my_booking_screen.dart';
import '../features/bookings/presentation/passenger_details_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/profile/presentation/driver_register_screen.dart';
import '../features/profile/presentation/driver_login_screen.dart';
import '../features/profile/presentation/driver_dashboard_screen.dart';
import 'scaffold_with_nav_bar.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  debugLogDiagnostics: true,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNavBar(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const SearchScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/my-bookings',
              builder: (context, state) => const MyBookingScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
    // Full screen routes
    GoRoute(
      path: '/cab-list',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return CabListScreen(
          from: extra['from'] ?? 'Bhopal',
          to: extra['to'] ?? 'Indore',
          date: extra['date'] ?? 'Sat, 19 Sep',
        );
      },
    ),
    GoRoute(
      path: '/select-seats',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return SelectSeatsScreen(cabDetails: extra);
      },
    ),
    GoRoute(
      path: '/passenger-payment',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return PassengerPaymentScreen(bookingData: extra);
      },
    ),
    GoRoute(
      path: '/custom-route',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CustomRouteScreen(),
    ),
    GoRoute(
      path: '/passenger-details',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return PassengerDetailsScreen(bookingData: extra);
      },
    ),
    GoRoute(
      path: '/driver-login',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const DriverLoginScreen(),
    ),
    GoRoute(
      path: '/driver-dashboard',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const DriverDashboardScreen(),
    ),
    GoRoute(
      path: '/profile/driver-register',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const DriverRegisterScreen(),
    ),
    GoRoute(
      path: '/cab-search',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CabSearchScreen(),
    ),
  ],
);