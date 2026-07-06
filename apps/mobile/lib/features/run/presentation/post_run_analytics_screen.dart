import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class PostRunAnalyticsScreen extends StatefulWidget {
  final String geoJsonData;

  const PostRunAnalyticsScreen({Key? key, required this.geoJsonData}) : super(key: key);

  @override
  _PostRunAnalyticsScreenState createState() => _PostRunAnalyticsScreenState();
}

class _PostRunAnalyticsScreenState extends State<PostRunAnalyticsScreen> {
  MapboxMap? mapboxMap;

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
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blueAccent.withOpacity(0.3))
                      ),
                      child: FutureBuilder<String>(
                        // In production, this would call GET /analytics/nutrition
                        future: Future.delayed(const Duration(seconds: 2), () => "• 45g Carbs (e.g., 2 bananas or rice)\n• 1.2L Water with electrolytes\n• 20g Protein for muscle repair"),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
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
