import 'package:flutter/foundation.dart';

class AppConfig {
  /// Base host URL for the Express backend API and Socket.IO.
  /// Can be overridden at build time via:
  /// flutter run --dart-define=BACKEND_HOST=https://your-hosted-backend.com
  static const String _defaultHost = String.fromEnvironment(
    'BACKEND_HOST',
    defaultValue: 'http://localhost:3000',
  );

  static String customHost = _defaultHost;

  static String get host => customHost.endsWith('/')
      ? customHost.substring(0, customHost.length - 1)
      : customHost;

  /// Base URL for the Express backend API.
  static String get apiBaseUrl => '$host/api/v1';

  /// Socket.IO URL
  static String get socketUrl => host;

  /// Timeout for API requests in seconds.
  static const int apiTimeoutSeconds = 10;

  /// Default mock coordinates for elderly testing (Koramangala, Bengaluru).
  static const double defaultElderlyLat = 12.9352;
  static const double defaultElderlyLng = 77.6245;

  /// Default mock coordinates for responder testing (~350m away).
  static const double defaultResponderLat = 12.9378;
  static const double defaultResponderLng = 77.6268;
}
