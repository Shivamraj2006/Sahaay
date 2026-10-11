import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  /// Base host URL for the Express backend API and Socket.IO.
  /// Can be overridden at build time via:
  /// flutter build apk --dart-define=BACKEND_HOST=https://your-hosted-backend.com
  static const String _defaultHost = String.fromEnvironment(
    'BACKEND_HOST',
    defaultValue: 'http://localhost:3000',
  );

  static const String _prefKey = 'sahaay_backend_host';

  static String customHost = _defaultHost;

  static String get host {
    final clean = customHost.trim();
    return clean.endsWith('/') ? clean.substring(0, clean.length - 1) : clean;
  }

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

  /// Load persisted backend host from SharedPreferences (if previously changed by user)
  static Future<void> loadSavedHost() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved != null && saved.trim().isNotEmpty) {
        customHost = saved.trim();
        debugPrint('[CONFIG] Loaded saved backend host: $customHost');
      }
    } catch (e) {
      debugPrint('[CONFIG] Error loading saved backend host: $e');
    }
  }

  /// Update backend host and persist to SharedPreferences
  static Future<void> setHost(String newHost) async {
    String clean = newHost.trim();
    if (!clean.startsWith('http://') && !clean.startsWith('https://')) {
      clean = 'http://$clean';
    }
    if (clean.endsWith('/')) {
      clean = clean.substring(0, clean.length - 1);
    }
    customHost = clean;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, customHost);
      debugPrint('[CONFIG] Persisted backend host: $customHost');
    } catch (e) {
      debugPrint('[CONFIG] Error persisting backend host: $e');
    }
  }

  /// Test connectivity to a specific backend host candidate
  static Future<Map<String, dynamic>> testConnection(String candidateHost) async {
    String clean = candidateHost.trim();
    if (!clean.startsWith('http://') && !clean.startsWith('https://')) {
      clean = 'http://$clean';
    }
    if (clean.endsWith('/')) {
      clean = clean.substring(0, clean.length - 1);
    }

    final stopwatch = Stopwatch()..start();
    try {
      final url = Uri.parse('$clean/health');
      final res = await http.get(url).timeout(const Duration(seconds: 4));
      stopwatch.stop();

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return {
          'success': true,
          'latencyMs': stopwatch.elapsedMilliseconds,
          'database': data['database']?['connected'] ?? false,
          'blockchain': data['blockchain']?['mode'] ?? 'unknown',
        };
      } else {
        return {
          'success': false,
          'error': 'HTTP status ${res.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
