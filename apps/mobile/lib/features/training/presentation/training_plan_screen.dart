import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/training_service.dart';
import '../domain/training_workout.dart';
import '../data/saved_plan_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/neo_brutalist_container.dart';
import '../../../core/ui/neo_brutalist_button.dart';
import '../../../core/ui/responsive_layout.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TrainingPlanScreen extends ConsumerStatefulWidget {
  final String goal;
  final String? planId;
  const TrainingPlanScreen({super.key, required this.goal, this.planId});

  @override
  ConsumerState<TrainingPlanScreen> createState() => _TrainingPlanScreenState();
}

class _TrainingPlanScreenState extends ConsumerState<TrainingPlanScreen> {
  final TrainingService _service = TrainingService();
  bool _isLoading = true;
  List<TrainingWorkout>? _workouts;
  bool _requiresBaseline = false;
  String _baselineInstruction = '';
  String? _adjustmentNotice;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchTrainingPlan();
  }

  Future<void> _fetchTrainingPlan() async {
    setState(() { _isLoading = true; _errorMessage = ''; });
    final response = await _service.getTrainingPlan(widget.goal);

    setState(() {
      _isLoading = false;
      if (response.errorMessage != null) {
        _errorMessage = response.errorMessage!;
      } else if (response.requiresBaseline) {
        _requiresBaseline = true;
        _baselineInstruction = response.baselineInstruction ?? 'Run at a conversational pace (RPE 3-4).';
      } else {
        _workouts = response.plan;
        _adjustmentNotice = response.adjustmentNotice;
        ref.invalidate(savedPlansProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _buildMobileScaffold(context),
      desktop: _buildDesktopScaffold(context),
    );
  }

  Widget _buildMobileScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E10),
      body: SafeArea(
        child: Column(
          children: [
            _buildMobileHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildContent(isDesktop: false),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildDesktopScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E10),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildDesktopSidebar(),
          Expanded(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildDesktopHeader(context),
                      const SizedBox(height: 32),
                      _buildContent(isDesktop: true),
                    ],
                  ),
                ),
              ),
              floatingActionButton: _buildFab(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF18181C),
        border: Border(bottom: BorderSide(color: Colors.black, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => context.go('/dashboard'),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF26262B),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: const Icon(Icons.chevron_left, color: Colors.white, size: 16),
                ),
              ),
              const Text(
                'WEEK 3 OF 8',
                style: TextStyle(
                  color: Color(0xFFFC4C02),
                  fontFamily: 'Unbounded',
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 28),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.goal.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Unbounded',
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'WEEK 3 OF 8',
              style: TextStyle(
                color: Color(0xFFFC4C02),
                fontFamily: 'Unbounded',
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.goal.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Unbounded',
                fontWeight: FontWeight.w900,
                fontSize: 32,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopSidebar() {
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
          _buildSidebarItem(Icons.crop_square, 'DASHBOARD', '/dashboard', false),
          const SizedBox(height: 16),
          _buildSidebarItem(Icons.crop_square, 'PLAN', '/dashboard', true),
          const SizedBox(height: 16),
          _buildSidebarItem(Icons.circle, 'LIVE RUN', '/dashboard', false, iconSize: 10),
          const SizedBox(height: 16),
          _buildSidebarItem(Icons.circle, 'ANALYTICS', '/dashboard', false, iconSize: 10),
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
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                color: Colors.grey[800],
                child: const Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ALEX RUNS', style: TextStyle(color: Colors.white, fontFamily: 'Unbounded', fontWeight: FontWeight.w800, fontSize: 12)),
                  SizedBox(height: 2),
                  Text('Premium Member', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 11, fontFamily: 'Geist')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String label, String route, bool isSelected, {double iconSize = 18}) {
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

  Widget _buildBottomNav() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF18181C),
        border: Border(top: BorderSide(color: Colors.black, width: 3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomNavItem(Icons.home_filled, 'Home', false, '/dashboard'),
          _buildBottomNavItem(Icons.calendar_today, 'Plan', true, '/dashboard'),
          _buildBottomNavItem(Icons.history, 'Activity', false, '/dashboard'),
          _buildBottomNavItem(Icons.person, 'Profile', false, '/dashboard'),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, bool isSelected, String route) {
    return GestureDetector(
      onTap: () {
        if (!isSelected) context.go(route);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? Colors.white : const Color(0xFF8E8E93), size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF8E8E93),
              fontFamily: 'Geist',
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent({required bool isDesktop}) {
    if (_isLoading) return _buildLoadingState();
    if (_errorMessage.isNotEmpty) return Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)));
    if (_requiresBaseline) return _buildBaselineState();
    if (_workouts == null || _workouts!.isEmpty) return const Center(child: Text('No plan available.', style: TextStyle(color: Colors.grey)));

    if (isDesktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('WEEKLY WORKOUT SCHEDULE', style: TextStyle(color: Colors.white, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          if (_workouts!.length >= 3)
            Row(
              children: [
                Expanded(child: _buildDayCard(_workouts![0], isDesktop)),
                const SizedBox(width: 16),
                Expanded(child: _buildDayCard(_workouts![1], isDesktop)),
                const SizedBox(width: 16),
                Expanded(child: _buildDayCard(_workouts![2], isDesktop)),
              ],
            ),
          const SizedBox(height: 16),
          if (_workouts!.length >= 7)
            Row(
              children: [
                Expanded(child: _buildDayCard(_workouts![3], isDesktop)),
                const SizedBox(width: 16),
                Expanded(child: _buildDayCard(_workouts![4], isDesktop)),
                const SizedBox(width: 16),
                Expanded(child: _buildDayCard(_workouts![5], isDesktop)),
                const SizedBox(width: 16),
                Expanded(child: _buildDayCard(_workouts![6], isDesktop)),
              ],
            ),
        ],
      );
    } else {
      return Column(
        children: _workouts!.map((w) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildDayCard(w, isDesktop),
        )).toList(),
      );
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          CircularProgressIndicator(color: Color(0xFFCCFF00)),
          SizedBox(height: 16),
          Text('Loading Plan...', style: TextStyle(color: Colors.white, fontFamily: 'Unbounded')),
        ],
      ),
    );
  }

  Widget _buildBaselineState() {
    return Center(
      child: Text('Baseline test required.', style: TextStyle(color: Colors.white)),
    );
  }

  Widget _buildDayCard(TrainingWorkout workout, bool isDesktop) {
    Color tagColor;
    Color bgColor = const Color(0xFF111113);
    Color tagTextColor = Colors.white;
    bool isToday = workout.day.toLowerCase() == 'wed'; // Dummy logic for today
    bool isCompleted = workout.day.toLowerCase() == 'mon' || workout.day.toLowerCase() == 'tue';
    
    switch (workout.type.toLowerCase()) {
      case 'easy':
      case 'easy run':
        tagColor = Colors.transparent;
        tagTextColor = const Color(0xFF8E8E93);
        break;
      case 'interval':
      case 'speed work':
        tagColor = const Color(0xFFCCFF00);
        tagTextColor = Colors.black;
        if (isToday) bgColor = const Color(0xFF26262B);
        break;
      case 'long':
      case 'long run':
        tagColor = const Color(0xFF9B51E0);
        break;
      case 'tempo':
        tagColor = const Color(0xFF2D9CDB);
        break;
      case 'rest':
        tagColor = Colors.transparent;
        tagTextColor = const Color(0xFF8E8E93);
        break;
      default:
        tagColor = Colors.transparent;
        tagTextColor = const Color(0xFF8E8E93);
    }

    return Container(
      padding: EdgeInsets.all(isDesktop ? 16 : 14),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: [BoxShadow(color: isToday ? const Color(0xFFFC4C02) : Colors.black, offset: const Offset(4, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(workout.day.toUpperCase(), style: TextStyle(color: isToday ? const Color(0xFFFC4C02) : Colors.white, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 15)),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: tagColor,
                      border: Border.all(color: tagColor == Colors.transparent ? Colors.black : Colors.black, width: 1.5),
                    ),
                    child: Text(
                      workout.type.toUpperCase(),
                      style: TextStyle(color: tagTextColor, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 9),
                    ),
                  ),
                ],
              ),
              if (isCompleted)
                Row(
                  children: const [
                    Icon(Icons.check_circle, color: Color(0xFFCCFF00), size: 16),
                    SizedBox(width: 4),
                    Text('DONE', style: TextStyle(color: Color(0xFFCCFF00), fontFamily: 'Geist', fontWeight: FontWeight.bold, fontSize: 11)),
                  ],
                ),
              if (isToday && !isDesktop)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCCFF00),
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                  child: const Text('TODAY', style: TextStyle(color: Colors.black, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 9)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (workout.type.toLowerCase() != 'rest') ...[
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                const Text('45 min', style: TextStyle(color: Colors.white, fontFamily: 'Geist', fontSize: 13)), // Dummy metric
                const SizedBox(width: 16),
                const Icon(Icons.speed, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                const Text('Pace: 5:30/km', style: TextStyle(color: Colors.white, fontFamily: 'Geist', fontSize: 13)), // Dummy metric
              ],
            ),
            const SizedBox(height: 10),
          ],
          Text(
            workout.description,
            style: const TextStyle(color: Color(0xFF8E8E93), fontFamily: 'Geist', fontSize: 13, height: 1.4),
          ),
          if (isToday) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                context.push('/run', extra: {
                  'targetDistance': 'Custom',
                  'targetPaceSeconds': 300.0,
                  'isGhostRacing': false,
                  'strictness': 'Standard',
                  'isBaseline': false,
                });
              },
              child: Container(
                height: isDesktop ? 36 : 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFCCFF00),
                  border: Border.all(color: Colors.black, width: 2),
                  boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
                ),
                child: Text('START WORKOUT', style: TextStyle(color: Colors.black, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: isDesktop ? 11 : 12)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget? _buildFab() {
    if (widget.planId != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: FloatingActionButton.extended(
          onPressed: _setActivePlan,
          backgroundColor: const Color(0xFFCCFF00),
          icon: const Icon(Icons.check_circle_outline, color: Colors.black),
          label: const Text('SET AS ACTIVE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontFamily: 'Unbounded')),
        ),
      );
    }
    return null;
  }

  void _setActivePlan() async {
    if (widget.planId == null) return;
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF4A90E2))),
      );
      final service = ref.read(savedPlanServiceProvider);
      await service.setActivePlan(widget.planId!);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Switched to ${widget.goal}', style: const TextStyle(color: Colors.white))),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to switch plan', style: TextStyle(color: Colors.white))),
        );
      }
    }
  }
}
