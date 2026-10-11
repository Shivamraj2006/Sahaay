import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/socket_service.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/elderly/models/emergency_model.dart';

class ResponderState {
  final bool isLoading;
  final bool isAvailable;
  final List<EmergencyModel> nearbyEmergencies;
  final EmergencyModel? assignedEmergency;
  final int completedAssistanceCount;
  final double reputationScore;
  final String? errorMessage;
  final String? actionSuccessMessage;

  ResponderState({
    this.isLoading = false,
    this.isAvailable = false,
    this.nearbyEmergencies = const [],
    this.assignedEmergency,
    this.completedAssistanceCount = 0,
    this.reputationScore = 5.0,
    this.errorMessage,
    this.actionSuccessMessage,
  });

  ResponderState copyWith({
    bool? isLoading,
    bool? isAvailable,
    List<EmergencyModel>? nearbyEmergencies,
    EmergencyModel? assignedEmergency,
    int? completedAssistanceCount,
    double? reputationScore,
    String? errorMessage,
    String? actionSuccessMessage,
    bool clearAssignedEmergency = false,
  }) {
    return ResponderState(
      isLoading: isLoading ?? this.isLoading,
      isAvailable: isAvailable ?? this.isAvailable,
      nearbyEmergencies: nearbyEmergencies ?? this.nearbyEmergencies,
      assignedEmergency: clearAssignedEmergency ? null : (assignedEmergency ?? this.assignedEmergency),
      completedAssistanceCount: completedAssistanceCount ?? this.completedAssistanceCount,
      reputationScore: reputationScore ?? this.reputationScore,
      errorMessage: errorMessage,
      actionSuccessMessage: actionSuccessMessage,
    );
  }
}

class ResponderNotifier extends StateNotifier<ResponderState> {
  final ApiClient _apiClient;
  final SocketService _socketService;
  StreamSubscription? _socketSubscription;

  ResponderNotifier(this._apiClient, this._socketService) : super(ResponderState()) {
    _listenToSocketEvents();
    loadProfileAndNearby();
  }

  void _listenToSocketEvents() {
    _socketSubscription = _socketService.eventStream.listen((event) {
      final eventName = event['eventName'] as String?;
      final payload = event['payload'] as Map<String, dynamic>?;

      // When nearby emergency created or cancelled, refresh list
      if (eventName == 'emergency.created' || eventName == 'emergency.cancelled') {
        fetchNearbyEmergencies();
      }

      // If active assigned emergency changed, refresh detail
      if (state.assignedEmergency != null) {
        final emergencyId = payload?['emergencyId'] as String?;
        if (emergencyId == state.assignedEmergency!.id || emergencyId == null) {
          fetchEmergencyById(state.assignedEmergency!.id);
        }
      }
    });
  }

  Future<void> loadProfileAndNearby() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      // 1. GET /responders/me
      final me = await _apiClient.get('/responders/me');
      final isAvail = me['available'] as bool? ?? me['isAvailable'] as bool? ?? false;
      final completed = me['completedCount'] as int? ?? me['completedAssistanceCount'] as int? ?? 0;
      final rep = (me['reputationScore'] as num?)?.toDouble() ?? 5.0;

      state = state.copyWith(
        isLoading: false,
        isAvailable: isAvail,
        completedAssistanceCount: completed,
        reputationScore: rep,
      );

      // 2. If available, fetch nearby emergencies
      if (isAvail) {
        await fetchNearbyEmergencies();
      }
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Toggle availability: PATCH /responders/me/availability { "available": true/false }
  Future<bool> toggleAvailability(bool newStatus) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _apiClient.patch(
        '/responders/me/availability',
        data: {'available': newStatus},
      );
      state = state.copyWith(isLoading: false, isAvailable: newStatus);

