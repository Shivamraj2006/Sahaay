import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/responder_provider.dart';
import '../../elderly/models/emergency_model.dart';
import '../../../shared/widgets/accessibility_notice_banner.dart';
import '../../../shared/widgets/emergency_status_badge.dart';

class ResponderHomeScreen extends ConsumerWidget {
  const ResponderHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final responderState = ref.watch(responderProvider);
    final user = authState.user;

    final isVerified = user?.verificationStatus == VerificationStatus.verified;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Responder Command'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Nearby',
            onPressed: () {
              ref.read(responderProvider.notifier).fetchNearbyEmergencies();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).logout();
              if (context.mounted) context.go('/auth');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(responderProvider.notifier).fetchNearbyEmergencies();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Active assigned emergency shortcut if present
                if (responderState.assignedEmergency != null) ...[
                  InkWell(
                    onTap: () => context.go('/responder/active'),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF3B82F6), width: 2),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.directions_run_rounded, color: Color(0xFF1D4ED8), size: 32),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'ASSIGNED INCIDENT IN PROGRESS',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1D4ED8),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  responderState.assignedEmergency!.category.label,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, color: Color(0xFF1D4ED8), size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Verification and Availability Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: isVerified ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                              child: Icon(
                                isVerified ? Icons.verified : Icons.pending_outlined,
                                color: isVerified ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?.displayName ?? 'Responder',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${user?.role.label} • ${user?.verificationStatus.label}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isVerified ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        // Duty Toggle Switch
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Available for Dispatch', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            responderState.isAvailable
                                ? 'Active: Listening for nearby emergencies within 3 km'
                                : 'Offline: Not receiving community emergency alerts',
                            style: const TextStyle(fontSize: 13),
                          ),
                          value: responderState.isAvailable,
                          activeColor: const Color(0xFF16A34A),
                          onChanged: isVerified
                              ? (val) {
                                  ref.read(responderProvider.notifier).toggleAvailability(val);
                                }
                              : null,
                        ),
                        if (!isVerified) ...[
                          const SizedBox(height: 8),
                          const AccessibilityNoticeBanner(
                            message: 'Account pending verifier review. Only verified responders can toggle availability.',
                            backgroundColor: Color(0xFFFFFBEB),
                            foregroundColor: Color(0xFFB45309),
                            icon: Icons.shield_moon_outlined,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Reputation & Community Trust Summary (Conforming to shared doc)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Completed Rescues', style: TextStyle(fontSize: 13, color: Colors.blueGrey)),
                              const SizedBox(height: 4),
                              Text(
                                '${responderState.completedAssistanceCount}',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        Container(height: 40, width: 1, color: Colors.grey.shade300),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Reputation Score', style: TextStyle(fontSize: 13, color: Colors.blueGrey)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 22),
                                  const SizedBox(width: 4),
                                  Text(
                                    responderState.reputationScore.toStringAsFixed(1),
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Section Title: Nearby Emergencies
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Nearby Alerts (Coarse Data)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${responderState.nearbyEmergencies.length} active',
                      style: const TextStyle(fontSize: 14, color: Colors.blueGrey),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Privacy Shield: Exact address & GPS unlocked only AFTER server confirmation of assignment.',
                  style: TextStyle(fontSize: 12, color: Colors.blueGrey, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 12),

                // Alerts list
                if (!responderState.isAvailable) ...[
                  Container(
                    padding: const EdgeInsets.all(28),
                    alignment: Center(
                      child: Column(
                        children: const [
                          Icon(Icons.power_settings_new, size: 48, color: Colors.grey),
                          SizedBox(height: 12),
                          Text(
                            'You are currently Offline',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Toggle switch above to receive alerts in your vicinity.',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else if (responderState.nearbyEmergencies.isEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(32),
                    alignment: Center(
                      child: Column(
                        children: const [
                          Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
                          SizedBox(height: 12),
                          Text(
                            'No Active Alerts Nearby',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Listening for emergency broadcasts within 3 km...',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  ...responderState.nearbyEmergencies.map((alert) {
                    final distMeters = alert.approximateDistanceMeters;
                    final distText = distMeters != null
                        ? distMeters >= 1000
                            ? '~${(distMeters / 1000).toStringAsFixed(1)} km away'
                            : '~${distMeters.round()} m away'
                        : '~Approximate distance';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                EmergencyStatusBadge(status: alert.status.value),
                                const Spacer(),
                                Text(
                                  distText,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFDC2626),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              alert.category.label,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Elder Citizen: ${alert.owner.displayName}',
                              style: const TextStyle(fontSize: 14, color: Colors.black87),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Location: Coarse Grid (Exact coordinates hidden for privacy)',
                              style: TextStyle(fontSize: 12, color: Colors.blueGrey, fontStyle: FontStyle.italic),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Colors.grey),
                                      minimumSize: const Size(0, 48),
                                    ),
                                    onPressed: () {
                                      ref.read(responderProvider.notifier).declineEmergency(alert.id);
                                    },
                                    child: const Text('Decline', style: TextStyle(color: Colors.grey)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFDC2626),
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(0, 48),
                                    ),
                                    onPressed: responderState.isLoading
                                        ? null
                                        : () async {
                                            final ok = await ref
                                                .read(responderProvider.notifier)
                                                .acceptEmergency(alert.id);
                                            if (ok && context.mounted) {
                                              context.go('/responder/active');
                                            }
                                          },
                                    child: const Text('Accept SOS'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
