import 'package:health/health.dart';
import 'package:flutter/foundation.dart';

class HealthSyncService {
  final Health _health = Health();

  // Define the types we care about for PaceFlow
  final types = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.DISTANCE_WALKING_RUNNING,
  ];

  /// Request permissions from Android Health Connect or Apple HealthKit
  Future<bool> requestPermissions() async {
    final permissions = types.map((e) => HealthDataAccess.READ).toList();
    
    // Check if we already have permissions
    bool? hasPermissions = await _health.hasPermissions(types, permissions: permissions);
    if (hasPermissions == true) {
      return true;
    }

    try {
      bool authorized = await _health.requestAuthorization(types, permissions: permissions);
      return authorized;
    } catch (e) {
      debugPrint("Exception in requestPermissions: $e");
      return false;
    }
  }

  /// Pull the last 30 days of workouts (Historical Sync)
  Future<List<HealthDataPoint>> fetchLast30DaysData() async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    try {
      List<HealthDataPoint> healthData = await _health.getHealthDataFromTypes(
        startTime: thirtyDaysAgo,
        endTime: now,
        types: types,
      );

      // Filter out duplicates
      healthData = Health().removeDuplicates(healthData);
      
      debugPrint("Successfully fetched ${healthData.length} data points from Health SDK.");
      return healthData;
    } catch (e) {
      debugPrint("Exception in fetchLast30DaysData: $e");
      return [];
    }
  }
}
