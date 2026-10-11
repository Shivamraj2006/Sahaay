import 'dart:async';
import 'package:flutter/material.dart';
import '../models/emergency.dart';
import '../services/emergency_service.dart';

class EmergencyProvider extends ChangeNotifier {
  EmergencyModel? _emergency;
  bool _isCountingDown = false;
  int _countdownSeconds = 3;
  Timer? _countdownTimer;
  EmergencyCategory _pendingCategory = EmergencyCategory.medical;
  bool _isLoading = false;

  EmergencyModel? get emergency => _emergency;
  bool get isCountingDown => _isCountingDown;
  int get countdownSeconds => _countdownSeconds;
  EmergencyCategory get pendingCategory => _pendingCategory;
  bool get isLoading => _isLoading;
  bool get hasActiveEmergency =>
      _emergency != null && _emergency!.status.isActiveOrAssigned;

  /// Start 3-second countdown modal
  void startCountdown({
    EmergencyCategory category = EmergencyCategory.medical,
    required VoidCallback onComplete,
  }) {
    _pendingCategory = category;
    _countdownSeconds = 3;
    _isCountingDown = true;
    notifyListeners();

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 1) {
        _countdownSeconds--;
        notifyListeners();
      } else {
        timer.cancel();
        _isCountingDown = false;
        notifyListeners();
        // Trigger emergency creation and callback
        sendSos(onComplete: onComplete);
      }
    });
  }

  void cancelCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _isCountingDown = false;
    _countdownSeconds = 3;
    notifyListeners();
  }

  Future<void> sendSos({VoidCallback? onComplete}) async {
    _isLoading = true;
    notifyListeners();
    try {
      _emergency = await emergencyService.createEmergency(
        category: _pendingCategory,
      );
      onComplete?.call();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cancelEmergency() async {
    if (_emergency == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      _emergency = await emergencyService.cancelEmergency(_emergency!.id);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Simulate arrival of responder for interactive testing
  Future<void> simulateAcceptAndArrive() async {
    if (_emergency == null) return;
    await emergencyService.acceptEmergency(_emergency!.id);
    _emergency = emergencyService.currentEmergency;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));
    await emergencyService.markArrived(_emergency!.id);
    _emergency = emergencyService.currentEmergency;
    notifyListeners();
  }

  Future<void> simulateResolution(String outcome) async {
    if (_emergency == null) return;
    await emergencyService.resolveEmergency(_emergency!.id, outcome);
    _emergency = emergencyService.currentEmergency;
    notifyListeners();
  }

  void reset() {
    emergencyService.clearCurrent();
    _emergency = null;
    _isCountingDown = false;
    _countdownSeconds = 3;
    notifyListeners();
  }
}
