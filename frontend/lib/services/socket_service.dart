import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/app_config.dart';

class SocketService {
  IO.Socket? _socket;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  final _emergencyCreatedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _emergencyUpdatedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _responderAcceptedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _responderArrivedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _emergencyResolvedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _emergencyCancelledController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onEmergencyCreated =>
      _emergencyCreatedController.stream;
  Stream<Map<String, dynamic>> get onEmergencyUpdated =>
      _emergencyUpdatedController.stream;
  Stream<Map<String, dynamic>> get onResponderAccepted =>
      _responderAcceptedController.stream;
  Stream<Map<String, dynamic>> get onResponderArrived =>
      _responderArrivedController.stream;
  Stream<Map<String, dynamic>> get onEmergencyResolved =>
      _emergencyResolvedController.stream;
  Stream<Map<String, dynamic>> get onEmergencyCancelled =>
      _emergencyCancelledController.stream;

  bool enabled = true;

  void connect(String token) {
    if (!enabled) return;
    if (_socket != null && _isConnected) return;

    try {
      _socket = IO.io(
        AppConfig.socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .setAuth({'token': token})
            .setExtraHeaders({'Authorization': 'Bearer $token'})
            .enableAutoConnect()
            .enableReconnection()
            .build(),
      );

      _socket!.onConnect((_) {
        _isConnected = true;
        debugPrint('[SOCKET] Connected to Sahaay real-time gateway');
      });

      _socket!.onDisconnect((_) {
        _isConnected = false;
        debugPrint('[SOCKET] Disconnected from gateway');
      });

      _socket!.onConnectError((err) {
        _isConnected = false;
        debugPrint('[SOCKET] Connection error: $err');
      });

      _socket!.on('emergency.created', (data) {
        if (data is Map) {
          _emergencyCreatedController.add(Map<String, dynamic>.from(data));
        }
      });

      _socket!.on('emergency.updated', (data) {
        if (data is Map) {
          _emergencyUpdatedController.add(Map<String, dynamic>.from(data));
        }
      });

      _socket!.on('responder.accepted', (data) {
        if (data is Map) {
          _responderAcceptedController.add(Map<String, dynamic>.from(data));
        }
      });

      _socket!.on('responder.arrived', (data) {
        if (data is Map) {
          _responderArrivedController.add(Map<String, dynamic>.from(data));
        }
      });

      _socket!.on('emergency.resolved', (data) {
        if (data is Map) {
          _emergencyResolvedController.add(Map<String, dynamic>.from(data));
        }
      });

      _socket!.on('emergency.cancelled', (data) {
        if (data is Map) {
          _emergencyCancelledController.add(Map<String, dynamic>.from(data));
        }
      });
    } catch (e) {
      debugPrint('[SOCKET] Failed to init socket: $e');
    }
  }

  void joinEmergency(String emergencyId) {
    if (_socket != null) {
      _socket!.emit('join:emergency', emergencyId);
    }
  }

  void disconnect() {
    try {
      _socket?.disconnect();
      _socket?.dispose();
    } catch (_) {}
    _socket = null;
    _isConnected = false;
  }
}

final socketService = SocketService();