      if (newStatus) {
        await fetchNearbyEmergencies();
      } else {
        state = state.copyWith(nearbyEmergencies: []);
      }
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to update availability.');
      return false;
    }
  }

  /// GET /emergencies/nearby (returns coarse location & approximateDistanceMeters)
  Future<void> fetchNearbyEmergencies() async {
    try {
      final response = await _apiClient.get('/emergencies/nearby');
      final list = (response as List<dynamic>? ?? [])
          .map((item) => EmergencyModel.fromJson(item as Map<String, dynamic>))
          .toList();

      state = state.copyWith(nearbyEmergencies: list);
    } catch (_) {}
  }

  /// Accept an emergency: POST /emergencies/:id/accept
  /// Shared Contract: Server atomically assigns and only then provides exact location.
  /// If 409 Conflict, another responder won the race!
  Future<bool> acceptEmergency(String emergencyId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _apiClient.post('/emergencies/$emergencyId/accept');
      final assigned = EmergencyModel.fromJson(response as Map<String, dynamic>);

      _socketService.joinEmergencyRoom(emergencyId);
      state = state.copyWith(
        isLoading: false,
        assignedEmergency: assigned,
        actionSuccessMessage: 'Emergency assigned to you. Exact location unlocked.',
      );
      return true;
    } on ApiException catch (e) {
      // Handle race condition: 409 Conflict
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.code == 'EMERGENCY_ALREADY_ASSIGNED' || e.statusCode == 409
            ? 'This emergency was just accepted by another responder.'
            : e.message,
      );
      // Refresh nearby list
      await fetchNearbyEmergencies();
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Unable to accept emergency.');
      await fetchNearbyEmergencies();
      return false;
    }
  }

  /// Decline an emergency: POST /emergencies/:id/decline
  Future<void> declineEmergency(String emergencyId) async {
    try {
      await _apiClient.post('/emergencies/$emergencyId/decline');
      // Filter out from local list
      state = state.copyWith(
        nearbyEmergencies: state.nearbyEmergencies.where((e) => e.id != emergencyId).toList(),
      );
    } catch (_) {
      await fetchNearbyEmergencies();
    }
  }

  /// Mark arrived: POST /emergencies/:id/arrive
  Future<bool> markArrived(String emergencyId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _apiClient.post('/emergencies/$emergencyId/arrive');
      final updated = EmergencyModel.fromJson(response as Map<String, dynamic>);
      state = state.copyWith(
        isLoading: false,
        assignedEmergency: updated,
        actionSuccessMessage: 'Arrival recorded. Backend queued tamper-evident proof.',
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    }
  }

  /// Resolve emergency: POST /emergencies/:id/resolve
  /// Body: { "outcome": "ASSISTED", "note": "..." }
  Future<bool> resolveEmergency({
    required String emergencyId,
    required String outcome,
    String? note,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _apiClient.post(
        '/emergencies/$emergencyId/resolve',
        data: {
          'outcome': outcome,
          if (note != null && note.isNotEmpty) 'note': note,
        },
      );
      final updated = EmergencyModel.fromJson(response as Map<String, dynamic>);
      _socketService.leaveEmergencyRoom(emergencyId);

      state = state.copyWith(
        isLoading: false,
        assignedEmergency: updated,
        completedAssistanceCount: state.completedAssistanceCount + 1,
        actionSuccessMessage: 'Emergency resolved successfully.',
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    }
  }

  /// Escalate emergency: POST /emergencies/:id/escalate
  Future<bool> escalateEmergency(String emergencyId, String reason) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _apiClient.post(
        '/emergencies/$emergencyId/escalate',
        data: {'reason': reason},
      );
      final updated = EmergencyModel.fromJson(response as Map<String, dynamic>);
      state = state.copyWith(
        isLoading: false,
        assignedEmergency: updated,
        actionSuccessMessage: 'Emergency escalated. Secondary responders alerted.',
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    }
  }

  Future<void> fetchEmergencyById(String id) async {
    try {
      final response = await _apiClient.get('/emergencies/$id');
      final updated = EmergencyModel.fromJson(response as Map<String, dynamic>);
      state = state.copyWith(assignedEmergency: updated);
    } catch (_) {}
  }

  void clearAssigned() {
    state = state.copyWith(clearAssignedEmergency: true);
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    super.dispose();
  }
}

final responderProvider = StateNotifierProvider<ResponderNotifier, ResponderState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final socketService = ref.watch(socketServiceProvider);
  return ResponderNotifier(apiClient, socketService);
});
