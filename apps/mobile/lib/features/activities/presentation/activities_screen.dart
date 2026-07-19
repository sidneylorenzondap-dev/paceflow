import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../data/activity_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/neo_brutalist_container.dart';
import '../../../core/ui/responsive_layout.dart';
import '../../training/domain/training_workout.dart'; 

class ActivitiesScreen extends ConsumerStatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  ConsumerState<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends ConsumerState<ActivitiesScreen> {
  dynamic _selectedActivity;

  String _formatPace(double paceSeconds) {
    if (paceSeconds <= 0) return '--:--';
    final minutes = (paceSeconds / 60).floor();
    final seconds = (paceSeconds % 60).floor().toString().padLeft(2, '0');
    return '$minutes /KM';
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds / 60).floor().toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    if (totalSeconds >= 3600) {
      final hours = (totalSeconds / 3600).floor();
      final remMin = ((totalSeconds % 3600) / 60).floor().toString().padLeft(2, '0');
      return '$hours:$remMin:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(runHistoryProvider);

    return Scaffold(
      backgroundColor: Colors.transparent, // Parent Dashboard handles background
      body: SafeArea(
        child: ResponsiveLayout(
          mobile: _buildMobileContent(historyAsync),
          desktop: _buildDesktopContent(historyAsync),
        ),
      ),
    );
  }

  // --- MOBILE LAYOUT ---

