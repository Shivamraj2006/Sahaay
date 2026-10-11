import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/emergency.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/emergency_provider.dart';
import '../../services/emergency_service.dart';
import '../../services/location_service.dart';
import 'assigned_mission_screen.dart';

class ResponderHomeScreen extends StatefulWidget {
  const ResponderHomeScreen({super.key});

  @override
  State<ResponderHomeScreen> createState() => _ResponderHomeScreenState();
}

class _ResponderHomeScreenState extends State<ResponderHomeScreen> {
  bool _isAvailable = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initResponderSession();
    });
  }

  Future<void> _initResponderSession() async {
    // 1. Proactively request GPS permission and acquire device fix
    final loc = await locationService.getCurrentLocation();
    // 2. Update responder profile availability and coordinates in backend
    await emergencyService.updateAvailability(_isAvailable, location: loc);
    // 3. Fetch nearby open emergencies within 3 km
    if (mounted) {
      await context.read<EmergencyProvider>().fetchNearbyEmergencies();
    }
  }

  Future<void> _refreshRadar() async {
    final loc = await locationService.getCurrentLocation();
    await emergencyService.updateAvailability(_isAvailable, location: loc);
    if (mounted) {
      await context.read<EmergencyProvider>().fetchNearbyEmergencies();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final emergencyProvider = context.watch<EmergencyProvider>();
    final currentEmg = emergencyProvider.emergency;

    // If responder has an active assigned mission, show mission screen
    if (currentEmg != null &&
        (currentEmg.status == EmergencyStatus.assigned ||
            currentEmg.status == EmergencyStatus.responderArrived)) {
      return AssignedMissionScreen(
        emergency: currentEmg,
        onComplete: () {
          emergencyProvider.reset();
        },
      );
    }

    // Merge nearby list with active emergency if any
    final allNearby = List<EmergencyModel>.from(emergencyProvider.nearbyEmergencies);
    if (currentEmg != null &&
        currentEmg.status == EmergencyStatus.active &&
        !allNearby.any((e) => e.id == currentEmg.id)) {
      allNearby.insert(0, currentEmg);
    }

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        title: const Text('Responder Portal'),
        actions: [
          IconButton(
            tooltip: 'Refresh Radar',
            icon: const Icon(Icons.refresh),
            onPressed: _refreshRadar,
          ),
          IconButton(
            tooltip: 'Switch to Senior Citizen (Victim)',
            icon: const Icon(Icons.swap_horiz),
            onPressed: () {
              auth.switchRole(UserRole.elderlyUser);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshRadar,
          color: AppColors.brandBlue,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Responder Profile & Verification Badge
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(
                          color: AppColors.brandBlueLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.medical_services,
                          color: AppColors.brandBlue,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (auth.user?.displayName.isNotEmpty == true)
                                  ? auth.user!.displayName
                                  : 'Community Responder',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppColors.slate900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.brandSuccessLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.verified,
                                        color: AppColors.brandSuccess,
                                        size: 13,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'VERIFIED (On-Chain)',
                                        style: TextStyle(
                                          color: AppColors.brandSuccess,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // GPS Location Status Chip
                ListenableBuilder(
                  listenable: locationService,
                  builder: (context, _) {
                    final hasGps = locationService.state == LocationState.active;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: hasGps ? AppColors.brandSuccessLight : AppColors.amber50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: hasGps ? AppColors.brandSuccess : AppColors.amber200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            hasGps ? Icons.location_on : Icons.location_searching,
                            color: hasGps ? AppColors.brandSuccess : AppColors.amber700,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              locationService.statusText,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: hasGps ? AppColors.brandSuccess : AppColors.amber900,
                              ),
                            ),
                          ),
                          if (!hasGps)
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () => locationService.requestPermission(),
                              child: const Text(
                                'Grant GPS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.brandBlue,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                // Availability Switch Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Duty Availability',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.slate900,
                              ),
                            ),
                            Text(
                              _isAvailable
                                  ? 'Receiving nearby emergency alerts'
                                  : 'Currently offline for dispatch',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.slate500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: _isAvailable,
                        activeColor: AppColors.brandSuccess,
                        onChanged: (val) async {
                          setState(() {
                            _isAvailable = val;
                          });
                          final loc = await locationService.getCurrentLocation();
                          await emergencyService.updateAvailability(val, location: loc);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Nearby Emergencies Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Nearby Incidents (< 3 km)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.slate900,
                        ),
                      ),
                    ),
                    if (emergencyProvider.isLoading)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.brandBlue,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Active Incident Feed
                if (allNearby.isNotEmpty)
                  Column(
                    children: allNearby
                        .map((emg) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _buildNearbyIncidentCard(
                                context,
                                emg,
                                emergencyProvider,
                              ),
                            ))
                        .toList(),
                  )
                else
                  _buildNoIncidentsPlaceholder(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNearbyIncidentCard(
    BuildContext context,
    EmergencyModel emg,
    EmergencyProvider provider,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.brandRedSoft, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandRed.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.rose50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: AppColors.brandRed, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      emg.category.label,
                      style: const TextStyle(
                        color: AppColors.brandRed,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                emg.status.name.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'SOS from ${(emg.ownerName?.isNotEmpty == true) ? emg.ownerName! : 'Senior Resident'}',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.slate900,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.near_me, color: AppColors.brandBlue, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Location: ${emg.location.latitude.toStringAsFixed(4)}, ${emg.location.longitude.toStringAsFixed(4)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.slate600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (emg.notes != null && emg.notes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Notes: ${emg.notes!}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.slate700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.slate50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '🔒 Exact coordinates & owner details are privacy-protected until acceptance.',
              style: TextStyle(fontSize: 11, color: AppColors.slate500),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await provider.acceptEmergency(emg.id);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Accept & Respond',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoIncidentsPlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.brandSuccessLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: AppColors.brandSuccess,
              size: 30,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'All Clear in Your Neighborhood',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.slate900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'No active SOS emergencies in this radius.\nPull down or tap Refresh to re-scan.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.slate500),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _refreshRadar,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Scan Radar Now'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.slate300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
