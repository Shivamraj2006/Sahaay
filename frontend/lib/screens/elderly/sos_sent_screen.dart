import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../models/emergency.dart';
import '../../providers/emergency_provider.dart';

class SosSentScreen extends StatefulWidget {
  final VoidCallback onDismiss;

  const SosSentScreen({super.key, required this.onDismiss});

  @override
  State<SosSentScreen> createState() => _SosSentScreenState();
}

class _SosSentScreenState extends State<SosSentScreen> {
  void _callAmbulance() async {
    final uri = Uri.parse('tel:108');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmergencyProvider>();
    final emergency = provider.emergency;

    final createdAtStr = emergency != null
        ? DateFormat('d MMM yyyy, h:mm a').format(emergency.createdAt.toLocal())
        : DateFormat('d MMM yyyy, h:mm a').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),

              // Green Success Checkmark Badge (Stitch Screen 3)
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.brandSuccess,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandSuccess.withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 44,
                ),
              ),
              const SizedBox(height: 14),

              const Text(
                'SOS Sent',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppColors.slate900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Help is on the way!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate600,
                ),
              ),
              const SizedBox(height: 20),

              // Live Operational Status Tracker (Connecting with Backend State Machine)
              _buildLiveStatusBanner(emergency),
              const SizedBox(height: 16),

              // Alert Details Card (Stitch Screen 3)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.slate200, width: 1),
                ),
                child: Column(
                  children: [
                    // Sent at
                    _buildDetailRow(
                      icon: Icons.access_time_rounded,
                      iconColor: AppColors.slate500,
                      title: 'SENT AT',
                      value: createdAtStr,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Divider(color: AppColors.slate200, height: 1),
                    ),

                    // Your location
                    _buildDetailRow(
                      icon: Icons.location_on,
                      iconColor: AppColors.brandRed,
                      title: 'YOUR LOCATION',
                      value: 'Koramangala, Bengaluru',
                      subtitleWidget: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.brandSuccess,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Expanded(
                            child: Text(
                              'Live location shared with emergency contacts',
                              style: TextStyle(
                                color: AppColors.brandSuccess,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Divider(color: AppColors.slate200, height: 1),
                    ),

                    // Notified recipients
                    _buildDetailRow(
                      icon: Icons.people_alt,
                      iconColor: AppColors.brandBlue,
                      title: 'NOTIFIED',
                      value: '3 emergency contacts',
                      subtitleWidget: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          SizedBox(height: 2),
                          Text(
                            'Nearby volunteers alerted',
                            style: TextStyle(
                              color: AppColors.slate700,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Emergency services (112/108)',
                            style: TextStyle(
                              color: AppColors.slate500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Cancel SOS Pill Button (Stitch Screen 3)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await provider.cancelEmergency();
                    widget.onDismiss();
                  },
                  icon: const Icon(Icons.stop, color: AppColors.brandRedDark, size: 20),
                  label: const Text(
                    'Cancel SOS',
                    style: TextStyle(
                      color: AppColors.brandRedDark,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandRedSoft,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Direct Ambulance Call Button (Stitch Screen 3)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _callAmbulance,
                  icon: Transform(
                    transform: Matrix4.rotationZ(-0.2),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.phone,
                      color: AppColors.brandBlue,
                      size: 22,
                    ),
                  ),
                  label: const Text(
                    'Call 108 (Ambulance)',
                    style: TextStyle(
                      color: AppColors.brandBlue,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.brandBlueLight,
                    side: const BorderSide(color: AppColors.brandBlueBorder, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Interactive Demo Flow Controls (Simulate responder accepting & arriving)
              _buildDemoControls(provider, emergency),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveStatusBanner(EmergencyModel? emergency) {
    if (emergency == null) return const SizedBox.shrink();

    String title;
    String desc;
    Color bg;
    Color border;
    IconData icon;

    switch (emergency.status) {
      case EmergencyStatus.active:
        title = 'Broadcasting to Nearby Responders';
        desc = 'Searching community volunteers within 500m...';
        bg = AppColors.brandBlueLight;
        border = AppColors.brandBlueBorder;
        icon = Icons.radar;
        break;
      case EmergencyStatus.assigned:
        title = 'Responder Assigned!';
        desc = '${emergency.assignedResponder?.displayName ?? "Rahul Sharma"} has accepted your SOS.';
        bg = AppColors.brandSuccessLight;
        border = AppColors.brandSuccessBorder;
        icon = Icons.directions_run;
        break;
      case EmergencyStatus.responderArrived:
        title = 'Responder Arrived on Scene!';
        desc = '${emergency.assignedResponder?.displayName ?? "Responder"} has reached you.';
        bg = AppColors.brandSuccessLight;
        border = AppColors.brandSuccessBorder;
        icon = Icons.check_circle;
        break;
      case EmergencyStatus.resolved:
        title = 'Emergency Resolved & Safe';
        desc = emergency.transactionHash != null
            ? 'Milestone proof confirmed on-chain on EmergencyLedger.sol'
            : 'Incident resolved safely.';
        bg = AppColors.slate100;
        border = AppColors.slate300;
        icon = Icons.verified;
        break;
      case EmergencyStatus.cancelled:
        title = 'SOS Cancelled';
        desc = 'Alert was cancelled by user.';
        bg = AppColors.rose50;
        border = AppColors.brandRedSoft;
        icon = Icons.cancel;
        break;
      default:
        title = 'Emergency Status';
        desc = emergency.status.label;
        bg = AppColors.slate100;
        border = AppColors.slate300;
        icon = Icons.info;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border, width: 1.2),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.slate900, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slate900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
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
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    Widget? subtitleWidget,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slate500,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.slate900,
                ),
              ),
              if (subtitleWidget != null) ...[
                const SizedBox(height: 4),
                subtitleWidget,
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDemoControls(EmergencyProvider provider, EmergencyModel? emergency) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Interactive Demo Simulation',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.slate600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                label: const Text('Simulate Accept & Arrive'),
                avatar: const Icon(Icons.play_arrow, size: 16),
                onPressed: () => provider.simulateAcceptAndArrive(),
              ),
              ActionChip(
                label: const Text('Simulate Resolution'),
                avatar: const Icon(Icons.check, size: 16),
                onPressed: () => provider.simulateResolution('ASSISTED'),
              ),
              ActionChip(
                label: const Text('Return to Home'),
                onPressed: widget.onDismiss,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
