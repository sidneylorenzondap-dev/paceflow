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
    if (totalSeconds >= 3600) {
      final hours = (totalSeconds / 3600).floor().toString();
      return '$hours:$minutes:$seconds';
    }
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
      backgroundColor: const Color(0xFF0E0E10),
      body: SafeArea(
        child: ResponsiveLayout(
          mobile: _buildMobileContent(state, notifier, locationState, locationNotifier),
          desktop: _buildDesktopContent(state, notifier, locationState, locationNotifier),
        ),
      ),
    );
  }

  // --- MOBILE LAYOUT ---

  Widget _buildMobileContent(dynamic state, dynamic notifier, dynamic locationState, dynamic locationNotifier) {
    return Column(
      children: [
        _buildMobileHeader(state, notifier, locationNotifier),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                if (widget.isBaseline) ...[
                  NeoBrutalistContainer(
                    backgroundColor: const Color(0xFF9B51E0),
                    shadowColor: Colors.black,
                    padding: const EdgeInsets.all(16),
                    child: const Text(
                      'Run comfortably but at a steady, pushing pace. The AI will use this to calibrate your 100% effort baseline.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 13, fontStyle: FontStyle.italic, fontFamily: 'Geist'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Distance & Time
                Text(
                  state.isRunning ? locationState.totalDistanceKm.toStringAsFixed(2) : '0.00',
                  style: const TextStyle(color: Colors.white, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 80, height: 1.1),
                ),
                const Text(
                  'KILOMETERS',
                  style: TextStyle(color: Color(0xFFFC4C02), fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1),
                ),
                const SizedBox(height: 24),
                
                Text(
                  state.isRunning ? _formatElapsedTime(locationState.elapsedSeconds) : '00:00',
                  style: const TextStyle(color: Colors.white, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 56, height: 1.1),
                ),
                const Text(
                  'ELAPSED TIME',
                  style: TextStyle(color: Color(0xFFCCFF00), fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1),
                ),
                const SizedBox(height: 32),

                // Metrics Row
                Row(
                  children: [
                    Expanded(child: _buildMobileMetricCard('PACE', state.isRunning ? _formatPace(locationState.currentPaceSecondsPerKm) : _formattedTargetPace, '/KM')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildMobileMetricCard('HR', '${state.telemetry.heartRate}', 'BPM')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildMobileMetricCard('CAD', '${state.telemetry.cadence}', 'SPM')),
                  ],
                ),
                const SizedBox(height: 24),

                // HR Graph Placeholder
                _buildMobileHRGraphPlaceholder(),
                const SizedBox(height: 24),

                // Coaching Cue
                if (state.latestCue != null)
                  _buildCoachingCueCard(state.latestCue!.text),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
        // Bottom Controls
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: _buildMobileControls(state, notifier, locationState, locationNotifier),
        ),
      ],
    );
  }

  Widget _buildMobileHeader(dynamic state, dynamic notifier, dynamic locationNotifier) {
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
            onTap: () {
              notifier.stopRun();
              locationNotifier.stopTracking();
              context.pop();
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF26262B),
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: const Icon(Icons.chevron_left, color: Colors.white, size: 16),
            ),
          ),
          Text(
            widget.isBaseline ? 'BASELINE TEST' : (widget.isGhostRacing ? 'GHOST RACE' : 'EASY RUN'),
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Unbounded',
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: state.isRunning ? const Color(0xFFCCFF00) : Colors.grey[800],
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: Row(
              children: [
                Icon(state.isRunning ? Icons.satellite_alt_rounded : Icons.satellite_alt_outlined, size: 10, color: Colors.black),
                const SizedBox(width: 4),
                Text(
                  state.isRunning ? 'GPS SECURED' : 'GPS STANDBY',
                  style: const TextStyle(color: Colors.black, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileMetricCard(String label, String value, String unit) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF18181C),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))],
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF8E8E93), fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 10)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 24)),
          const SizedBox(height: 2),
          Text(unit, style: const TextStyle(color: Color(0xFF8E8E93), fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildMobileHRGraphPlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF18181C),
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('HEART RATE', style: TextStyle(color: Colors.white, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFC4C02),
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
                child: const Text('ZONE 2', style: TextStyle(color: Colors.white, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Mock Graph
          Container(
            height: 80,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF111113),
              border: Border.all(color: const Color(0xFF26262B), width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMockBar(30), _buildMockBar(45), _buildMockBar(60),
                _buildMockBar(50), _buildMockBar(70), _buildMockBar(65),
                _buildMockBar(80, isAccent: true), _buildMockBar(75), _buildMockBar(60),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockBar(double height, {bool isAccent = false}) {
    return Container(
      width: 16,
      height: height,
      color: isAccent ? const Color(0xFFFC4C02) : const Color(0xFF26262B),
    );
  }

  Widget _buildCoachingCueCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.graphic_eq_rounded, color: Colors.black, size: 20),
              SizedBox(width: 8),
              Text('COACHING CUE', style: TextStyle(color: Colors.black, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Text(text, style: const TextStyle(color: Colors.black, fontFamily: 'Geist', fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildMobileControls(dynamic state, dynamic notifier, dynamic locationState, dynamic locationNotifier) {
    if (!state.isRunning) {
      return GestureDetector(
        onTap: () {
          setState(() { _isPaused = false; });
          notifier.startRun(
            isGhostRace: widget.isGhostRacing,
            distance: widget.targetDistance,
            paceSeconds: widget.targetPaceSeconds,
            strictness: widget.strictness,
          );
          locationNotifier.startTracking();
        },
        child: Container(
          width: double.infinity,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFCCFF00),
            border: Border.all(color: Colors.black, width: 3),
            boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
          ),
          child: const Text('START WORKOUT', style: TextStyle(color: Colors.black, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 16)),
        ),
      );
    } else {
      return Row(
        children: [
          Expanded(
            flex: 1,
            child: GestureDetector(
              onTap: () => _handleStopRun(notifier, locationState, locationNotifier),
              child: Container(
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFFC4C02),
                  border: Border.all(color: Colors.black, width: 3),
                  boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
                ),
                child: const Icon(Icons.stop_rounded, color: Colors.white, size: 32),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () {
                setState(() { _isPaused = !_isPaused; });
              },
              child: Container(
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _isPaused ? const Color(0xFFCCFF00) : const Color(0xFF18181C),
                  border: Border.all(color: Colors.black, width: 3),
                  boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded, color: _isPaused ? Colors.black : Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      _isPaused ? 'RESUME RUN' : 'PAUSE WORKOUT',
                      style: TextStyle(color: _isPaused ? Colors.black : Colors.white, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 14),
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

  // --- DESKTOP LAYOUT ---

  Widget _buildDesktopContent(dynamic state, dynamic notifier, dynamic locationState, dynamic locationNotifier) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDesktopSidebar(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildDesktopHeader(state, notifier, locationNotifier),
                const SizedBox(height: 48),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: Stats & Controls
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.isBaseline) ...[
                              NeoBrutalistContainer(
                                backgroundColor: const Color(0xFF9B51E0),
                                shadowColor: Colors.black,
                                padding: const EdgeInsets.all(16),
                                child: const Text(
                                  'Run comfortably but at a steady, pushing pace. The AI will use this to calibrate your 100% effort baseline.',
                                  style: TextStyle(color: Colors.white, fontSize: 14, fontStyle: FontStyle.italic, fontFamily: 'Geist'),
                                ),
                              ),
                              const SizedBox(height: 32),
                            ],
                            
                            Text(
                              state.isRunning ? locationState.totalDistanceKm.toStringAsFixed(2) : '0.00',
                              style: const TextStyle(color: Colors.white, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 120, height: 1.0),
                            ),
                            const Text(
                              'KILOMETERS',
                              style: TextStyle(color: Color(0xFFFC4C02), fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 1),
                            ),
                            const SizedBox(height: 40),
                            
                            Text(
                              state.isRunning ? _formatElapsedTime(locationState.elapsedSeconds) : '00:00',
                              style: const TextStyle(color: Colors.white, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 80, height: 1.0),
                            ),
                            const Text(
                              'ELAPSED TIME',
                              style: TextStyle(color: Color(0xFFCCFF00), fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
                            ),
                            const SizedBox(height: 48),

                            // Metrics
                            Row(
                              children: [
                                _buildDesktopMetric('Pace', state.isRunning ? _formatPace(locationState.currentPaceSecondsPerKm) : _formattedTargetPace, '/km'),
                                const SizedBox(width: 48),
                                _buildDesktopMetric('HR', '${state.telemetry.heartRate}', 'bpm'),
                                const SizedBox(width: 48),
                                _buildDesktopMetric('Cadence', '${state.telemetry.cadence}', 'spm'),
                              ],
                            ),
                            const Spacer(),

                            // Desktop Controls
                            Row(
                              children: [
                                if (!state.isRunning)
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() { _isPaused = false; });
                                        notifier.startRun(
                                          isGhostRace: widget.isGhostRacing,
                                          distance: widget.targetDistance,
                                          paceSeconds: widget.targetPaceSeconds,
                                          strictness: widget.strictness,
                                        );
                                        locationNotifier.startTracking();
                                      },
                                      child: Container(
                                        height: 72,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFCCFF00),
                                          border: Border.all(color: Colors.black, width: 3),
                                          boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(6, 6))],
                                        ),
                                        child: const Text('START WORKOUT', style: TextStyle(color: Colors.black, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 18)),
                                      ),
                                    ),
                                  )
                                else ...[
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() { _isPaused = !_isPaused; });
                                      },
                                      child: Container(
                                        height: 72,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: _isPaused ? const Color(0xFFCCFF00) : const Color(0xFF18181C),
                                          border: Border.all(color: Colors.black, width: 3),
                                          boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(6, 6))],
                                        ),
                                        child: Text(
                                          _isPaused ? 'RESUME' : 'PAUSE',
                                          style: TextStyle(color: _isPaused ? Colors.black : Colors.white, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 18),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => _handleStopRun(notifier, locationState, locationNotifier),
                                      child: Container(
                                        height: 72,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFC4C02),
                                          border: Border.all(color: Colors.black, width: 3),
                                          boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(6, 6))],
                                        ),
                                        child: const Text('END RUN', style: TextStyle(color: Colors.white, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 18)),
                                      ),
                                    ),
                                  ),
                                ]
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 64),
                      // Right Column: Live Status & Ghost Pacing
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (widget.isGhostRacing) ...[
                              _buildDesktopGhostPacerCard(),
                              const SizedBox(height: 24),
                            ],
                            if (state.latestCue != null) ...[
                              _buildDesktopCoachingCueCard(state.latestCue!.text),
                              const SizedBox(height: 24),
                            ],
                            Expanded(child: _buildDesktopHRGraphPlaceholder()),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
          _buildDesktopSidebarItem(Icons.crop_square, 'DASHBOARD', '/dashboard', false),
          const SizedBox(height: 16),
          _buildDesktopSidebarItem(Icons.crop_square, 'PLAN', '/dashboard', false),
          const SizedBox(height: 16),
          _buildDesktopSidebarItem(Icons.circle, 'LIVE RUN', '/dashboard', true, iconSize: 10),
          const SizedBox(height: 16),
          _buildDesktopSidebarItem(Icons.circle, 'ANALYTICS', '/dashboard', false, iconSize: 10),
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

  Widget _buildDesktopSidebarItem(IconData icon, String label, String route, bool isSelected, {double iconSize = 18}) {
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          ref.read(liveCoachingProvider.notifier).stopRun();
          ref.read(locationProvider.notifier).stopTracking();
          context.go(route);
        }
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

  Widget _buildDesktopHeader(dynamic state, dynamic notifier, dynamic locationNotifier) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () {
                notifier.stopRun();
                locationNotifier.stopTracking();
                context.pop();
              },
              child: const Text(
                '< DASHBOARD',
                style: TextStyle(color: Color(0xFFFC4C02), fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 14),
              ),
            ),
            const SizedBox(width: 24),
            Text(
              widget.isBaseline ? 'BASELINE TEST' : 'LIVE WORKOUT TRACKING',
              style: const TextStyle(color: Colors.white, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 24),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: state.isRunning ? const Color(0xFFCCFF00) : Colors.grey[800],
            border: Border.all(color: Colors.black, width: 2),
          ),
          child: Row(
            children: [
              Icon(state.isRunning ? Icons.satellite_alt_rounded : Icons.satellite_alt_outlined, size: 14, color: Colors.black),
              const SizedBox(width: 8),
              Text(
                state.isRunning ? 'GPS SECURED' : 'GPS STANDBY',
                style: const TextStyle(color: Colors.black, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopMetric(String label, String value, String unit) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(color: Color(0xFF8E8E93), fontFamily: 'Geist', fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontFamily: 'Geist', fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 4),
        Text(
          unit,
          style: const TextStyle(color: Color(0xFF8E8E93), fontFamily: 'Geist', fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDesktopGhostPacerCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF18181C),
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(6, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('GHOST PACER STATUS', style: TextStyle(color: Colors.white, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF9B51E0),
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
                child: const Text('ACTIVE', style: TextStyle(color: Colors.white, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('AHEAD BY 14 SECONDS', style: TextStyle(color: Color(0xFFCCFF00), fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 24)),
          const SizedBox(height: 8),
          const Text('You are slightly ahead of your target 5:30 pace.', style: TextStyle(color: Color(0xFF8E8E93), fontFamily: 'Geist', fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildDesktopCoachingCueCard(String text) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(6, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.graphic_eq_rounded, color: Colors.black, size: 24),
              SizedBox(width: 12),
              Text('LIVE AUDIO COACHING', style: TextStyle(color: Colors.black, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 16),
          Text(text, style: const TextStyle(color: Colors.black, fontFamily: 'Geist', fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildDesktopHRGraphPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF18181C),
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(6, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('HEART RATE DYNAMICS', style: TextStyle(color: Colors.white, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFC4C02),
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
                child: const Text('ZONE 2', style: TextStyle(color: Colors.white, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF111113),
                border: Border.all(color: const Color(0xFF26262B), width: 2),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMockDesktopBar(60), _buildMockDesktopBar(80), _buildMockDesktopBar(110),
                  _buildMockDesktopBar(95), _buildMockDesktopBar(130), _buildMockDesktopBar(120),
                  _buildMockDesktopBar(150, isAccent: true), _buildMockDesktopBar(140), _buildMockDesktopBar(110),
                  _buildMockDesktopBar(130), _buildMockDesktopBar(115), _buildMockDesktopBar(100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockDesktopBar(double height, {bool isAccent = false}) {
    return Container(
      width: 20,
      height: height,
      color: isAccent ? const Color(0xFFFC4C02) : const Color(0xFF26262B),
    );
  }

  // --- ACTIONS LOGIC ---

  void _handleStopRun(dynamic notifier, dynamic locationState, dynamic locationNotifier) async {
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
  }
}
