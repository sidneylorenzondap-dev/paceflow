import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/run/presentation/live_run_screen.dart';
import '../../features/run/presentation/post_run_analytics_screen.dart';
import '../../features/training/presentation/training_adjust_chat_screen.dart';
import '../../features/training/presentation/training_plan_screen.dart';

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
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final targetDistance = extra['distance'] as String? ?? '5K';
          final targetPaceSeconds = extra['paceSeconds'] as double? ?? 360.0;
          final isGhostRacing = extra['isGhostRacing'] as bool? ?? false;
          final strictness = extra['strictness'] as String? ?? 'Standard';
          
          return LiveRunScreen(
            targetDistance: targetDistance,
            targetPaceSeconds: targetPaceSeconds,
            isGhostRacing: isGhostRacing,
            strictness: strictness,
          );
        },
      ),
      GoRoute(
        path: '/analytics',
        builder: (context, state) {
          final geoJsonData = state.extra as String? ?? "{}";
          return PostRunAnalyticsScreen(geoJsonData: geoJsonData);
        },
      ),
      GoRoute(
        path: '/training',
        builder: (context, state) {
          final goal = state.extra as String? ?? "Sub-20 5K";
          return TrainingPlanScreen(goal: goal);
        },
      ),
      GoRoute(
        path: '/training/chat',
        builder: (context, state) => const TrainingAdjustChatScreen(),
      ),
    ],
  );
});
