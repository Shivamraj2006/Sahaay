import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../config/app_config.dart';
import '../models/emergency.dart';

enum LocationState {
  unknown,
  requesting,
  active,
  disabled,
  denied,
  deniedForever,
  error,
}

class LocationService extends ChangeNotifier {
  LocationState _state = LocationState.unknown;
  LatLngCoordinates? _lastCoords;
  String _statusText = 'GPS initializing...';

  LocationState get state => _state;
  LatLngCoordinates? get lastCoords => _lastCoords;
  String get statusText => _statusText;
  bool get hasGpsFix => _lastCoords != null && _state == LocationState.active;

  /// Proactively request location permissions from Android OS dialog.
  Future<bool> requestPermission() async {
    try {
      _state = LocationState.requesting;
      _statusText = 'Requesting location permission...';
      notifyListeners();

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _state = LocationState.denied;
        _statusText = 'Location permission denied. Using fallback test coordinates.';
        notifyListeners();
        return false;
      }

      if (permission == LocationPermission.deniedForever) {
        _state = LocationState.deniedForever;
        _statusText = 'Location permanently denied. Enable in device settings.';
        notifyListeners();
        return false;
      }

      // Check if hardware location service (GPS) is turned on
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _state = LocationState.disabled;
        _statusText = 'GPS service disabled on device. Using fallback test coordinates.';
        notifyListeners();
        return false;
      }

      // Fetch initial position
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );

      _lastCoords = LatLngCoordinates(
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
      _state = LocationState.active;
      _statusText =
          'Real GPS Active (${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)})';
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[LOCATION] Exception in requestPermission: $e');
      _state = LocationState.error;
      _statusText = 'Using fallback test coordinates ($e)';
      notifyListeners();
      return false;
    }
  }

  /// Request GPS permission and fetch current device coordinates.
  /// Falls back to configured default coordinates if permission is denied,
  /// services are unavailable, or timeout occurs.
  Future<LatLngCoordinates> getCurrentLocation({
    double fallbackLat = AppConfig.defaultElderlyLat,
    double fallbackLng = AppConfig.defaultElderlyLng,
  }) async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('[LOCATION] Location permission denied by user.');
          _state = LocationState.denied;
          notifyListeners();
          return LatLngCoordinates(latitude: fallbackLat, longitude: fallbackLng);
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('[LOCATION] Location permission permanently denied.');
        _state = LocationState.deniedForever;
        notifyListeners();
        return LatLngCoordinates(latitude: fallbackLat, longitude: fallbackLng);
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[LOCATION] Device location service is disabled, using fallback.');
        _state = LocationState.disabled;
        notifyListeners();
        return LatLngCoordinates(latitude: fallbackLat, longitude: fallbackLng);
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );

      _lastCoords = LatLngCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      _state = LocationState.active;
      _statusText =
          'Real GPS Active (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
      notifyListeners();

      return _lastCoords!;
    } catch (e) {
      debugPrint('[LOCATION] Error acquiring location: $e. Using fallback.');
      return LatLngCoordinates(latitude: fallbackLat, longitude: fallbackLng);
    }
  }

  Future<void> openSettings() async {
    await Geolocator.openAppSettings();
  }

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }
}

final locationService = LocationService();
