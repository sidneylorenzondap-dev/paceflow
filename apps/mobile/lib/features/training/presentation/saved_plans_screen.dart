import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../data/saved_plan_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/neo_brutalist_container.dart';
import '../../../core/ui/responsive_layout.dart';

class SavedPlansScreen extends ConsumerWidget {
  const SavedPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(savedPlansProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E10),
      body: SafeArea(
        child: ResponsiveLayout(
          mobile: _buildMobileContent(context, ref, plansAsync),
          desktop: _buildDesktopContent(context, ref, plansAsync),
        ),
      ),
    );
  }

  // --- MOBILE LAYOUT ---

  Widget _buildMobileContent(BuildContext context, WidgetRef ref, AsyncValue<List<dynamic>> plansAsync) {
    return Column(
      children: [
        _buildMobileHeader(context),
        Expanded(
          child: _buildListOrGrid(context, ref, plansAsync, isMobile: true),
        ),
      ],
    );
  }

  Widget _buildMobileHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF18181C),
        border: Border(bottom: BorderSide(color: Colors.black, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => context.go('/dashboard'),
            child: Row(
              children: [
                const Icon(Icons.chevron_left, color: Color(0xFFFC4C02), size: 24),
                const SizedBox(width: 4),
                const Text(
                  'DASHBOARD',
                  style: TextStyle(color: Color(0xFFFC4C02), fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 12),
                ),
              ],
            ),
          ),
          const Text(
            'SAVED AI PLANS',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Unbounded',
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // --- DESKTOP LAYOUT ---

  Widget _buildDesktopContent(BuildContext context, WidgetRef ref, AsyncValue<List<dynamic>> plansAsync) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDesktopSidebar(context),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildDesktopHeader(context),
                const SizedBox(height: 32),
                Expanded(
                  child: _buildListOrGrid(context, ref, plansAsync, isMobile: false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopSidebar(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF18181C),
        border: Border(right: BorderSide(color: Colors.black, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFCCFF00),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: const Text('PF', style: TextStyle(color: Colors.black, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 16)),
              ),
              const SizedBox(width: 8),
              const Text('PACEFLOW', style: TextStyle(color: Colors.white, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 20)),
            ],
          ),
          const SizedBox(height: 48),
          _buildDesktopSidebarItem(context, Icons.crop_square, 'DASHBOARD', '/dashboard', true),
          const SizedBox(height: 16),
          _buildDesktopSidebarItem(context, Icons.crop_square, 'PLAN', '/dashboard', false),
          const SizedBox(height: 16),
          _buildDesktopSidebarItem(context, Icons.circle, 'LIVE RUN', '/dashboard', false, iconSize: 10),
          const SizedBox(height: 16),
          _buildDesktopSidebarItem(context, Icons.circle, 'ANALYTICS', '/dashboard', false, iconSize: 10),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFC4C02),
              border: Border.all(color: Colors.black, width: 3),
              boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PACEFLOW PREMIUM', style: TextStyle(color: Colors.white, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 12)),
                SizedBox(height: 12),
                Text('Unlock advanced AI metrics, live ghost pacing & audio recovery engine.', style: TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'Geist')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSidebarItem(BuildContext context, IconData icon, String label, String route, bool isSelected, {double iconSize = 18}) {
    return GestureDetector(
      onTap: () {
        if (!isSelected) context.go(route);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFCCFF00) : Colors.transparent,
          border: isSelected ? Border.all(color: Colors.black, width: 2) : Border.all(color: Colors.transparent, width: 2),
          boxShadow: isSelected ? const [BoxShadow(color: Colors.black, offset: Offset(4, 4))] : [],
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.black : const Color(0xFF8E8E93), size: iconSize),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : const Color(0xFF8E8E93),
                fontFamily: 'Unbounded',
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopHeader(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.go('/dashboard'),
          child: const Text(
            '< DASHBOARD',
            style: TextStyle(color: Color(0xFFFC4C02), fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 14),
          ),
        ),
        const SizedBox(width: 24),
        const Text(
          'SAVED AI PLANS',
          style: TextStyle(color: Colors.white, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 24),
        ),
      ],
    );
  }

  // --- CONTENT BUILDER ---

  Widget _buildListOrGrid(BuildContext context, WidgetRef ref, AsyncValue<List<dynamic>> plansAsync, {required bool isMobile}) {
    return plansAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFCCFF00))),
      error: (error, stack) => Center(
        child: Text('Error loading plans: $error', style: const TextStyle(color: Colors.red, fontFamily: 'Geist')),
      ),
      data: (plans) {
        if (plans.isEmpty) {
          return _buildEmptyState(isMobile);
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(savedPlansProvider);
          },
          color: const Color(0xFFCCFF00),
          backgroundColor: const Color(0xFF18181C),
          child: isMobile 
            ? ListView.separated(
                padding: const EdgeInsets.all(20.0),
                itemCount: plans.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) => _buildPlanCard(context, plans[index]),
              )
            : GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 500,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                ),
                itemCount: plans.length,
                itemBuilder: (context, index) => _buildPlanCard(context, plans[index]),
              ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isMobile) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF18181C),
          border: Border.all(color: Colors.black, width: 3),
          boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(8, 8))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, size: 48, color: Color(0xFFCCFF00)),
            const SizedBox(height: 24),
            Text(
              'NO SAVED PLANS YET',
              style: TextStyle(
                fontSize: isMobile ? 18 : 24,
                fontFamily: 'Unbounded',
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Generate an AI Training Plan from the Home dashboard to see it here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF8E8E93), fontFamily: 'Geist', fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, dynamic plan) {
    return GestureDetector(
      onTap: () {
        context.push('/training', extra: {
          'goal': plan.goal,
          'planId': plan.id,
        });
      },
      child: NeoBrutalistContainer(
        backgroundColor: Colors.white,
        shadowColor: Colors.black,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CREATED ${DateFormat('MMM d, yyyy').format(plan.createdAt).toUpperCase()}',
                  style: const TextStyle(
                    color: Color(0xFF8E8E93),
                    fontFamily: 'Unbounded',
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 1.0,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9B51E0),
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                  child: const Text(
                    'AI PLAN',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Unbounded',
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    plan.goal.toUpperCase(),
                    style: const TextStyle(color: Colors.black, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 24),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF18181C),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
