import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/live_coaching_service.dart';
import '../data/location_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/constants/api_constants.dart';

class LiveRunScreen extends ConsumerStatefulWidget {
  final String targetDistance;
  final double targetPaceSeconds;
  final bool isGhostRacing;
  final String strictness;

  const LiveRunScreen({
    super.key,
    this.targetDistance = '5K',
    this.targetPaceSeconds = 360.0,
    this.isGhostRacing = false,
    this.strictness = 'Standard',
  });

  @override
  ConsumerState<LiveRunScreen> createState() => _LiveRunScreenState();
}

class _LiveRunScreenState extends ConsumerState<LiveRunScreen> {
  bool _isPaused = false;

  String get _formattedTargetPace {
    final minutes = (widget.targetPaceSeconds / 60).floor();
    final seconds = (widget.targetPaceSeconds % 60).floor().toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _formatElapsedTime(int totalSeconds) {
    final minutes = (totalSeconds / 60).floor().toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _formatPace(double paceSeconds) {
    if (paceSeconds <= 0) return '--:--';
    final minutes = (paceSeconds / 60).floor();
    final seconds = (paceSeconds % 60).floor().toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(liveCoachingProvider);
    final notifier = ref.read(liveCoachingProvider.notifier);
    final locationState = ref.watch(locationProvider);
    final locationNotifier = ref.read(locationProvider.notifier);

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
                      locationNotifier.stopTracking();
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
                state.isRunning ? locationState.totalDistanceKm.toStringAsFixed(2) : '0.00',
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
                state.isRunning ? _formatElapsedTime(locationState.elapsedSeconds) : '00:00',
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
                  _buildMetric('PACE', state.isRunning ? _formatPace(locationState.currentPaceSecondsPerKm) : _formattedTargetPace, '/KM'),
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
                FloatingActionButton.large(
                  onPressed: () {
                    setState(() { _isPaused = false; });
                    // Pass isGhostRace from extra
                    notifier.startRun(
                      isGhostRace: widget.isGhostRacing,
                      distance: widget.targetDistance,
                      paceSeconds: widget.targetPaceSeconds,
                      strictness: widget.strictness,
                    );
                    locationNotifier.startTracking();
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
                      onPressed: () async {
                        setState(() { _isPaused = false; });
                        notifier.stopRun();
                        locationNotifier.stopTracking();

                        // Save run session
                        final session = Supabase.instance.client.auth.currentSession;
                        final token = session?.accessToken;
                        if (token != null) {
                          try {
                            final url = Uri.parse('${ApiConstants.baseUrl}/training/session/save');
                            await http.post(url, 
                              headers: {
                                'Authorization': 'Bearer $token',
                                'Content-Type': 'application/json'
                              },
                              body: jsonEncode({
                                'totalTimeSecs': locationState.elapsedSeconds,
                                'distanceMeters': locationState.totalDistanceKm * 1000,
                              })
                            );
                          } catch (e) {
                            print('Error saving run session: $e');
                          }
                        }

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
