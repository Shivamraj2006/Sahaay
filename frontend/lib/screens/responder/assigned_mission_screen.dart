import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/emergency.dart';
import '../../providers/emergency_provider.dart';

class AssignedMissionScreen extends StatelessWidget {
  final EmergencyModel emergency;
  final VoidCallback onComplete;

  const AssignedMissionScreen({
    super.key,
    required this.emergency,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmergencyProvider>();
    final isArrived = emergency.status == EmergencyStatus.responderArrived;
    final isResolved = emergency.status == EmergencyStatus.resolved;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Active Emergency Mission'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mission Status Header
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isArrived
                      ? AppColors.brandSuccessLight
                      : AppColors.brandBlueLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isArrived
                        ? AppColors.brandSuccessBorder
                        : AppColors.brandBlueBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isArrived ? Icons.person_pin_circle : Icons.navigation,
                      color: isArrived
                          ? AppColors.brandSuccess
                          : AppColors.brandBlue,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isArrived
                                ? 'You Have Arrived on Scene'
                                : 'Assigned to You — En Route',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isArrived
                                  ? AppColors.brandSuccess
                                  : AppColors.brandBlue,
                            ),
                          ),
                          Text(
                            isArrived
                                ? 'Assist the elderly resident safely.'
                                : 'Exact location unlocked post-assignment.',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.slate600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Patient & Exact Location Card (Privacy Unlocked Post-Assignment)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'RESIDENT DETAILS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.slate500,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Kamla Devi (Amma)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.slate900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '#42, 3rd Cross, 4th Block, Koramangala, Bengaluru',
                      style: TextStyle(fontSize: 14, color: AppColors.slate700),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.gps_fixed,
                          size: 16,
                          color: AppColors.brandRed,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Coordinates: ${emergency.location.latitude.toStringAsFixed(4)}, ${emergency.location.longitude.toStringAsFixed(4)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            color: AppColors.slate600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Action Buttons
              if (!isArrived && !isResolved) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await provider.simulateAcceptAndArrive();
                    },
                    icon: const Icon(Icons.check_circle, color: Colors.white),
                    label: const Text('Mark Arrived at Scene'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandSuccess,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
              ] else if (isArrived && !isResolved) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await provider.simulateResolution('ASSISTED');
                    },
                    icon: const Icon(Icons.verified, color: Colors.white),
                    label: const Text('Resolve Emergency (Assisted)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandBlue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Return / Complete
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onComplete,
                  child: const Text('Close Mission View'),
                ),
              ),

              const SizedBox(height: 24),

              // Blockchain Attestation Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.link, color: AppColors.brandBlue, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'EVM Trust Layer (EmergencyLedger.sol)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.slate900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Proof Status: ${emergency.proofStatus.value}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.brandSuccess,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Canonical SHA-256 Digest: 0xb6fe811fa1d8e1293baaa2fec3235bca253c05423cc81a17fa2b67f405cff15b',
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