  Widget _buildMobileContent(AsyncValue<List<dynamic>> historyAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildMobileHeader(),
        Expanded(
          child: _buildListView(historyAsync, isMobile: true),
        ),
      ],
    );
  }

  Widget _buildMobileHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF0E0E10),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RUN LOGS',
            style: TextStyle(
              color: Color(0xFFFC4C02),
              fontFamily: 'Unbounded',
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'ACTIVITY ARCHIVE',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Unbounded',
              fontWeight: FontWeight.w900,
              fontSize: 28,
            ),
          ),
        ],
      ),
    );
  }

  // --- DESKTOP LAYOUT ---

  Widget _buildDesktopContent(AsyncValue<List<dynamic>> historyAsync) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RUN LOGS',
                style: TextStyle(
                  color: Color(0xFFFC4C02),
                  fontFamily: 'Unbounded',
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'ACTIVITY ARCHIVE',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Unbounded',
                  fontWeight: FontWeight.w900,
                  fontSize: 40,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: List
                Expanded(
                  flex: 5,
                  child: _buildListView(historyAsync, isMobile: false),
                ),
                const SizedBox(width: 40),
                // Right Column: Details Panel
                Expanded(
                  flex: 4,
                  child: _buildDesktopDetailsPanel(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopDetailsPanel() {
    if (_selectedActivity == null) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF18181C),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: const Center(
          child: Text(
            'SELECT A RUN TO VIEW DETAILS',
            style: TextStyle(color: Color(0xFF8E8E93), fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 14),
          ),
        ),
      );
    }

    final session = _selectedActivity;
    // Generate mock detailed stats
    final maxCadence = (session.isBaseline == true) ? 180 : 184;
    final avgHeartRate = (session.isBaseline == true) ? 175 : 165;
    final aerobicLoad = (session.isBaseline == true) ? 'MAX (5.0)' : 'HIGH (4.2)';
    
    // Default feedback if none provided
    final feedback = session.isBaseline == true 
      ? '"Baseline test complete. High heart rate drift detected in the final 5 minutes. Adjusting future threshold paces to compensate."'
      : '"Excellent interval pacing consistency. Cadence recovery periods averaged 142 SPM. Ready for higher thresholds."';

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: Color(0xFF18181C),
        // Adding the right yellow accent line from the design
        border: Border(
          top: BorderSide(color: Colors.black, width: 2),
          bottom: BorderSide(color: Colors.black, width: 2),
          left: BorderSide(color: Colors.black, width: 2),
          right: BorderSide(color: Color(0xFFCCFF00), width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SELECTED RUN DETAILED', style: TextStyle(color: Color(0xFFFC4C02), fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 10)),
          const SizedBox(height: 8),
          Text(
            (session.isBaseline == true ? 'BASELINE TEST' : 'AI TRAINING RUN').toUpperCase(), 
            style: const TextStyle(color: Colors.white, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 24)
          ),
          const SizedBox(height: 24),
          
          // Map Placeholder
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF0E0E10),
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: const Center(
              child: Icon(Icons.map_outlined, color: Color(0xFF8E8E93), size: 48),
            ),
          ),
          const SizedBox(height: 32),
          
          // Performance Breakdown
          const Text('PERFORMANCE BREAKDOWN', style: TextStyle(color: Color(0xFF8E8E93), fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 10)),
          const SizedBox(height: 16),
          _buildStatRow('Max Cadence', '$maxCadence SPM', const Color(0xFFCCFF00)),
          const SizedBox(height: 12),
          _buildStatRow('Avg Heart Rate', '$avgHeartRate BPM', const Color(0xFFFC4C02)),
          const SizedBox(height: 12),
          _buildStatRow('Aerobic Load', aerobicLoad, const Color(0xFF56CCF2)), // Light blue
          
          const SizedBox(height: 32),
          
          // AI Coach Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E),
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  color: const Color(0xFFCCFF00),
                  child: const Text('AI COACH INPUT', style: TextStyle(color: Colors.black, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 10)),
                ),
                const SizedBox(height: 12),
                Text(
                  feedback,
                  style: const TextStyle(color: Colors.white, fontFamily: 'Geist', fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF8E8E93), fontFamily: 'Geist', fontSize: 14)),
        Text(value, style: TextStyle(color: valueColor, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 14)),
      ],
    );
  }

  // --- CONTENT BUILDER ---

  Widget _buildListView(AsyncValue<List<dynamic>> historyAsync, {required bool isMobile}) {
    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFCCFF00))),
      error: (error, stack) => Center(
        child: Text('Error loading activities: $error', style: const TextStyle(color: Colors.red, fontFamily: 'Geist')),
      ),
      data: (history) {
        if (history.isEmpty) {
          return Center(
            child: NeoBrutalistContainer(
              backgroundColor: const Color(0xFF18181C),
              shadowColor: Colors.black,
              padding: const EdgeInsets.all(32),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.directions_run, size: 64, color: Color(0xFF8E8E93)),
                  SizedBox(height: 16),
                  Text('NO ACTIVITIES YET', style: TextStyle(color: Colors.white, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 18)),
                  SizedBox(height: 8),
                  Text('Complete a run to see your history here.', style: TextStyle(color: Color(0xFF8E8E93), fontFamily: 'Geist', fontSize: 14)),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(runHistoryProvider.future),
          color: const Color(0xFFCCFF00),
          backgroundColor: const Color(0xFF18181C),
          child: ListView.separated(
            padding: EdgeInsets.all(isMobile ? 24 : 0),
            itemCount: history.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) => _buildHistoryCard(history[index], isMobile: isMobile),
          ),
        );
      },
    );
  }

  Widget _buildHistoryCard(dynamic session, {required bool isMobile}) {
    final distanceKm = (session.totalTime / session.avgPace) / 60;
    final dateFormatted = DateFormat('MMM dd').format(session.date).toUpperCase();
    final title = session.isBaseline == true ? 'BASELINE TEST' : 'MIDNIGHT INTERVALS'; // Using mock title based on screenshot, could be dynamic
    
    final isSelected = !isMobile && _selectedActivity == session;

    return GestureDetector(
      onTap: () {
        if (isMobile) {
          context.push('/analytics', extra: {
            'geoJsonData': "{}",
            'distance': distanceKm * 1000,
            'isHistoryView': true,
          });
        } else {
          setState(() {
            _selectedActivity = session;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF18181C),
          border: Border.all(color: Colors.black, width: 2),
          // Subtle highlight for selected card on desktop
          boxShadow: isSelected ? const [BoxShadow(color: Color(0xFFCCFF00), offset: Offset(-4, 0))] : const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Unbounded',
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      if (!isMobile) ...[
                        const SizedBox(height: 4),
                        Text(
                          '$dateFormatted - PACEFLOW COMPATIBLE',
                          style: const TextStyle(
                            color: Color(0xFF8E8E93),
                            fontFamily: 'Geist',
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isMobile)
                  Text(
                    dateFormatted,
                    style: const TextStyle(
                      color: Color(0xFF8E8E93),
                      fontFamily: 'Unbounded',
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                // Distance Tag (Green)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCCFF00),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: Text(
                    '${distanceKm.toStringAsFixed(1)} KM',
                    style: const TextStyle(color: Colors.black, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 12),
                // Pace Tag (Purple)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9B51E0),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: Text(
                    _formatPace(session.avgPace * 60),
                    style: const TextStyle(color: Colors.white, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 12),
                // Duration Tag (Orange)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFC4C02),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: Text(
                    _formatDuration(session.totalTime),
                    style: const TextStyle(color: Colors.white, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
