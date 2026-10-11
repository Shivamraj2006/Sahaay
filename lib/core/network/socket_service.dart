import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../storage/secure_storage_service.dart';
import 'app_config.dart';

/// Socket event names defined in 00-shared-contract.md:
/// - emergency.created
/// - emergency.updated
/// - responder.accepted
/// - responder.arrived
/// - emergency.resolved
/// - emergency.cancelled
class SocketService {
  final SecureStorageService _storageService;
  io.Socket? _socket;
  final _eventController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  Stream<Map<String, dynamic>> get eventStream => _eventController.stream;
  Stream<bool> get connectionStream => _connectionStateController.stream;

  SocketService({required SecureStorageService storageService})
      : _storageService = storageService;

  Future<void> connect() async {
    if (_socket != null && _socket!.connected) return;

    final token = await _storageService.getToken();

    _socket = io.io(
      AppConfig.socketBaseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token ?? ''})
          .setExtraHeaders({'Authorization': 'Bearer ${token ?? ""}'})
          .enableReconnection()
          .setReconnectionDelay(2000)
          .setReconnectionAttempts(10)
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('[SocketIO] Connected to ${AppConfig.socketBaseUrl}');
      _isConnected = true;
      _connectionStateController.add(true);
    });

    _socket!.onDisconnect((_) {
      debugPrint('[SocketIO] Disconnected');
      _isConnected = false;
      _connectionStateController.add(false);
    });

    _socket!.onConnectError((err) {
      debugPrint('[SocketIO] Connect error: $err');
      _isConnected = false;
      _connectionStateController.add(false);
    });

    // Listen to canonical events
    final events = [
      'emergency.created',
      'emergency.updated',
      'responder.accepted',
      'responder.arrived',
      'emergency.resolved',
      'emergency.cancelled',
    ];

    for (final event in events) {
      _socket!.on(event, (data) {
        debugPrint('[SocketIO] Received $event: $data');
        if (data is Map<String, dynamic>) {
          _eventController.add({
            'eventName': event,
            'payload': data,
          });
        }
      });
    }

    _socket!.connect();
  }

  void joinEmergencyRoom(String emergencyId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('join', {'room': 'emergency:$emergencyId'});
    }
  }

  void leaveEmergencyRoom(String emergencyId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('leave', {'room': 'emergency:$emergencyId'});
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _connectionStateController.add(false);
  }

  void dispose() {
    disconnect();
    _eventController.close();
    _connectionStateController.close();
  }
}
