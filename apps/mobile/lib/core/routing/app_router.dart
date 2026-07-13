import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/run/presentation/live_run_screen.dart';
import '../../features/run/presentation/post_run_analytics_screen.dart';
import '../../features/training/presentation/training_adjust_chat_screen.dart';
import '../../features/training/presentation/training_plan_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/data/auth_service.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isAuth = authState.value?.session != null;
      final isLoggingIn = state.uri.toString() == '/login';

      if (!isAuth && !isLoggingIn) return '/login';
      if (isAuth && isLoggingIn) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
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
          final isBaseline = extra['isBaseline'] as bool? ?? false;
          
          return LiveRunScreen(
            targetDistance: targetDistance,
            targetPaceSeconds: targetPaceSeconds,
            isGhostRacing: isGhostRacing,
            strictness: strictness,
            isBaseline: isBaseline,
          );
        },
      ),
      GoRoute(
        path: '/analytics',
        builder: (context, state) {
          String geoJsonData = "{}";
          double distance = 0.0;
          bool isHistoryView = false;
          if (state.extra is String) {
            geoJsonData = state.extra as String;
          } else if (state.extra is Map) {
            final map = state.extra as Map;
            geoJsonData = map['geoJsonData'] ?? "{}";
            distance = map['distance'] ?? 0.0;
            isHistoryView = map['isHistoryView'] ?? false;
          }
          return PostRunAnalyticsScreen(
            geoJsonData: geoJsonData,
            distanceMeters: distance,
            isHistoryView: isHistoryView,
          );
        },
      ),
      GoRoute(
        path: '/training',
        builder: (context, state) {
          String goal = "Sub-20 5K";
          String? planId;
          if (state.extra is String) {
            goal = state.extra as String;
          } else if (state.extra is Map) {
            final map = state.extra as Map;
            goal = map['goal'] ?? "Sub-20 5K";
            planId = map['planId'];
          }
          return TrainingPlanScreen(goal: goal, planId: planId);
        },
      ),
      GoRoute(
        path: '/training/chat',
        builder: (context, state) => const TrainingAdjustChatScreen(),
      ),
    ],
  );
});
