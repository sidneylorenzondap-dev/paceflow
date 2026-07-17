import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/api_constants.dart';

class PostRunAnalyticsScreen extends StatefulWidget {
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

class _PostRunAnalyticsScreenState extends State<PostRunAnalyticsScreen> {
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
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Row(
            children: [
              Icon(Icons.auto_awesome, color: Color(0xFFFC4C02), size: 32),
              SizedBox(width: 8),
              Text('Baseline Complete!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'Great job! We now have your baseline data for ${widget.pendingPlanGoal}. Are you ready to generate your AI Training Plan?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Later', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.push('/training', extra: {'goal': widget.pendingPlanGoal});
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFC4C02)),
              child: const Text('Generate Plan'),
            ),
          ],
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
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.amber, size: 32),
              SizedBox(width: 8),
              Text('Plan Completed!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'Incredible work! You just broke your record and completed your active training plan. Are you ready to level up and generate a new plan?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Not right now', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/training');
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFC4C02)),
              child: const Text('Level Up!'),
            ),
          ],
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
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Post-Run Analytics', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: kIsWeb
                ? Container(
                    color: Colors.grey[900],
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.map, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            "Mapbox Heatmap\n(Available on iOS/Android device)",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 16),
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
                  ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Fatigue Heatmap", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 10),
                    Text("Red dots indicate where your cadence dropped and form degraded.", style: TextStyle(color: Colors.grey[400], fontSize: 16)),
                    const SizedBox(height: 20),
                    const Text("AI Recovery Coach", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['Standard', 'Vegan', 'Keto', 'High-Protein'].map((diet) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(diet),
                              selected: selectedDiet == diet,
                              onSelected: (bool selected) {
                                if (selected) {
                                  setState(() {
                                    selectedDiet = diet;
                                    _nutritionPlanFuture = _fetchNutritionPlan(diet);
                                  });
                                }
                              },
                              selectedColor: Colors.blueAccent.withOpacity(0.3),
                              backgroundColor: Colors.grey[900],
                              labelStyle: TextStyle(color: selectedDiet == diet ? Colors.blueAccent : Colors.grey),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(color: selectedDiet == diet ? Colors.blueAccent : Colors.grey[800]!),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blueAccent.withOpacity(0.3))
                      ),
                      child: FutureBuilder<String>(
                        future: _nutritionPlanFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                          }
                          if (snapshot.hasError) {
                            return Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red));
                          }
                          return Text(
                            snapshot.data ?? "Failed to load nutrition plan",
                            style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
                          );
                        }
                      ),
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
