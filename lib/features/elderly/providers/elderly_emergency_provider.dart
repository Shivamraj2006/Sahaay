import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/location_service.dart';
import '../../core/network/socket_service.dart';
import '../models/emergency_model.dart';
import '../../auth/providers/auth_provider.dart';

class ElderlyEmergencyState {
  final bool isLoading;
  final EmergencyModel? activeEmergency;
  final int countdownSeconds;
  final bool isCountingDown;
  final String? errorMessage;
  final List<EmergencyModel> pastEmergencies;

  ElderlyEmergencyState({
    this.isLoading = false,
    this.activeEmergency,
    this.countdownSeconds = 5,
    this.isCountingDown = false,
    this.errorMessage,
    this.pastEmergencies = const [],
  });

  ElderlyEmergencyState copyWith({
    bool? isLoading,
    EmergencyModel? activeEmergency,
    int? countdownSeconds,
    bool? isCountingDown,
    String? errorMessage,
    List<EmergencyModel>? pastEmergencies,
    bool clearActiveEmergency = false,
  }) {
    return ElderlyEmergencyState(
      isLoading: isLoading ?? this.isLoading,
      activeEmergency: clearActiveEmergency ? null : (activeEmergency ?? this.activeEmergency),
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      isCountingDown: isCountingDown ?? this.isCountingDown,
      errorMessage: errorMessage,
      pastEmergencies: pastEmergencies ?? this.pastEmergencies,
    );
  }
}

class ElderlyEmergencyNotifier extends StateNotifier<ElderlyEmergencyState> {
  final ApiClient _apiClient;
  final SocketService _socketService;
  Timer? _countdownTimer;
  StreamSubscription? _socketSubscription;

  ElderlyEmergencyNotifier(this._apiClient, this._socketService) : super(ElderlyEmergencyState()) {
    _listenToSocketEvents();
  }

  void _listenToSocketEvents() {
    _socketSubscription = _socketService.eventStream.listen((event) {
      final payload = event['payload'] as Map<String, dynamic>?;
      final data = payload?['data'] as Map<String, dynamic>? ?? payload;
      final emergencyId = payload?['emergencyId'] as String? ?? data?['id'] as String?;

      if (state.activeEmergency != null &&
          (state.activeEmergency!.id == emergencyId || emergencyId == null)) {
        // Shared Contract rule: Refetch emergency from server as authoritative source of truth
        fetchEmergencyById(state.activeEmergency!.id);
      }
    });
  }

  /// Step 1: User initiates SOS with chosen Category
  /// Immediately creates emergency as ACTIVE on server (Section 6 recommendation:
  /// "create immediately so backend can begin auditable flow, then allow cancellation")
  Future<bool> initiateSos({
    required EmergencyCategory category,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // 1. Get GPS coordinates
      final position = await LocationService.getCurrentPosition();
      final double lat = position?.latitude ?? 21.1458; // Fallback demo default (Nagpur/India)
      final double lng = position?.longitude ?? 79.0882;

      // 2. Call POST /emergencies
      final response = await _apiClient.post(
        '/emergencies',
        data: {
          'category': category.value,
          'location': {
            'latitude': lat,
            'longitude': lng,
          },
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );

      final createdEmergency = EmergencyModel.fromJson(response as Map<String, dynamic>);
      _socketService.joinEmergencyRoom(createdEmergency.id);

      state = state.copyWith(
        isLoading: false,
        activeEmergency: createdEmergency,
        countdownSeconds: 5,
        isCountingDown: true,
      );

      _startCancellationCountdown();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to broadcast SOS. Please call 112 directly if in immediate danger.',
      );
      return false;
    }
  }

  void _startCancellationCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.countdownSeconds > 1) {
        state = state.copyWith(countdownSeconds: state.countdownSeconds - 1);
      } else {
        _countdownTimer?.cancel();
        state = state.copyWith(isCountingDown: false, countdownSeconds: 0);
      }
    });
  }

  /// Step 2: Cancel SOS
  /// Calls POST /emergencies/:id/cancel
  Future<bool> cancelEmergency() async {
    final emergency = state.activeEmergency;
    if (emergency == null) return false;

    _countdownTimer?.cancel();
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await _apiClient.post('/emergencies/${emergency.id}/cancel');
      final updated = EmergencyModel.fromJson(response as Map<String, dynamic>);

      _socketService.leaveEmergencyRoom(emergency.id);
      state = state.copyWith(
        isLoading: false,
        isCountingDown: false,
        activeEmergency: updated,
      );
      return true;
    } on ApiException catch (e) {
      // Server returned conflict (e.g. responder already assigned)
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      await fetchEmergencyById(emergency.id);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to cancel alert.');
      return false;
    }
  }

  /// Step 3: Fetch emergency details (authoritative update)
  Future<void> fetchEmergencyById(String id) async {
    try {
      final response = await _apiClient.get('/emergencies/$id');
      final updated = EmergencyModel.fromJson(response as Map<String, dynamic>);
      state = state.copyWith(activeEmergency: updated);
    } catch (_) {}
  }

  /// Request escalation (calls POST /emergencies/:id/escalate)
  Future<bool> escalateEmergency(String reason) async {
    final emergency = state.activeEmergency;
    if (emergency == null) return false;

    try {
      final response = await _apiClient.post(
        '/emergencies/${emergency.id}/escalate',
        data: {'reason': reason},
      );
      final updated = EmergencyModel.fromJson(response as Map<String, dynamic>);
      state = state.copyWith(activeEmergency: updated);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      return false;
    }
  }

  void resetActiveEmergency() {
    _countdownTimer?.cancel();
    if (state.activeEmergency != null) {
      _socketService.leaveEmergencyRoom(state.activeEmergency!.id);
    }
    state = state.copyWith(clearActiveEmergency: true, isCountingDown: false);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _socketSubscription?.cancel();
    super.dispose();
  }
}

final elderlyEmergencyProvider =
    StateNotifierProvider<ElderlyEmergencyNotifier, ElderlyEmergencyState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final socketService = ref.watch(socketServiceProvider);
  return ElderlyEmergencyNotifier(apiClient, socketService);
});
