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
                          child: Text('GENERATE PLAN'),
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

    // Basic mock check: If they ran further than 5000m, they likely broke a baseline record!
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
                          child: Text('LEVEL UP!'),
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
    // Hide default UI for cleaner look
    mapboxMap.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
    mapboxMap.compass.updateSettings(CompassSettings(enabled: false));
    
    _loadFatigueHeatmap();
  }

  Future<void> _loadFatigueHeatmap() async {
    if (mapboxMap == null) return;
    
    try {
      await mapboxMap!.style.addSource(GeoJsonSource(id: "fatigue-source", data: widget.geoJsonData));
      
      // Add a circle layer to visualize the fatigue points
      await mapboxMap!.style.addLayer(
        CircleLayer(
          id: "fatigue-layer",
          sourceId: "fatigue-source",
          circleColor: Colors.red.value, // Simplification to fix compiler error
          circleRadius: 5.0,
        ),
      );
    } catch (e) {
      debugPrint("Error loading heatmap: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Note: To use Mapbox, a public token must be set via MapboxOptions in main.dart or Info.plist / AndroidManifest
    // For this prototype, we assume the token is configured at the platform level.
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('POST-RUN ANALYTICS', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: ResponsiveLayout(
        mobile: _buildMobileContent(),
        desktop: _buildDesktopContent(),
      ),
    );
  }

  Widget _buildMobileContent() {
    return Column(
      children: [
        Expanded(flex: 2, child: _buildMapArea()),
        Expanded(flex: 1, child: _buildAnalyticsArea()),
      ],
    );
  }

  Widget _buildDesktopContent() {
    return Row(
      children: [
        Expanded(flex: 2, child: _buildMapArea()),
        Expanded(flex: 1, child: _buildAnalyticsArea()),
      ],
    );
  }

  Widget _buildMapArea() {
    return kIsWeb
        ? Container(
            color: AppTheme.backgroundColor,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map, size: 64, color: Colors.grey[800]),
                  const SizedBox(height: 16),
                  const Text(
                    "MAPBOX HEATMAP\n(Available on iOS/Android device)",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.secondaryTextColor, fontSize: 14, fontFamily: 'Unbounded', fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          )
        : MapWidget(
            key: const ValueKey("mapboxWidget"),
            onMapCreated: _onMapCreated,
            styleUri: MapboxStyles.DARK,
            cameraOptions: CameraOptions(
              center: Point(coordinates: Position(-122.4194, 37.7749)),
              zoom: 12.0,
            ),
          );
  }

  Widget _buildAnalyticsArea() {
    return Container(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("FATIGUE HEATMAP", style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 20)),
                    const SizedBox(height: 10),
                    const Text("Red dots indicate where your cadence dropped and form degraded.", style: TextStyle(color: AppTheme.secondaryTextColor, fontSize: 14, fontFamily: 'Geist')),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Text("AI RECOVERY COACH", style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 20)),
                        const SizedBox(width: 8),
                        ref.watch(userProfileProvider).when(
                          data: (profile) => profile.subscriptionTier == 'premium' 
                            ? const Icon(Icons.auto_awesome, color: AppTheme.primaryColor)
                            : const Icon(Icons.lock, color: Colors.grey, size: 20),
                          loading: () => const SizedBox(),
                          error: (_, __) => const SizedBox(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['Standard', 'Vegan', 'Keto', 'High-Protein'].map((diet) {
                          final isSelected = selectedDiet == diet;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedDiet = diet;
                                  _nutritionPlanFuture = _fetchNutritionPlan(diet);
                                });
                              },
                              child: NeoBrutalistContainer(
                                backgroundColor: isSelected ? AppTheme.accentColor : AppTheme.surfaceColor,
                                shadowColor: Colors.black,
                                shadowOffset: isSelected ? 1 : 2,
                                borderWidth: 1.5,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Text(
                                  diet.toUpperCase(),
                                  style: TextStyle(
                                    color: isSelected ? Colors.black : Colors.white,
                                    fontFamily: 'Unbounded',
                                    fontWeight: FontWeight.w900,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    NeoBrutalistContainer(
                      backgroundColor: AppTheme.surfaceColor,
                      shadowColor: AppTheme.primaryColor,
                      borderWidth: 2,
                      shadowOffset: 4,
                      padding: const EdgeInsets.all(16),
                      child: FutureBuilder<String>(
                        future: _nutritionPlanFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: AppTheme.primaryColor)));
                          }
                          if (snapshot.hasError) {
                            return Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.redAccent, fontFamily: 'Geist'));
                          }
                          return Text(
                            snapshot.data ?? "Failed to load nutrition plan",
                            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5, fontFamily: 'Geist'),
                          );
                        }
                      ),
                    )
                  ],
                ),
              ),
            );
  }
}
