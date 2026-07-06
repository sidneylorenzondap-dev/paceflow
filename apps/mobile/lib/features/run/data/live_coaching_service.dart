import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TelemetryData {
  final int heartRate;
  final int cadence;
  final int gct;

  TelemetryData({this.heartRate = 0, this.cadence = 0, this.gct = 0});

  factory TelemetryData.fromJson(Map<String, dynamic> json) {
    return TelemetryData(
      heartRate: json['heartRate'] ?? 0,
      cadence: json['cadence'] ?? 0,
      gct: json['gct'] ?? 0,
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
    
    // Connect to local Node.js backend (use 10.0.2.2 for Android emulator if needed, localhost for Chrome)
    const wsUrl = 'ws://localhost:3000/api/v1/live-coaching';
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

    _channel!.stream.listen((message) {
      final data = jsonDecode(message);
      
      if (data['type'] == 'TELEMETRY_UPDATE') {
        state = state.copyWith(
          telemetry: TelemetryData.fromJson(data['data']),
        );
      } else if (data['action'] == 'PLAY_TTS') {
        final cueText = data['text'] as String;
        state = state.copyWith(
          latestCue: CoachingCue(text: cueText, timestamp: DateTime.now()),
        );
        _flutterTts.speak(cueText);
      } else if (data['type'] == 'SIMULATION_COMPLETE') {
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
