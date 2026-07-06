import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/run/presentation/live_run_screen.dart';
import '../../features/run/presentation/post_run_analytics_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/run',
        builder: (context, state) => const LiveRunScreen(),
      ),
      GoRoute(
        path: '/analytics',
        builder: (context, state) => const PostRunAnalyticsScreen(geoJsonData: "{}"),
      ),
    ],
  );
});
