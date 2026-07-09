import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../core/constants/api_constants.dart';
import 'ble_service.dart';

class TelemetryData {
  final int heartRate;
  final int cadence;
  final double groundContactTime;
  final double verticalOscillation;

  TelemetryData({
    this.heartRate = 0, 
    this.cadence = 0, 
    this.groundContactTime = 0.0,
    this.verticalOscillation = 0.0,
  });

  factory TelemetryData.fromJson(Map<String, dynamic> json) {
    return TelemetryData(
      heartRate: json['heartRate'] ?? 0,
      cadence: json['cadence'] ?? 0,
      groundContactTime: (json['groundContactTime'] ?? 0).toDouble(),
      verticalOscillation: (json['verticalOscillation'] ?? 0).toDouble(),
    );
  }
}

class CoachingCue {
  final String text;
  final DateTime timestamp;

  CoachingCue({required this.text, required this.timestamp});
}

class LiveCoachingState {
  final bool isRunning;
  final TelemetryData telemetry;
  final CoachingCue? latestCue;

  LiveCoachingState({
    this.isRunning = false,
    required this.telemetry,
    this.latestCue,
  });

  LiveCoachingState copyWith({
    bool? isRunning,
    TelemetryData? telemetry,
    CoachingCue? latestCue,
  }) {
    return LiveCoachingState(
      isRunning: isRunning ?? this.isRunning,
      telemetry: telemetry ?? this.telemetry,
      latestCue: latestCue ?? this.latestCue,
    );
  }
}

class LiveCoachingNotifier extends Notifier<LiveCoachingState> {
  WebSocketChannel? _channel;
  final FlutterTts _flutterTts = FlutterTts();

  @override
  LiveCoachingState build() {
    _initTts();

    // Listen to real BLE Heart Rate updates
    ref.listen<BleState>(bleProvider, (previous, next) {
      if (state.isRunning && next.connectedDevice != null && next.currentHeartRate > 0) {
        // We have real HR! Update state immediately for UI
        state = state.copyWith(
          telemetry: TelemetryData(
            heartRate: next.currentHeartRate,
            cadence: state.telemetry.cadence,
            groundContactTime: state.telemetry.groundContactTime,
            verticalOscillation: state.telemetry.verticalOscillation,
          )
        );
        
        // Send real telemetry up to the backend AI
        if (_channel != null) {
          _channel!.sink.add(jsonEncode({
            'type': 'REAL_TELEMETRY',
            'data': {
              'heartRate': next.currentHeartRate,
            }
          }));
        }
      }
    });

    return LiveCoachingState(telemetry: TelemetryData());
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  void startRun({bool isGhostRace = false}) {
    state = state.copyWith(isRunning: true, latestCue: null);
    
    // Connect to backend websocket
    final wsUrl = '${ApiConstants.wsBaseUrl}/live-coaching';
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

    _channel!.stream.listen((message) {
      final jsonMessage = jsonDecode(message);
      
      if (jsonMessage['type'] == 'TELEMETRY_UPDATE') {
        final data = jsonMessage['data'];
        
        // If we have a real BLE device, ignore the mock heart rate from the backend
        final bleState = ref.read(bleProvider);
        final hasRealHr = bleState.connectedDevice != null && bleState.currentHeartRate > 0;
        
        state = state.copyWith(
          telemetry: TelemetryData(
            heartRate: hasRealHr ? bleState.currentHeartRate : data['heartRate'],
            cadence: data['cadence'],
            groundContactTime: (data['groundContactTime'] ?? 0).toDouble(),
            verticalOscillation: (data['verticalOscillation'] ?? 0).toDouble(),
          ),
        );
      } else if (jsonMessage['type'] == 'COACHING_CUE') {
        final cueText = jsonMessage['text'] as String;
        state = state.copyWith(
          latestCue: CoachingCue(text: cueText, timestamp: DateTime.now()),
        );
        _flutterTts.speak(cueText);
      } else if (jsonMessage['type'] == 'SIMULATION_COMPLETE') {
        stopRun();
      }
    }, onError: (error) {
      print('WebSocket Error: $error');
      stopRun();
    }, onDone: () {
      print('WebSocket Disconnected');
      stopRun();
    });

    // Start mock simulation or ghost race in the backend
    if (isGhostRace) {
      _channel!.sink.add(jsonEncode({"type": "START_GHOST", "ghostSessionId": "test_ghost_123"}));
      // In a real scenario, we'd start pushing real BLE telemetry here.
      // For now, let's also trigger the mock so we have data flowing.
      _channel!.sink.add(jsonEncode({"type": "START_MOCK"}));
    } else {
      _channel!.sink.add(jsonEncode({"type": "START_MOCK"}));
    }
  }

  void stopRun() {
    _channel?.sink.close();
    _channel = null;
    state = state.copyWith(isRunning: false);
  }
}

final liveCoachingProvider = NotifierProvider<LiveCoachingNotifier, LiveCoachingState>(() {
  return LiveCoachingNotifier();
});
