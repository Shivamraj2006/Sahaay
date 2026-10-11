import 'dart:async';
import 'package:flutter/material.dart';
import '../models/emergency.dart';
import '../services/emergency_service.dart';
import '../services/socket_service.dart';

class EmergencyProvider extends ChangeNotifier {
  EmergencyModel? _emergency;
  List<EmergencyModel> _nearbyEmergencies = [];
  bool _isCountingDown = false;
  int _countdownSeconds = 3;
  Timer? _countdownTimer;
  EmergencyCategory _pendingCategory = EmergencyCategory.medical;
  bool _isLoading = false;

  final List<StreamSubscription> _subscriptions = [];

  EmergencyModel? get emergency => _emergency;
  List<EmergencyModel> get nearbyEmergencies => _nearbyEmergencies;
  bool get isCountingDown => _isCountingDown;
  int get countdownSeconds => _countdownSeconds;
  EmergencyCategory get pendingCategory => _pendingCategory;
  bool get isLoading => _isLoading;
  bool get hasActiveEmergency =>
      _emergency != null && _emergency!.status.isActiveOrAssigned;

  EmergencyProvider() {
    _initSocketListeners();
  }

  void _initSocketListeners() {
    _subscriptions.add(
      socketService.onEmergencyCreated.listen((payload) {
        final data = payload['data'] as Map<String, dynamic>?;
        final emergencyId = payload['emergencyId'] ?? '';
        final newEmg = EmergencyModel(
          id: emergencyId,
          ownerId: '',
          ownerName: 'Senior Resident',
          category: EmergencyCategory.fromString(data?['category'] ?? 'MEDICAL'),
          status: EmergencyStatus.fromString(data?['status'] ?? 'ACTIVE'),
          location: data?['location'] != null
              ? LatLngCoordinates.fromJson(data!['location'])
              : const LatLngCoordinates(latitude: 12.9352, longitude: 77.6245),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final idx = _nearbyEmergencies.indexWhere((e) => e.id == emergencyId);
        if (idx == -1) {
          _nearbyEmergencies.insert(0, newEmg);
        } else {
          _nearbyEmergencies[idx] = newEmg;
        }

        if (_emergency == null) {
          _emergency = newEmg;
        }
        notifyListeners();
      }),
    );

    _subscriptions.add(
      socketService.onResponderAccepted.listen((payload) {
        final emergencyId = payload['emergencyId'];
        if (_emergency != null && _emergency!.id == emergencyId) {
          final respData = payload['data']?['assignedResponder'] as Map<String, dynamic>? ??
              payload['assignedResponder'] as Map<String, dynamic>?;
          _emergency = _emergency!.copyWith(
            status: EmergencyStatus.assigned,
            assignedResponder: AssignedResponder(
              id: respData?['id'] ?? 'resp_online',
              displayName: respData?['displayName'] ?? 'Verified Volunteer',
              phone: respData?['phone'] ?? '+919876543211',
              role: respData?['role'] ?? 'VOLUNTEER',
            ),
          );
          notifyListeners();
        }
      }),
    );

    _subscriptions.add(
      socketService.onResponderArrived.listen((payload) {
        final emergencyId = payload['emergencyId'];
        if (_emergency != null && _emergency!.id == emergencyId) {
          _emergency = _emergency!.copyWith(
            status: EmergencyStatus.responderArrived,
            proofStatus: ProofStatus.pending,
          );
          notifyListeners();
        }
      }),
    );

    _subscriptions.add(
      socketService.onEmergencyResolved.listen((payload) {
        final emergencyId = payload['emergencyId'];
        _nearbyEmergencies.removeWhere((e) => e.id == emergencyId);
        if (_emergency != null && _emergency!.id == emergencyId) {
          _emergency = _emergency!.copyWith(
            status: EmergencyStatus.resolved,
            proofStatus: ProofStatus.confirmed,
          );
          notifyListeners();
        }
      }),
    );

    _subscriptions.add(
      socketService.onEmergencyCancelled.listen((payload) {
        final emergencyId = payload['emergencyId'];
        _nearbyEmergencies.removeWhere((e) => e.id == emergencyId);
        if (_emergency != null && _emergency!.id == emergencyId) {
          _emergency = _emergency!.copyWith(
            status: EmergencyStatus.cancelled,
          );
          notifyListeners();
        }
      }),
    );
  }

  Future<void> fetchNearbyEmergencies() async {
    _isLoading = true;
    notifyListeners();
    try {
      _nearbyEmergencies = await emergencyService.getNearbyEmergencies();
    } catch (e) {
      debugPrint('[EMERGENCY_PROVIDER] fetchNearbyEmergencies error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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
      if (_emergency != null) {
        socketService.joinEmergency(_emergency!.id);
      }
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

  Future<void> acceptEmergency(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      _emergency = await emergencyService.acceptEmergency(id);
      socketService.joinEmergency(id);
      _nearbyEmergencies.removeWhere((e) => e.id == id);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markArrived() async {
    if (_emergency == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      _emergency = await emergencyService.markArrived(_emergency!.id);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resolveEmergency(String outcome) async {
    if (_emergency == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      _emergency = await emergencyService.resolveEmergency(_emergency!.id, outcome);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Simulate arrival of responder for interactive testing
  Future<void> simulateAcceptAndArrive() async {
    if (_emergency == null) return;
    await emergencyService.acceptEmergency(_emergency!.id);
    socketService.joinEmergency(_emergency!.id);
    _emergency = emergencyService.currentEmergency;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));
    await emergencyService.markArrived(_emergency!.id);
    _emergency = emergencyService.currentEmergency;
    notifyListeners();
  }

  Future<void> simulateResolution(String outcome) async {
    await resolveEmergency(outcome);
  }

  void reset() {
    emergencyService.clearCurrent();
    _emergency = null;
    _isCountingDown = false;
    _countdownSeconds = 3;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _countdownTimer?.cancel();
    super.dispose();
  }
}
