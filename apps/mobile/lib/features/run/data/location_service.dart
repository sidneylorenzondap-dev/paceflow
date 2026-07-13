import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class LocationState {
  final double totalDistanceKm;
  final double currentPaceSecondsPerKm; // derived from last few locations
  final Position? lastPosition;
  final bool isTracking;
  final int elapsedSeconds;

  LocationState({
    this.totalDistanceKm = 0.0,
    this.currentPaceSecondsPerKm = 0.0,
    this.lastPosition,
    this.isTracking = false,
    this.elapsedSeconds = 0,
  });

  LocationState copyWith({
    double? totalDistanceKm,
    double? currentPaceSecondsPerKm,
    Position? lastPosition,
    bool? isTracking,
    int? elapsedSeconds,
  }) {
    return LocationState(
      totalDistanceKm: totalDistanceKm ?? this.totalDistanceKm,
      currentPaceSecondsPerKm: currentPaceSecondsPerKm ?? this.currentPaceSecondsPerKm,
      lastPosition: lastPosition ?? this.lastPosition,
      isTracking: isTracking ?? this.isTracking,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
    );
  }
}

class LocationNotifier extends Notifier<LocationState> {
  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _timer;
  DateTime? _lastPositionTime;

  @override
  LocationState build() {
    return LocationState();
  }

  Future<void> startTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    state = state.copyWith(isTracking: true);
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // MOCK DATA for testing: simulate a 7:00 min/km pace
      final mockDistanceKm = state.totalDistanceKm + (1.0 / 420.0);
      state = state.copyWith(
        elapsedSeconds: state.elapsedSeconds + 1,
        totalDistanceKm: mockDistanceKm,
        currentPaceSecondsPerKm: 420.0,
      );
    });
    
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // minimum 5 meters before update
      ),
    ).listen((Position position) {
      if (state.lastPosition != null) {
        final distanceInMeters = Geolocator.distanceBetween(
          state.lastPosition!.latitude,
          state.lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );

        final newTotalDistanceKm = state.totalDistanceKm + (distanceInMeters / 1000);
        
        // Calculate instantaneous pace
        double newPace = state.currentPaceSecondsPerKm;
        if (_lastPositionTime != null && distanceInMeters > 0) {
          final timeDiffSeconds = position.timestamp.difference(_lastPositionTime!).inSeconds;
          // pace = time / distance
          newPace = timeDiffSeconds / (distanceInMeters / 1000);
        }

        state = state.copyWith(
          totalDistanceKm: newTotalDistanceKm,
          currentPaceSecondsPerKm: newPace,
          lastPosition: position,
        );
      } else {
        state = state.copyWith(lastPosition: position);
      }
      _lastPositionTime = position.timestamp;
    });
  }

  void stopTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(isTracking: false);
  }
}

final locationProvider = NotifierProvider<LocationNotifier, LocationState>(() {
  return LocationNotifier();
});
