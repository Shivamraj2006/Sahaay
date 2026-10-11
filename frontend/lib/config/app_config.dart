import 'package:flutter/foundation.dart';

class AppConfig {
  /// Base URL for the Express backend API.
  /// For Android emulator, use 10.0.2.2; for web and desktop, use localhost.
  static String get apiBaseUrl {
    if (kIsWeb) return 'http://localhost:3000/api/v1';
    // When running in Android emulator:
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:3000/api/v1'
        : 'http://localhost:3000/api/v1';
  }

  /// Socket.IO URL
  static String get socketUrl {
    if (kIsWeb) return 'http://localhost:3000';
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:3000'
        : 'http://localhost:3000';
  }

  /// Timeout for API requests in seconds.
  static const int apiTimeoutSeconds = 8;

  /// Default mock coordinates for elderly testing (Koramangala, Bengaluru).
  static const double defaultElderlyLat = 12.9352;
  static const double defaultElderlyLng = 77.6245;

  /// Default mock coordinates for responder testing (~350m away).
  static const double defaultResponderLat = 12.9378;
  static const double defaultResponderLng = 77.6268;
}
