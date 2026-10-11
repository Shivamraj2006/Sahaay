import '../models/emergency.dart';
import '../config/app_config.dart';
import 'api_client.dart';

class EmergencyService {
  EmergencyModel? _currentEmergency;
  EmergencyModel? get currentEmergency => _currentEmergency;

  Future<EmergencyModel> createEmergency({
    required EmergencyCategory category,
    LatLngCoordinates? location,
    String? notes,
  }) async {
    final loc = location ??
        const LatLngCoordinates(
          latitude: AppConfig.defaultElderlyLat,
          longitude: AppConfig.defaultElderlyLng,
        );

    try {
      final res = await apiClient.post(
        '/emergencies',
        body: {
          'category': category.value,
          'location': loc.toJson(),
          'notes': notes ?? 'SOS triggered via mobile app',
        },
      );
      _currentEmergency = EmergencyModel.fromJson(res);
      return _currentEmergency!;
    } catch (e) {
      // Offline fallback: simulated local emergency
      final id = 'emg_${DateTime.now().millisecondsSinceEpoch}';
      _currentEmergency = EmergencyModel(
        id: id,
        ownerId: 'owner_123',
        ownerName: 'Kamla Devi',
        category: category,
        status: EmergencyStatus.active,
        location: loc,
        notes: notes ?? 'SOS triggered via mobile app',
        proofStatus: ProofStatus.notSubmitted,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      return _currentEmergency!;
    }
  }

  Future<EmergencyModel?> cancelEmergency(String id) async {
    try {
      final res = await apiClient.post('/emergencies/$id/cancel');
      _currentEmergency = EmergencyModel.fromJson(res);
      return _currentEmergency;
    } catch (e) {
      if (_currentEmergency != null) {
        _currentEmergency = EmergencyModel(
          id: _currentEmergency!.id,
          ownerId: _currentEmergency!.ownerId,
          ownerName: _currentEmergency!.ownerName,
          category: _currentEmergency!.category,
          status: EmergencyStatus.cancelled,
          location: _currentEmergency!.location,
          createdAt: _currentEmergency!.createdAt,
          updatedAt: DateTime.now(),
        );
      }
      return _currentEmergency;
    }
  }

  Future<EmergencyModel?> acceptEmergency(String id) async {
    try {
      final res = await apiClient.post('/emergencies/$id/accept');
      _currentEmergency = EmergencyModel.fromJson(res);
      return _currentEmergency;
    } catch (e) {
      if (_currentEmergency != null) {
        _currentEmergency = EmergencyModel(
          id: _currentEmergency!.id,
          ownerId: _currentEmergency!.ownerId,
          ownerName: _currentEmergency!.ownerName,
          category: _currentEmergency!.category,
          status: EmergencyStatus.assigned,
          location: _currentEmergency!.location,
          assignedResponder: const AssignedResponder(
            id: 'resp_rahul',
            displayName: 'Rahul Sharma',
            phone: '+91 98765 43211',
            role: 'VOLUNTEER',
          ),
          createdAt: _currentEmergency!.createdAt,
          updatedAt: DateTime.now(),
        );
      }
      return _currentEmergency;
    }
  }

  Future<EmergencyModel?> markArrived(String id) async {
    try {
      final res = await apiClient.post('/emergencies/$id/arrive');
      _currentEmergency = EmergencyModel.fromJson(res);
      return _currentEmergency;
    } catch (e) {
      if (_currentEmergency != null) {
        _currentEmergency = EmergencyModel(
          id: _currentEmergency!.id,
          ownerId: _currentEmergency!.ownerId,
          ownerName: _currentEmergency!.ownerName,
          category: _currentEmergency!.category,
          status: EmergencyStatus.responderArrived,
          location: _currentEmergency!.location,
          assignedResponder: _currentEmergency!.assignedResponder,
          proofStatus: ProofStatus.pending,
          createdAt: _currentEmergency!.createdAt,
          updatedAt: DateTime.now(),
        );
      }
      return _currentEmergency;
    }
  }

  Future<EmergencyModel?> resolveEmergency(String id, String outcome) async {
    try {
      final res = await apiClient.post(
        '/emergencies/$id/resolve',
        body: {'outcome': outcome, 'note': 'Assisted on scene'},
      );
      _currentEmergency = EmergencyModel.fromJson(res);
      return _currentEmergency;
    } catch (e) {
      if (_currentEmergency != null) {
        _currentEmergency = EmergencyModel(
          id: _currentEmergency!.id,
          ownerId: _currentEmergency!.ownerId,
          ownerName: _currentEmergency!.ownerName,
          category: _currentEmergency!.category,
          status: EmergencyStatus.resolved,
          location: _currentEmergency!.location,
          assignedResponder: _currentEmergency!.assignedResponder,
          proofStatus: ProofStatus.confirmed,
          transactionHash: '0x8f2a1b9c3d4e5f60718293a4b5c6d7e8f90123456789abcdef0123456789abcd',
          createdAt: _currentEmergency!.createdAt,
          updatedAt: DateTime.now(),
        );
      }
      return _currentEmergency;
    }
  }

  void clearCurrent() {
    _currentEmergency = null;
  }
}

final emergencyService = EmergencyService();
