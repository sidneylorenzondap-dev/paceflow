import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/live_coaching_service.dart';
import '../data/location_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/neo_brutalist_container.dart';
import '../../../core/ui/neo_brutalist_button.dart';
import '../../../core/ui/responsive_layout.dart';

class LiveRunScreen extends ConsumerStatefulWidget {
  final String targetDistance;
  final double targetPaceSeconds;
  final bool isGhostRacing;
  final String strictness;
  final bool isBaseline;
  final String? pendingPlanGoal;

  const LiveRunScreen({
    super.key,
    this.targetDistance = '5K',
    this.targetPaceSeconds = 360.0,
    this.isGhostRacing = false,
    this.strictness = 'Standard',
    this.isBaseline = false,
    this.pendingPlanGoal,
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
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: ResponsiveLayout(
          mobile: _buildMobileContent(state, notifier, locationState, locationNotifier),
          desktop: _buildDesktopContent(state, notifier, locationState, locationNotifier),
        ),
      ),
    );
  }

  Widget _buildTopBar(dynamic state, dynamic notifier, dynamic locationNotifier) {
    return Row(
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
        NeoBrutalistContainer(
          backgroundColor: widget.isBaseline 
              ? Colors.deepPurple 
              : (state.isRunning ? AppTheme.primaryColor : Colors.grey[800]!),
          shadowColor: Colors.black,
          borderWidth: 2,
          shadowOffset: 2,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Icon(
                widget.isBaseline 
                    ? Icons.biotech 
                    : (state.isRunning ? Icons.satellite_alt_rounded : Icons.satellite_alt_outlined), 
                size: 14, 
                color: widget.isBaseline || state.isRunning ? Colors.black : Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                widget.isBaseline 
                    ? 'BASELINE TEST' 
                    : (state.isRunning ? 'GPS ACTIVE' : 'GPS STANDBY'),
                style: TextStyle(
                  color: widget.isBaseline || state.isRunning ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Unbounded',
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileContent(dynamic state, dynamic notifier, dynamic locationState, dynamic locationNotifier) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          _buildTopBar(state, notifier, locationNotifier),
              
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
                  color: AppTheme.secondaryTextColor,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Unbounded',
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                state.isRunning ? _formatElapsedTime(locationState.elapsedSeconds) : '00:00',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontSize: 48,
                  letterSpacing: -1,
                  color: AppTheme.primaryColor,
                ),
              ),
              const Text(
                'ELAPSED TIME',
                style: TextStyle(
                  color: AppTheme.secondaryTextColor,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Unbounded',
                  fontSize: 12,
                ),
              ),
              
              const SizedBox(height: 16),
              if (widget.isBaseline)
                NeoBrutalistContainer(
                  backgroundColor: Colors.deepPurple,
                  shadowColor: Colors.black,
                  padding: const EdgeInsets.all(16),
                  child: const Text(
                    'Run comfortably but at a steady, pushing pace. The AI will use this to calibrate your 100% effort baseline.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 13, fontStyle: FontStyle.italic, fontFamily: 'Geist'),
                  ),
                ),
              if (!widget.isBaseline) const SizedBox(height: 32),
              
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
                NeoBrutalistContainer(
                  backgroundColor: AppTheme.accentColor,
                  shadowColor: Colors.black,
                  borderWidth: 2,
                  shadowOffset: 4,
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.graphic_eq_rounded,
                        color: Colors.black,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          state.latestCue!.text,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Geist',
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                const SizedBox(height: 104), // Space placeholder
              
              if (!state.isRunning)
                _buildControls(state, notifier, locationState, locationNotifier)
              else if (!_isPaused)
                _buildControls(state, notifier, locationState, locationNotifier)
              else
                _buildControls(state, notifier, locationState, locationNotifier),
              const SizedBox(height: 16),
            ],
          ),
        );
  }

  Widget _buildDesktopContent(dynamic state, dynamic notifier, dynamic locationState, dynamic locationNotifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 64.0, vertical: 32.0),
      child: Column(
        children: [
          _buildTopBar(state, notifier, locationNotifier),
          const SizedBox(height: 64),
          Expanded(
            child: Row(
              children: [
                // Left Pane: Big Timer & Distance
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.isRunning ? locationState.totalDistanceKm.toStringAsFixed(2) : '0.00',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontSize: 120,
                          letterSpacing: -2,
                        ),
                      ),
                      const Text(
                        'KILOMETERS',
                        style: TextStyle(
                          color: AppTheme.secondaryTextColor,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Unbounded',
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 48),
                      Text(
                        state.isRunning ? _formatElapsedTime(locationState.elapsedSeconds) : '00:00',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontSize: 80,
                          letterSpacing: -1,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const Text(
                        'ELAPSED TIME',
                        style: TextStyle(
                          color: AppTheme.secondaryTextColor,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Unbounded',
                          fontSize: 16,
                        ),
                      ),
                      if (widget.isBaseline) ...[
                        const SizedBox(height: 32),
                        NeoBrutalistContainer(
                          backgroundColor: Colors.deepPurple,
                          shadowColor: Colors.black,
                          padding: const EdgeInsets.all(16),
                          child: const Text(
                            'Run comfortably but at a steady, pushing pace. The AI will use this to calibrate your 100% effort baseline.',
                            style: TextStyle(color: Colors.white, fontSize: 14, fontStyle: FontStyle.italic, fontFamily: 'Geist'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Right Pane: Metrics, Cue, Controls
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildMetric('HR', '${state.telemetry.heartRate}', 'BPM'),
                          _buildMetric('PACE', state.isRunning ? _formatPace(locationState.currentPaceSecondsPerKm) : _formattedTargetPace, '/KM'),
                          _buildMetric('CAD', '${state.telemetry.cadence}', 'SPM'),
                        ],
                      ),
                      const SizedBox(height: 64),
                      if (state.latestCue != null) ...[
                        NeoBrutalistContainer(
                          backgroundColor: AppTheme.accentColor,
                          shadowColor: Colors.black,
                          borderWidth: 2,
                          shadowOffset: 4,
                          padding: const EdgeInsets.all(24),
                          child: Row(
                            children: [
                              const Icon(Icons.graphic_eq_rounded, color: Colors.black, size: 40),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  state.latestCue!.text,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'Geist',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 64),
                      ],
                      _buildControls(state, notifier, locationState, locationNotifier),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(dynamic state, dynamic notifier, dynamic locationState, dynamic locationNotifier) {
    if (!state.isRunning) {
      return SizedBox(
        width: double.infinity,
        child: NeoBrutalistButton(
          onPressed: () {
            setState(() { _isPaused = false; });
            notifier.startRun(
              isGhostRace: widget.isGhostRacing,
              distance: widget.targetDistance,
              paceSeconds: widget.targetPaceSeconds,
              strictness: widget.strictness,
            );
            locationNotifier.startTracking();
          },
          backgroundColor: AppTheme.primaryColor,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'START RUN',
              style: TextStyle(fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 20, color: Colors.black, letterSpacing: 1.5),
            ),
          ),
        ),
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: NeoBrutalistButton(
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
                        'totalTimeSecs': widget.isBaseline ? 8400 : locationState.elapsedSeconds,
                        'distanceMeters': widget.isBaseline ? 20000 : locationState.totalDistanceKm * 1000,
                        'isBaseline': widget.isBaseline,
                      })
                    );
                  } catch (e) {
                    debugPrint('Error saving run session: $e');
                  }
                }

                if (widget.isBaseline) {
                  if (context.mounted) {
                    context.push('/analytics', extra: {
                      'isBaseline': true,
                      'pendingPlanGoal': widget.pendingPlanGoal
                    });
                  }
                } else {
                  if (context.mounted) {
                    context.push('/analytics');
                  }
                }
              },
              backgroundColor: AppTheme.accentColor,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.stop_rounded, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'STOP',
                      style: TextStyle(fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white, letterSpacing: 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: NeoBrutalistButton(
              onPressed: () {
                setState(() { _isPaused = !_isPaused; });
              },
              backgroundColor: AppTheme.primaryColor,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded, color: Colors.black),
                    const SizedBox(width: 8),
                    Text(
                      _isPaused ? 'RESUME' : 'PAUSE',
                      style: const TextStyle(fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black, letterSpacing: 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }
  }



  Widget _buildMetric(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            fontSize: 28,
          ),
        ),
        Text(
          '$label ($unit)',
          style: const TextStyle(
            color: AppTheme.secondaryTextColor,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            fontFamily: 'Unbounded',
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
