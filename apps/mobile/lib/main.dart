import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://jjxwczjynvjvkgjcyiyo.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpqeHdjemp5bnZqdmtnamN5aXlvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEyMTA2NzAsImV4cCI6MjA5Njc4NjY3MH0.z13h_ajz031a_BVX7ZTpZIb55QTUS0ys_93P74i_SAQ',
  );

  runApp(const ProviderScope(child: PaceFlowApp()));
}

class PaceFlowApp extends ConsumerWidget {
  const PaceFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'PaceFlow',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
