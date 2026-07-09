import 'package:flutter/foundation.dart';

class ApiConstants {
  static String get baseUrl {
    if (kReleaseMode) {
      return 'https://paceflow-node.onrender.com/api/v1';
    } else {
      return 'http://localhost:3000/api/v1'; // Local testing
    }
  }

  static String get wsBaseUrl {
    if (kReleaseMode) {
      return 'wss://paceflow-node.onrender.com/api/v1';
    } else {
      return 'ws://localhost:3000/api/v1'; // Local testing
    }
  }
}
