import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/live_coaching_service.dart';

class LiveRunScreen extends ConsumerStatefulWidget {
  const LiveRunScreen({super.key});

  @override
  ConsumerState<LiveRunScreen> createState() => _LiveRunScreenState();
}

class _LiveRunScreenState extends ConsumerState<LiveRunScreen> {
  bool _isGhostRacing = false;
  bool _isPaused = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(liveCoachingProvider);
    final notifier = ref.read(liveCoachingProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      notifier.stopRun();
                      context.pop();
                    },
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          state.isRunning ? Icons.satellite_alt_rounded : Icons.satellite_alt_outlined, 
                          size: 16, 
                          color: state.isRunning ? Theme.of(context).colorScheme.primary : Colors.grey
                        ),
                        const SizedBox(width: 8),
                        Text(
                          state.isRunning ? 'GPS ACTIVE' : 'GPS STANDBY',
                          style: TextStyle(
                            color: state.isRunning ? Theme.of(context).colorScheme.primary : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const Spacer(),
              
              // Big Timer / Distance
              Text(
                '1.24',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 84,
                  letterSpacing: -2,
                ),
              ),
              const Text(
                'KILOMETERS',
                style: TextStyle(
                  color: Colors.grey,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '06:45',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontSize: 48,
                  letterSpacing: -1,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const Text(
                'ELAPSED TIME',
                style: TextStyle(
                  color: Colors.grey,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 64),
              
              // Metrics Grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMetric('HR', '${state.telemetry.heartRate}', 'BPM'),
                  _buildMetric('PACE', '5:20', '/KM'),
                  _buildMetric('CAD', '${state.telemetry.cadence}', 'SPM'),
                ],
              ),
              
              const Spacer(),
              
              // Coaching Cue Banner
              if (state.latestCue != null)
                Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(bottom: 32),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                    )
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.graphic_eq_rounded,
                        color: Theme.of(context).colorScheme.secondary,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          state.latestCue!.text,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onBackground,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                const SizedBox(height: 104), // Space placeholder
              
              if (!state.isRunning)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.group_outlined, color: Colors.grey),
                    const SizedBox(width: 8),
                    const Text('Race a Ghost', style: TextStyle(color: Colors.white, fontSize: 16)),
                    Switch(
                      value: _isGhostRacing,
                      activeColor: Theme.of(context).colorScheme.primary,
                      onChanged: (val) {
                        setState(() {
                          _isGhostRacing = val;
                        });
                      },
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              if (!state.isRunning)
                FloatingActionButton.large(
                  onPressed: () {
                    setState(() { _isPaused = false; });
                    notifier.startRun(isGhostRace: _isGhostRacing);
                  },
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.black,
                  child: const Icon(Icons.play_arrow_rounded, size: 36),
                )
              else if (!_isPaused)
                FloatingActionButton.large(
                  onPressed: () {
                    setState(() { _isPaused = true; });
                  },
                  backgroundColor: Colors.amber[700],
                  foregroundColor: Colors.black,
                  child: const Icon(Icons.pause_rounded, size: 36),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FloatingActionButton.large(
                      heroTag: 'resume_btn',
                      onPressed: () {
                        setState(() { _isPaused = false; });
                      },
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.black,
                      child: const Icon(Icons.play_arrow_rounded, size: 36),
                    ),
                    const SizedBox(width: 32),
                    FloatingActionButton.large(
                      heroTag: 'stop_btn',
                      onPressed: () {
                        setState(() { _isPaused = false; });
                        notifier.stopRun();
                        context.push('/analytics');
                      },
                      backgroundColor: Colors.red[800],
                      foregroundColor: Colors.white,
                      child: const Icon(Icons.stop_rounded, size: 36),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '$label ($unit)',
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
