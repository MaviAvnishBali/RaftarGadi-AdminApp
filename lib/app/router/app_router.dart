import 'package:admin_app/app/router/routes.dart';
import 'package:admin_app/features/analytics/analytics_screen.dart';
import 'package:admin_app/features/auth/admin_login_screen.dart';
import 'package:admin_app/features/bookings/admin_booking_detail_screen.dart';
import 'package:admin_app/features/bookings/admin_bookings_screen.dart';
import 'package:admin_app/features/customers/customers_screen.dart';
import 'package:admin_app/features/drivers/driver_detail_screen.dart';
import 'package:admin_app/features/drivers/drivers_screen.dart';
import 'package:admin_app/features/overview/overview_screen.dart';
import 'package:admin_app/features/pricing/pricing_screen.dart';
import 'package:admin_app/features/serviceable_areas/serviceable_areas_screen.dart';
import 'package:admin_app/features/shell/admin_shell.dart';
import 'package:admin_app/features/splash/splash_screen.dart';
import 'package:admin_app/features/support/admin_support_chat_screen.dart';
import 'package:admin_app/features/support/admin_support_screen.dart';
import 'package:admin_app/session/admin_session_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'adminRoot');
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'adminShell');

final adminRouterProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(adminSessionControllerProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AdminRoutes.splash,
    redirect: (context, state) {
      final isSplash = state.uri.path == AdminRoutes.splash;
      final isLogin = state.uri.path == AdminRoutes.login;

      if (session.status == AdminSessionStatus.unknown) {
        return isSplash ? null : AdminRoutes.splash;
      }

      if (!session.isAuthenticated) {
        return isLogin ? null : AdminRoutes.login;
      }

      if (isLogin || isSplash) {
        return AdminRoutes.overview;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AdminRoutes.splash,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AdminRoutes.login,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AdminLoginScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: AdminRoutes.overview,
            builder: (context, state) => const OverviewScreen(),
          ),
          GoRoute(
            path: AdminRoutes.drivers,
            builder: (context, state) => const DriversScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id'] ?? '';
                  return DriverDetailScreen(driverId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: AdminRoutes.bookings,
            builder: (context, state) => const AdminBookingsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id'] ?? '';
                  return AdminBookingDetailScreen(bookingId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: AdminRoutes.customers,
            builder: (context, state) => const CustomersScreen(),
          ),
          GoRoute(
            path: AdminRoutes.pricing,
            builder: (context, state) => const PricingScreen(),
          ),
          GoRoute(
            path: AdminRoutes.serviceableAreas,
            builder: (context, state) => const ServiceableAreasScreen(),
          ),
          GoRoute(
            path: AdminRoutes.analytics,
            builder: (context, state) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: AdminRoutes.support,
            builder: (context, state) => const AdminSupportScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id'] ?? '';
                  return AdminSupportChatScreen(ticketId: id);
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
