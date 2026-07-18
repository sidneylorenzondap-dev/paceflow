import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/api_constants.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../user/data/user_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/neo_brutalist_container.dart';
import '../../../core/ui/neo_brutalist_button.dart';
import '../../../core/ui/responsive_layout.dart';

class PostRunAnalyticsScreen extends ConsumerStatefulWidget {
  final String geoJsonData;
  final double distanceMeters;
  final bool isHistoryView;
  final bool isBaseline;
  final String? pendingPlanGoal;

  const PostRunAnalyticsScreen({
    super.key, 
    required this.geoJsonData,
    this.distanceMeters = 0.0,
    this.isHistoryView = false,
    this.isBaseline = false,
    this.pendingPlanGoal,
  });

  @override
  _PostRunAnalyticsScreenState createState() => _PostRunAnalyticsScreenState();
}

class _PostRunAnalyticsScreenState extends ConsumerState<PostRunAnalyticsScreen> {
  MapboxMap? mapboxMap;
  String selectedDiet = 'Standard';
  late Future<String> _nutritionPlanFuture;
  bool _showedCelebration = false;

  @override
  void initState() {
    super.initState();
    _nutritionPlanFuture = _fetchNutritionPlan(selectedDiet);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPlanCompletion();
    });
  }

  void _checkPlanCompletion() {
    if (widget.isBaseline && widget.pendingPlanGoal != null && !_showedCelebration) {
      _showedCelebration = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: NeoBrutalistContainer(
            backgroundColor: AppTheme.surfaceColor,
            shadowColor: AppTheme.primaryColor,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: AppTheme.primaryColor, size: 32),
                    const SizedBox(width: 8),
                    Expanded(child: Text('BASELINE COMPLETE!', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 18))),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Great job! We now have your baseline data for ${widget.pendingPlanGoal}. Are you ready to generate your AI Training Plan?',
                  style: const TextStyle(color: AppTheme.secondaryTextColor, fontFamily: 'Geist'),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('LATER', style: TextStyle(color: AppTheme.secondaryTextColor, fontFamily: 'Unbounded', fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 16),
                      NeoBrutalistButton(
                        onPressed: () {
                          Navigator.pop(context);
                          context.push('/training', extra: {'goal': widget.pendingPlanGoal});
                        },
                        backgroundColor: AppTheme.primaryColor,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text('GENERATE PLAN', style: TextStyle(fontFamily: 'Unbounded', fontWeight: FontWeight.w900)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }

    if (!widget.isHistoryView && widget.distanceMeters >= 5000 && !_showedCelebration) {
      _showedCelebration = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: NeoBrutalistContainer(
            backgroundColor: AppTheme.surfaceColor,
            shadowColor: Colors.amber,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.emoji_events, color: Colors.amber, size: 32),
                    const SizedBox(width: 8),
                    Expanded(child: Text('PLAN COMPLETED!', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 18))),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Incredible work! You just broke your record and completed your active training plan. Are you ready to level up and generate a new plan?',
                  style: TextStyle(color: AppTheme.secondaryTextColor, fontFamily: 'Geist'),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('NOT RIGHT NOW', style: TextStyle(color: AppTheme.secondaryTextColor, fontFamily: 'Unbounded', fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 16),
                      NeoBrutalistButton(
                        onPressed: () {
                          Navigator.pop(context);
                          context.go('/training');
                        },
                        backgroundColor: AppTheme.primaryColor,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text('LEVEL UP!', style: TextStyle(fontFamily: 'Unbounded', fontWeight: FontWeight.w900)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Map<String, String> _nutritionCache = {};

  Future<String> _fetchNutritionPlan(String diet) async {
    if (_nutritionCache.containsKey(diet)) {
      return _nutritionCache[diet]!;
    }
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/analytics/nutrition?diet=$diet');
      
      final session = Supabase.instance.client.auth.currentSession;
      final token = session?.accessToken;
      
      final response = await http.get(url, headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final plan = data['plan'] ?? 'No plan received.';
        _nutritionCache[diet] = plan;
        return plan;
      } else {
        return 'Failed to load plan: ${response.statusCode}';
      }
    } catch (e) {
      return 'Network error: $e';
    }
  }

  _onMapCreated(MapboxMap mapboxMap) {
    this.mapboxMap = mapboxMap;
    mapboxMap.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
    mapboxMap.compass.updateSettings(CompassSettings(enabled: false));
    _loadFatigueHeatmap();
  }

  Future<void> _loadFatigueHeatmap() async {
    if (mapboxMap == null) return;
    try {
      await mapboxMap!.style.addSource(GeoJsonSource(id: "fatigue-source", data: widget.geoJsonData));
      await mapboxMap!.style.addLayer(
        CircleLayer(
          id: "fatigue-layer",
          sourceId: "fatigue-source",
          circleColor: Colors.red.value,
          circleRadius: 5.0,
        ),
      );
    } catch (e) {
      debugPrint("Error loading heatmap: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E10),
      body: SafeArea(
        child: ResponsiveLayout(
          mobile: _buildMobileContent(),
          desktop: _buildDesktopContent(),
        ),
      ),
    );
  }

  // --- MOBILE LAYOUT ---

  Widget _buildMobileContent() {
    return Column(
      children: [
        _buildMobileHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                // Top Stats
                _buildTopStats(),
                const SizedBox(height: 32),
                
                // Map Area
                _buildMapSection(),
                const SizedBox(height: 24),

                // Metrics Grid
                _buildMetricsGrid(),
                const SizedBox(height: 32),

                // AI Breakdown
                _buildAIBreakdown(),
                const SizedBox(height: 24),

                // AI Nutrition
                _buildAINutrition(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileHeader() {
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
            'POST-RUN ANALYTICS',
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

  Widget _buildTopStats() {
    // Dummy conversion if 0 for prototype
    final km = widget.distanceMeters > 0 ? (widget.distanceMeters / 1000).toStringAsFixed(1) : '5.0';
    return Column(
      children: [
        Text(
          km,
          style: const TextStyle(color: Colors.white, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 80, height: 1.1),
        ),
        const Text(
          'KILOMETERS',
          style: TextStyle(color: Color(0xFFFC4C02), fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1),
        ),
        const SizedBox(height: 24),
        const Text(
          '32:41', // Placeholder time
          style: TextStyle(color: Colors.white, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 56, height: 1.1),
        ),
        const Text(
          'ELAPSED TIME',
          style: TextStyle(color: Color(0xFFCCFF00), fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1),
        ),
      ],
    );
  }

  Widget _buildMapSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF18181C),
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('ROUTE & EFFORT HEATMAP', style: TextStyle(color: Colors.white, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 14)),
                const Icon(Icons.map_outlined, color: Colors.white, size: 20),
              ],
            ),
          ),
          Container(
            height: 250,
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.black, width: 3)),
            ),
            child: widget.geoJsonData.isNotEmpty 
              ? MapWidget(
                  key: const ValueKey("mapWidget"),
                  onMapCreated: _onMapCreated,
                )
              : Container(
                  color: const Color(0xFF111113),
                  alignment: Alignment.center,
                  child: const Text('NO GPS DATA', style: TextStyle(color: Color(0xFF8E8E93), fontFamily: 'Unbounded', fontWeight: FontWeight.w900)),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildMetricBox('AVG PACE', '5:35/KM', const Color(0xFFCCFF00))),
            const SizedBox(width: 16),
            Expanded(child: _buildMetricBox('MAX HR', '172 BPM', const Color(0xFF9B51E0))),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildMetricBox('AVG CADENCE', '165 SPM', const Color(0xFFFC4C02))),
            const SizedBox(width: 16),
            Expanded(child: _buildMetricBox('ELEVATION', '45M', const Color(0xFF2D9CDB))),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricBox(String label, String value, Color tagColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF18181C),
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: tagColor,
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: Text(label, style: TextStyle(color: tagColor == const Color(0xFFCCFF00) ? Colors.black : Colors.white, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 10)),
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: Colors.white, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildAIBreakdown() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
              Icon(Icons.psychology, color: Colors.black, size: 24),
              SizedBox(width: 8),
              Text('AI RUN BREAKDOWN', style: TextStyle(color: Colors.black, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Your form was highly efficient for the first 3km, but cadence dropped by 8% in the final kilometer. Focus on maintaining quick turnover when fatigued.',
            style: TextStyle(color: Colors.black, fontFamily: 'Geist', fontWeight: FontWeight.bold, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildAINutrition() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF18181C),
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.restaurant, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text('AI RECOVERY NUTRITION', style: TextStyle(color: Colors.white, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildDietToggle('Standard')),
              const SizedBox(width: 8),
              Expanded(child: _buildDietToggle('Vegan')),
              const SizedBox(width: 8),
              Expanded(child: _buildDietToggle('Keto')),
            ],
          ),
          const SizedBox(height: 20),
          FutureBuilder<String>(
            future: _nutritionPlanFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(color: Color(0xFFCCFF00)),
                ));
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return const Text('Failed to load nutrition plan.', style: TextStyle(color: Colors.red));
              }
              return Text(
                snapshot.data!,
                style: const TextStyle(color: Colors.white, fontFamily: 'Geist', fontSize: 14, height: 1.5),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDietToggle(String diet) {
    bool isSelected = selectedDiet == diet;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedDiet = diet;
          _nutritionPlanFuture = _fetchNutritionPlan(diet);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFCCFF00) : Colors.transparent,
          border: Border.all(color: isSelected ? Colors.black : const Color(0xFF8E8E93), width: 2),
        ),
        child: Text(
          diet.toUpperCase(),
          style: TextStyle(
            color: isSelected ? Colors.black : const Color(0xFF8E8E93),
            fontFamily: 'Unbounded',
            fontWeight: FontWeight.w900,
            fontSize: 10,
          ),
        ),
      ),
    );
  }

  // --- DESKTOP LAYOUT ---

  Widget _buildDesktopContent() {
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
                _buildDesktopHeader(),
                const SizedBox(height: 48),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: Stats & Map
                      Expanded(
                        flex: 5,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.distanceMeters > 0 ? (widget.distanceMeters / 1000).toStringAsFixed(1) : '5.0',
                                style: const TextStyle(color: Colors.white, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 120, height: 1.0),
                              ),
                              const Text(
                                'KILOMETERS',
                                style: TextStyle(color: Color(0xFFFC4C02), fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 1),
                              ),
                              const SizedBox(height: 40),
                              
                              const Text(
                                '32:41',
                                style: TextStyle(color: Colors.white, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 80, height: 1.0),
                              ),
                              const Text(
                                'ELAPSED TIME',
                                style: TextStyle(color: Color(0xFFCCFF00), fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
                              ),
                              const SizedBox(height: 48),

                              _buildMetricsGrid(),
                              const SizedBox(height: 48),

                              _buildMapSection(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 64),
                      // Right Column: Summary & AI
                      Expanded(
                        flex: 4,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildDesktopGhostPacerCard(),
                              const SizedBox(height: 32),
                              _buildAIBreakdown(),
                              const SizedBox(height: 32),
                              _buildAINutrition(),
                            ],
                          ),
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
          _buildDesktopSidebarItem(Icons.circle, 'LIVE RUN', '/dashboard', false, iconSize: 10),
          const SizedBox(height: 16),
          _buildDesktopSidebarItem(Icons.circle, 'ANALYTICS', '/dashboard', true, iconSize: 10),
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

  Widget _buildDesktopHeader() {
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
          'POST-RUN ANALYTICS',
          style: TextStyle(color: Colors.white, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 24),
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
              const Text('GHOST PACER SUMMARY', style: TextStyle(color: Colors.white, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF9B51E0),
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
                child: const Text('VICTORY', style: TextStyle(color: Colors.white, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('BEAT TARGET BY 14 SECONDS', style: TextStyle(color: Color(0xFFCCFF00), fontFamily: 'Unbounded', fontWeight: FontWeight.w900, fontSize: 24)),
          const SizedBox(height: 8),
          const Text('You held off the ghost pacer efficiently during the final mile push.', style: TextStyle(color: Color(0xFF8E8E93), fontFamily: 'Geist', fontSize: 14)),
        ],
      ),
    );
  }
}
