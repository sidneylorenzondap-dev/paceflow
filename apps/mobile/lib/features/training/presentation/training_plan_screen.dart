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
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('AI TRAINING PLAN', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildContent(),
        ),
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildDesktopScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('AI TRAINING PLAN (DESKTOP)', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 64.0, vertical: 32.0),
          child: _buildDesktopContent(),
        ),
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget? _buildFab() {
    if (_workouts != null && _workouts!.isNotEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (widget.planId != null) ...[
            NeoBrutalistButton(
              onPressed: _setActivePlan,
              backgroundColor: AppTheme.primaryColor,
              shadowColor: Colors.black,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.check_circle_outline, color: Colors.black, size: 20),
                    SizedBox(width: 8),
                    Text('SET AS ACTIVE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          NeoBrutalistButton(
            onPressed: () => context.push('/training/chat'),
            backgroundColor: AppTheme.accentColor,
            shadowColor: Colors.black,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.chat_bubble_outline, color: Colors.black, size: 20),
                  SizedBox(width: 8),
                  Text('ADJUST PLAN', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ),
        ],
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

  Widget _buildDesktopContent() {
    if (_isLoading) return _buildLoadingState();
    if (_errorMessage.isNotEmpty) return Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)));
    if (_requiresBaseline) return _buildBaselineState();
    if (_workouts == null || _workouts!.isEmpty) return const Center(child: Text('No plan available.', style: TextStyle(color: Colors.grey)));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_adjustmentNotice != null && _adjustmentNotice!.isNotEmpty) ...[
          Expanded(
            flex: 1,
            child: NeoBrutalistContainer(
              backgroundColor: AppTheme.primaryColor,
              shadowColor: Colors.black,
              borderWidth: 2,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.psychology, color: Colors.black, size: 28),
                      const SizedBox(width: 12),
                      const Text('AI COACH NOTE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16, fontFamily: 'Unbounded')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _adjustmentNotice!,
                    style: const TextStyle(color: Colors.black87, fontSize: 14, height: 1.5, fontFamily: 'Geist', fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 32),
        ],
        Expanded(
          flex: _adjustmentNotice != null && _adjustmentNotice!.isNotEmpty ? 2 : 1,
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: _workouts!.map((workout) => SizedBox(
                width: 300,
                child: _buildWorkoutCard(workout),
              )).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: NeoBrutalistContainer(
        backgroundColor: AppTheme.surfaceColor,
        shadowColor: AppTheme.accentColor,
        borderWidth: 3,
        shadowOffset: 6,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                const SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                    strokeWidth: 4,
                  ),
                ),
                Icon(
                  Icons.auto_awesome,
                  color: AppTheme.primaryColor,
                  size: 32,
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'CRAFTING PLAN',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 12),
            const Text(
              'Analyzing history...\nCalibrating targets...',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.secondaryTextColor,
                fontFamily: 'Geist',
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) return _buildLoadingState();

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
      );
    }

    if (_requiresBaseline) {
      return _buildBaselineState();
    }

    if (_workouts == null || _workouts!.isEmpty) {
      return const Center(child: Text('No plan available.', style: TextStyle(color: Colors.grey)));
    }

    return Column(
      children: [
        if (_adjustmentNotice != null && _adjustmentNotice!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: NeoBrutalistContainer(
              backgroundColor: AppTheme.primaryColor,
              shadowColor: Colors.black,
              borderWidth: 2,
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.psychology, color: Colors.black, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('AI COACH NOTE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14, fontFamily: 'Unbounded')),
                        const SizedBox(height: 4),
                        Text(
                          _adjustmentNotice!,
                          style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.4, fontFamily: 'Geist', fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: _workouts!.length,
            itemBuilder: (context, index) {
              final workout = _workouts![index];
              return _buildWorkoutCard(workout);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBaselineState() {
    return Center(
      child: NeoBrutalistContainer(
        backgroundColor: AppTheme.surfaceColor,
        shadowColor: AppTheme.accentColor,
        borderWidth: 3,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.directions_run, color: AppTheme.accentColor, size: 64),
            const SizedBox(height: 16),
            Text(
              'BASELINE TEST REQUIRED',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'We need to understand your current fitness level before generating a plan for ${widget.goal}.',
              style: const TextStyle(color: AppTheme.secondaryTextColor, fontSize: 14, fontFamily: 'Geist'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            NeoBrutalistContainer(
              backgroundColor: AppTheme.backgroundColor,
              shadowColor: Colors.transparent,
              borderWidth: 2,
              padding: const EdgeInsets.all(12),
              child: Text(
                _baselineInstruction,
                style: const TextStyle(color: Colors.white, fontStyle: FontStyle.italic, fontFamily: 'Geist'),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            NeoBrutalistButton(
              onPressed: () {
                context.push('/run', extra: {
                  'targetDistance': 'Open',
                  'targetPaceSeconds': 420.0,
                  'isGhostRacing': false,
                  'strictness': 'Standard',
                  'isBaseline': true,
                  'pendingPlanGoal': widget.goal
                });
              },
              backgroundColor: AppTheme.accentColor,
              child: const Text('START BASELINE RUN'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutCard(TrainingWorkout workout) {
    Color typeColor;
    IconData typeIcon;
    switch (workout.type.toLowerCase()) {
      case 'easy':
        typeColor = Colors.blueAccent;
        typeIcon = Icons.spa;
        break;
      case 'interval':
        typeColor = Colors.redAccent;
        typeIcon = Icons.speed;
        break;
      case 'long':
        typeColor = Colors.purpleAccent;
        typeIcon = Icons.map;
        break;
      case 'rest':
        typeColor = Colors.grey;
        typeIcon = Icons.bedtime;
        break;
      default:
        typeColor = Colors.white54;
        typeIcon = Icons.fitness_center;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: NeoBrutalistContainer(
        backgroundColor: AppTheme.surfaceColor,
        shadowColor: typeColor,
        borderWidth: 2,
        shadowOffset: 3,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  workout.day.toUpperCase(),
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 16),
                ),
                const Spacer(),
                NeoBrutalistContainer(
                  backgroundColor: typeColor,
                  shadowColor: Colors.black,
                  shadowOffset: 2,
                  borderWidth: 1.5,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      Icon(typeIcon, color: Colors.black, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        workout.type.toUpperCase(),
                        style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w900, fontFamily: 'Unbounded'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              workout.description,
              style: const TextStyle(color: AppTheme.secondaryTextColor, fontSize: 14, fontFamily: 'Geist'),
            ),
          ],
        ),
      ),
    );
  }
}
