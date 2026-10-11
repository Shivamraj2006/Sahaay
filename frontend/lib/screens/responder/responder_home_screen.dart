import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/emergency.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/emergency_provider.dart';
import 'assigned_mission_screen.dart';

class ResponderHomeScreen extends StatefulWidget {
  const ResponderHomeScreen({super.key});

  @override
  State<ResponderHomeScreen> createState() => _ResponderHomeScreenState();
}

class _ResponderHomeScreenState extends State<ResponderHomeScreen> {
  bool _isAvailable = true;

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

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        title: const Text('Responder Portal'),
        actions: [
          IconButton(
            tooltip: 'Switch Persona',
            icon: const Icon(Icons.swap_horiz),
            onPressed: () {
              auth.switchRole(UserRole.elderlyUser);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
                            auth.user?.displayName ?? 'Rahul Sharma',
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

              const SizedBox(height: 16),

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
                      onChanged: (val) {
                        setState(() {
                          _isAvailable = val;
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Nearby Emergencies Section Header
              const Text(
                'Nearby Incidents (< 3 km)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.slate900,
                ),
              ),
              const SizedBox(height: 10),

              // Active Incident Feed (shows current emergency if active)
              if (currentEmg != null && currentEmg.status == EmergencyStatus.active)
                _buildNearbyIncidentCard(context, currentEmg, emergencyProvider)
              else
                _buildNoIncidentsPlaceholder(),
            ],
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
              const Text(
                'Just now',
                style: TextStyle(fontSize: 12, color: AppColors.slate500),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'SOS from Elderly Resident',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.slate900,
            ),
          ),
          const SizedBox(height: 4),
          const Row(
            children: [
              Icon(Icons.near_me, color: AppColors.brandBlue, size: 16),
              SizedBox(width: 6),
              Text(
                'Approx. 350 meters away (Koramangala 4th Block)',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.slate600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
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
                    await provider.simulateAcceptAndArrive();
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
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.brandSuccessLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: AppColors.brandSuccess,
              size: 32,
            ),
          ),
          const SizedBox(height: 14),
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
            'You will receive instant push notifications if an elderly resident triggers SOS.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.slate500),
          ),
        ],
      ),
    );
  }
}
