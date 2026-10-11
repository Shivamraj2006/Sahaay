import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/emergency_model.dart';
import '../providers/elderly_emergency_provider.dart';
import '../../../shared/widgets/emergency_status_badge.dart';
import '../../../shared/widgets/emergency_hotline_banner.dart';

class ElderlyActiveEmergencyScreen extends ConsumerWidget {
  const ElderlyActiveEmergencyScreen({super.key});

  Future<void> _callPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emergencyState = ref.watch(elderlyEmergencyProvider);
    final emergency = emergencyState.activeEmergency;

    if (emergency == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Emergency Status')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
              const SizedBox(height: 16),
              const Text('No Active Emergency', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/elderly'),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      );
    }

    final isCountingDown = emergencyState.isCountingDown;
    final countdownSeconds = emergencyState.countdownSeconds;
    final hasAssignedResponder = emergency.assignedResponder != null;
    final isTerminal = emergency.status.isTerminal;

    return WillPopScope(
      onWillPop: () async => false, // Prevent accidental back press during crisis
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Live Emergency Status'),
          automaticallyImplyLeading: false,
          actions: [
            if (isTerminal)
              IconButton(
                icon: const Icon(Icons.home),
                onPressed: () {
                  ref.read(elderlyEmergencyProvider.notifier).resetActiveEmergency();
                  context.go('/elderly');
                },
              )
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Real-time Status Badge
                Center(
                  child: EmergencyStatusBadge(status: emergency.status.value),
                ),
                const SizedBox(height: 16),

                // Cancellation Countdown Banner (Usability safeguard)
                if (isCountingDown && emergency.status == EmergencyStatus.active) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF59E0B), width: 2),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'CANCEL WINDOW OPEN',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF92400E),
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$countdownSeconds',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFB45309),
                          ),
                        ),
                        const Text(
                          'Seconds remaining to safely cancel before full responder dispatch.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Color(0xFF78350F)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Error Message if cancellation or update race failed
                if (emergencyState.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      emergencyState.errorMessage!,
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Emergency Overview Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.blueGrey),
                            const SizedBox(width: 8),
                            const Text(
                              'Alert Details',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            Text(
                              emergency.category.label,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Text(
                          'Alert ID: ${emergency.id}',
                          style: const TextStyle(fontSize: 12, color: Colors.blueGrey, fontFamily: 'monospace'),
                        ),
                        if (emergency.notes != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Note: ${emergency.notes}',
                            style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Assigned Responder Card (Only shown if authorized & assigned by backend)
                if (hasAssignedResponder) ...[
                  Card(
                    color: const Color(0xFFF0FDF4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFF86EFAC), width: 1.5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.verified_user, color: Color(0xFF16A34A), size: 24),
                              SizedBox(width: 8),
                              Text(
                                'Verified Responder On The Way',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF166534),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            emergency.assignedResponder!.displayName,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                          ),
                          Text(
                            emergency.assignedResponder!.role ?? 'Community Responder',
                            style: const TextStyle(fontSize: 14, color: Colors.black54),
                          ),
                          if (emergency.assignedResponder!.phone != null) ...[
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.phone),
                              label: Text('Call ${emergency.assignedResponder!.displayName}'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF16A34A),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => _callPhone(emergency.assignedResponder!.phone!),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else if (!isTerminal) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blueGrey.shade200),
                    ),
                    child: Row(
                      children: const [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Searching for nearby verified responders within 500m – 3km...',
                            style: TextStyle(fontSize: 14, color: Colors.blueGrey),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Actions: Cancel SOS or Done
                if (!isTerminal) ...[
                  ElevatedButton.icon(
                    icon: const Icon(Icons.close_rounded, size: 26),
                    label: const Text('Cancel SOS Alert'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFDC2626), width: 2),
                    ),
                    onPressed: emergencyState.isLoading
                        ? null
                        : () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Confirm Cancellation'),
                                content: const Text('Are you sure you want to cancel this emergency request?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep Active')),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Yes, Cancel Alert'),
                                  ),
                                ],
                              ),
                            );

                            if (confirmed == true) {
                              await ref.read(elderlyEmergencyProvider.notifier).cancelEmergency();
                            }
                          },
                  ),
                  const SizedBox(height: 12),
                  // Escalate button
                  OutlinedButton.icon(
                    icon: const Icon(Icons.warning_amber_rounded, color: Colors.deepOrange),
                    label: const Text('Escalate to Public Help Desk', style: TextStyle(color: Colors.deepOrange)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.deepOrange),
                    ),
                    onPressed: () async {
                      await ref
                          .read(elderlyEmergencyProvider.notifier)
                          .escalateEmergency('Citizen requested immediate escalated assistance');
                    },
                  ),
                ] else ...[
                  ElevatedButton(
                    onPressed: () {
                      ref.read(elderlyEmergencyProvider.notifier).resetActiveEmergency();
                      context.go('/elderly');
                    },
                    child: const Text('Return to Home Screen'),
                  ),
                ],
                const SizedBox(height: 24),

                // Standard helpline banner
                const EmergencyHotlineBanner(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
