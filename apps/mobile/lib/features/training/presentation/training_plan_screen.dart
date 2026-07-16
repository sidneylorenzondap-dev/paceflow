import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/training_service.dart';
import '../domain/training_workout.dart';
import '../data/saved_plan_service.dart';

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
        ref.invalidate(savedPlansProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('AI Training Plan', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildContent(),
        ),
      ),
      floatingActionButton: (_workouts != null && _workouts!.isNotEmpty)
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (widget.planId != null) ...[
                  FloatingActionButton.extended(
                    heroTag: 'set_active',
                    onPressed: _setActivePlan,
                    backgroundColor: const Color(0xFF4A90E2),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Set as Active', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  const SizedBox(height: 16),
                ],
                FloatingActionButton.extended(
                  heroTag: 'adjust_plan',
                  onPressed: () {
                    context.push('/training/chat');
                  },
                  backgroundColor: const Color(0xFFFC4C02),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Adjust Plan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            )
          : null,
    );
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

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFC4C02).withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFC4C02).withOpacity(0.1),
                blurRadius: 32,
                spreadRadius: 8,
              ),
            ],
          ),
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
                      color: Color(0xFFFC4C02),
                      strokeWidth: 2,
                    ),
                  ),
                  Icon(
                    Icons.auto_awesome,
                    color: const Color(0xFFFC4C02).withOpacity(0.8),
                    size: 32,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text(
                'Crafting Your Plan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Analyzing your history and\ncalibrating AI targets...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

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

    return ListView.builder(
      itemCount: _workouts!.length,
      itemBuilder: (context, index) {
        final workout = _workouts![index];
        return _buildWorkoutCard(workout);
      },
    );
  }

  Widget _buildBaselineState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFC4C02).withOpacity(0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.directions_run, color: Color(0xFFFC4C02), size: 64),
            const SizedBox(height: 16),
            const Text(
              'Baseline Test Required',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'We need to understand your current fitness level before generating a plan for ${widget.goal}.',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(12)),
              child: Text(
                _baselineInstruction,
                style: const TextStyle(color: Colors.white, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFC4C02),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('Start Baseline Run', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: typeColor, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                workout.day,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(typeIcon, color: typeColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      workout.type,
                      style: TextStyle(color: typeColor, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            workout.description,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
